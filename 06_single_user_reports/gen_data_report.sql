WITH x AS (SELECT duration FROM tpcds_reports.gen_data)
SELECT 'Seconds' as time, round(extract('epoch' from duration),3) AS value
FROM x
UNION ALL
SELECT 'Minutes', round(extract('epoch' from duration)/60,3) AS minutes
FROM x
UNION ALL
SELECT 'Hours', round(extract('epoch' from duration)/(60*60),3) AS hours 
FROM x;
