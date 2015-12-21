
## テーブル定義


インデックス(URL)

```
\d url_lists;
           Table "public.url_lists"
 Column |          Type           | Modifiers 
--------+-------------------------+-----------
 id     | integer                 | not null
 url    | character varying(1023) | not null
Indexes:
    "url_lists_pkey" PRIMARY KEY, btree (id)
    "ix_url_url_lists" pgroonga (url) WITH (tokenizer=TokenRegexp, normalizer=)
    "ix_url_url_lists2" pgroonga (url pgroonga.varchar_regexp_ops)
```

インデックス(キーワード)

```
\d keywords;
           Table "public.keywords"
 Column |          Type           | Modifiers 
--------+-------------------------+-----------
 id     | integer                 | not null
 name   | character varying(40)   | not null
 url    | character varying(1023) | not null
Indexes:
    "keywords_pkey" PRIMARY KEY, btree (id)
    "ix_name_keywords" btree (name)
    "ix_url_keywords" btree (url)
```

## クエリ1 : LikeでJOIN

```sql
SELECT
  u.url 
FROM 
  url_lists u,
  keywords  k
WHERE
  u.url like k.url
  and k.name = 'like_str';
```    

```
 Nested Loop  (cost=0.30..699.81 rows=125 width=56)
   Join Filter: ((u.url)::text ~~ (k.url)::text)
   ->  Index Scan using ix_name_keywords on keywords k  (cost=0.14..8.16 rows=1 width=516)
         Index Cond: ((name)::text = 'like_str'::text)
   ->  Index Only Scan using ix_url_url_lists2 on url_lists u  (cost=0.15..379.15 rows=25000 width=56)
(5 rows)
```

### 問題点

* 結果はでるがインデックスを使ってくれてない(ようだ)

## 疑問点

* Join Filter..のところは、pgroongaのインデックスを使ってくれない？


## クエリ2 : like文に直接URLを指定

```sql
SELECT
  u.url 
FROM 
  url_lists u
WHERE
  u.url like 'http://aa.yahoo.co.jp/%';
```

```
                                           QUERY PLAN                                           
------------------------------------------------------------------------------------------------
 Index Only Scan using ix_url_url_lists2 on url_lists u  (cost=0.15..441.65 rows=5051 width=56)
   Filter: ((url)::text ~~ 'http://aa.yahoo.co.jp/%'::text)
```

### 問題点

* 結果はでるがインデックスを使ってくれてない(ようだ)

## 疑問点

* Join Filter..のところは、pgroongaのインデックスを使ってくれない？


## クエリ3 : @~オペレータ、.をエスケープ

```sql
SELECT
  u.url 
FROM 
  url_lists u
WHERE
  u.url @~ 'http://aa\.yahoo\.co\.jp';
````

```
                                           QUERY PLAN                                            
-------------------------------------------------------------------------------------------------
 Index Only Scan using ix_url_url_lists2 on url_lists u  (cost=0.15..222.90 rows=12500 width=56)
   Index Cond: (url @~ 'http://aa\.yahoo\.co\.jp'::character varying)
(2 rows)
```

### 問題点

* 特になし、インデックスが効いている。

```
2015-12-21 18:36:31.022125|n| grn_init: <5.1.0>
2015-12-21 18:36:31.033727|i| [object][search][index][key][regexp] <Lexicon76274_0.index>
2015-12-21 18:36:31.033746|i| grn_ii_sel > (http://aa\.yahoo\.co\.jp)
2015-12-21 18:36:31.034899|i| n=11 (http://aa.yahoo.co.jp)
2015-12-21 18:36:31.037575|i| exact: 5000
2015-12-21 18:36:31.037583|i| hits=5000
2015-12-21 18:36:31.131449|n| grn_fin (0)
```

## クエリ4 : @~オペレータ、.をエスケープしない

```
SELECT
  u.url 
FROM 
  url_lists u
WHERE
  u.url @~ 'http://aa.yahoo.co.jp/';
```

```
 Index Only Scan using ix_url_url_lists2 on url_lists u  (cost=0.15..222.90 rows=12500 width=56)
   Index Cond: (url @~ 'http://aa.yahoo.co.jp/'::character varying)
(2 rows)
```

### 問題点

* 結果が0件になってしまう。

## 疑問点

* ``.``は任意の一文字にマッチする正規表現であるため、マッチしても良いような...
* なぜ件数が0件になってしまうのか？


## クエリ5 : @~でジョイン、.をエスケープ

```
2015-12-21 18:39:28.491031|n| grn_init: <5.1.0>
2015-12-21 18:39:28.503632|i| [object][search][index][key][regexp] <Lexicon76274_0.index>
2015-12-21 18:39:28.503652|i| grn_ii_sel > (http://ae\.yahoo\.co\.jp/ae/)
2015-12-21 18:39:28.504935|i| n=13 (http://ae.yahoo.co.jp/ae/)
2015-12-21 18:39:28.509543|i| exact: 0
2015-12-21 18:39:28.509580|i| unsplit: 0
2015-12-21 18:39:28.510263|i| partial: 0
2015-12-21 18:39:28.510269|i| hits=0
2015-12-21 18:39:28.510603|i| [object][search][index][key][regexp] <Lexicon76274_0.index>
2015-12-21 18:39:28.510612|i| grn_ii_sel > (http://ae\.yahoo\.co\.jp/aa/)
2015-12-21 18:39:28.511675|i| n=13 (http://ae.yahoo.co.jp/aa/)
2015-12-21 18:39:28.516017|i| exact: 1000
2015-12-21 18:39:28.516028|i| hits=1000
2015-12-21 18:39:28.544379|n| grn_fin (0)
```

```
                                              QUERY PLAN                                               
-------------------------------------------------------------------------------------------------------
 Nested Loop  (cost=0.30..356.06 rows=12500 width=56)
   ->  Index Scan using ix_name_keywords on keywords k  (cost=0.14..8.16 rows=1 width=516)
         Index Cond: ((name)::text = 'esc_url'::text)
   ->  Index Only Scan using ix_url_url_lists2 on url_lists u  (cost=0.15..222.90 rows=12500 width=56)
         Index Cond: (url @~ k.url)
(5 rows)
```
