#!/bin/bash
set -e

PWD=$(get_pwd ${BASH_SOURCE[0]})

step="single_user_reports"

init_log ${step}

filter="gpdb"

for i in ${PWD}/*.${filter}.*.sql; do
  log_time "psql -v ON_ERROR_STOP=1 -a -f ${i}"
  psql -v ON_ERROR_STOP=1 -a -f ${i}
  echo ""
done

for i in ${PWD}/*.copy.*.sql; do
  logstep=$(echo ${i} | awk -F 'copy.' '{print $2}' | awk -F '.' '{print $1}')
  logfile="${TPC_DS_DIR}/log/rollout_${logstep}.log"
  logfile="'${logfile}'"
  log_time "psql -v ON_ERROR_STOP=1 -a -f ${i} -v LOGFILE=\"${logfile}\""
  psql -v ON_ERROR_STOP=1 -a -f ${i} -v LOGFILE="${logfile}"
  echo ""
done

psql -v ON_ERROR_STOP=1 -q -t -A -c "select 'analyze ' || n.nspname || '.' || c.relname || ';' from pg_class c join pg_namespace n on n.oid = c.relnamespace and n.nspname = 'tpcds_reports'" | psql -v ON_ERROR_STOP=1 -t -A -e

echo "********************************************************************************"
echo "Generate Data"
echo "********************************************************************************"
psql -v ON_ERROR_STOP=1 -P pager=off -f ${PWD}/gen_data_report.sql
echo ""
echo "********************************************************************************"
echo "Data Loads"
echo "********************************************************************************"
psql -v ON_ERROR_STOP=1 -P pager=off -f ${PWD}/loads_report.sql
echo ""
echo "********************************************************************************"
echo "Analyze"
echo "********************************************************************************"
psql -v ON_ERROR_STOP=1 -P pager=off -f ${PWD}/analyze_report.sql
echo ""
echo ""
echo "********************************************************************************"
echo "Queries"
echo "********************************************************************************"
psql -v ON_ERROR_STOP=1 -P pager=off -f ${PWD}/queries_report.sql
echo ""

echo "********************************************************************************"
echo "Summary"
echo "********************************************************************************"
echo ""
LOAD_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_reports.load where tuples > 0")
ANALYZE_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from tpcds_reports.sql where tuples = -1")
QUERIES_TIME=$(psql -v ON_ERROR_STOP=1 -q -t -A -c "select round(sum(extract('epoch' from duration))) from (SELECT split_part(description, '.', 2) AS id, min(duration) AS duration FROM tpcds_reports.sql where tuples >= 0 GROUP BY split_part(description, '.', 2)) as sub")

printf "Load (seconds)\t\t\t%d\n" "${LOAD_TIME}"
printf "Analyze (seconds)\t\t\t%d\n" "${ANALYZE_TIME}"
printf "1 User Queries (seconds)\t\t%d\n" "${QUERIES_TIME}"
echo ""
echo "********************************************************************************"

echo "Finished ${step}"
