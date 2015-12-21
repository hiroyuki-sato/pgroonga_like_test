create table url_lists (
  id int not null primary key,
  url varchar(1023) not null
);

create index
  ix_url_url_lists
on
  url_lists
using
  pgroonga(url)
with 
  (tokenizer='TokenRegexp', normalizer='');

create index
  ix_url_url_lists2
on
  url_lists
using
  pgroonga(url pgroonga.varchar_regexp_ops);
  
create table keywords (
  id int not null primary key,
  name varchar(40) not null,
  url varchar(1023) not null
);

create index ix_url_keywords on keywords(url);
create index ix_name_keywords on keywords(name);
  

\copy url_lists(id,url) from 'sample.txt' with delimiter ',';
\copy keywords(id,name,url) from 'keyword.txt' with delimiter ',';
