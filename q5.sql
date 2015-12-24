SET enable_seqscan = off;
SET enable_indexscan = on;
SET enable_bitmapscan = on;

set pgroonga.log_level = 'debug';

set work_mem = '100MB';

EXPLAIN SELECT
  u.url 
FROM 
  url_lists u
WHERE
  u.url @~ 'http://aa\.yahoo\.co\.jp'
OR
  u.url @~ 'http://ab\.yahoo\.co\.jp';

SELECT
  u.url 
FROM 
  url_lists u
WHERE
  u.url @~ 'http://aa\.yahoo\.co\.jp'
OR
  u.url @~ 'http://ab\.yahoo\.co\.jp';

