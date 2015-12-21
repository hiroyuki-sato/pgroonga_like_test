
## 1, やりたいこと

* 二つのテーブル
* url_listsテーブルには、URLのリスト(アクセスログ)
* keywordsのテーブルには、url_listsの中で先頭・部分・完全一致させたいURLのリスト
* 今回は前方一致ができれば良い。

## 2, 疑問

* [ ] Like分でpgroongaのインデックスが使われないのはなぜか？
* [ ] クエリプランで``Join Filter``と出る場合、Groongaのインデックスが使われない？
* [ ] ``@~``を利用する際に、``.``をエスケープしないと検索結果が0件になってしまう理由

## 3, ファイル

```
.
|-- ER.graffle   # ER図
|-- ER.png       # ER図(png)
|-- README.md    # この文書
|-- create.sql   # テストテーブル作成用SQL
|-- keyword.txt  # keywordのリスト
|-- m.sql        # pgroongaに入っていたクエリ
|-- q1.sql       # テストクエリ1
|-- q2.sql       # テストクエリ2
|-- q3.sql       # テストクエリ3
|-- q4.sql       # テストクエリ4
|-- q5.sql       # テストクエリ5
|-- sample.txt   # サンプルURL
`-- sample_gen.rb # URLデータ生成スクリプト

0 directories, 13 files
````

## 4, テーブル定義

![](https://raw.githubusercontent.com/hiroyuki-sato/pgroonga_like_test/master/ER.png)

## 5, インデックス

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

## 7, テストクエリ

### 7.1 クエリ1 : LikeでJOIN


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

#### 問題点

* 結果はでるがインデックスを使ってくれてない(ようだ)

#### 疑問点

* Join Filter..のところは、pgroongaのインデックスを使ってくれない？


### 7.2 クエリ2 : like文に直接URLを指定

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

#### 問題点

* 結果はでるがインデックスを使ってくれてない(ようだ)

### 疑問点

* Join Filter..のところは、pgroongaのインデックスを使ってくれない？


### 7.3 クエリ3 : @~オペレータ、.をエスケープ

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

#### 問題点

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

### 7.4 クエリ4 : @~オペレータ、.をエスケープしない

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

結果
```
Time: 22.578 ms
 url 
-----
(0 rows)
```

#### 問題点

* 結果が0件になってしまう。

#### 疑問点

* ``.``は任意の一文字にマッチする正規表現であるため、マッチしても良いような...
* なぜ件数が0件になってしまうのか？


### 7.5 クエリ5 : @~でジョイン、.をエスケープ


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

#### 問題点

* 問題点なし
