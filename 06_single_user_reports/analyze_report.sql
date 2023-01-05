SELECT split_part(description, '.', 1) as schema_name, extract('epoch' from duration) AS seconds 
FROM tpcds_reports.sql
WHERE tuples = -1
ORDER BY 1;
