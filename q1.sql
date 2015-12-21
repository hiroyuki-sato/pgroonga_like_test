set pgroonga.log_level = 'debug';

set work_mem = '100MB';

SET enable_seqscan = off;
SET enable_indexscan = on;
SET enable_bitmapscan = off;


EXPLAIN SELECT
  u.url 
FROM 
  url_lists u,
  keywords  k
WHERE
  u.url like k.url
  and k.name = 'like_str';

SELECT
  u.url 
FROM 
  url_lists u,
  keywords  k
WHERE
  u.url like k.url
  and k.name = 'like_str';

