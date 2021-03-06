SET enable_seqscan = off;
SET enable_indexscan = on;
SET enable_bitmapscan = on;

set pgroonga.log_level = 'debug';

set work_mem = '100MB';

EXPLAIN SELECT
  u.url 
FROM 
  url_lists u,
  keywords k
WHERE
  u.url @~ k.url
AND
  k.name = 'url';

SELECT 
  u.url 
FROM 
  url_lists u,
  keywords k
WHERE
  u.url @~ k.url
AND
  k.name = 'url';

