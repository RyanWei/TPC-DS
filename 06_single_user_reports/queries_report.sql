SELECT split_part(description, '.', 2) AS id,  max(tuples) as tuples, min(extract('epoch' from duration)) AS duration
FROM tpcds_reports.sql
where tuples >= 0
GROUP BY split_part(description, '.', 2)
ORDER BY id;