#!/bin/bash
set -e

PWD=$(get_pwd ${BASH_SOURCE[0]})

step="load"

log_time "Step ${step} started"
printf "\n"

init_log ${step}

get_version
filter="gpdb"

function copy_script() {
  echo "copy the start and stop scripts to the segment hosts in the cluster"
  for i in $(cat ${TPC_DS_DIR}/segment_hosts.txt); do
    echo "scp start_gpfdist.sh stop_gpfdist.sh ${i}:"
    scp ${PWD}/start_gpfdist.sh ${PWD}/stop_gpfdist.sh ${i}: &
  done
  wait
}

function stop_gpfdist() {
  echo "stop gpfdist on all ports"
  for i in $(cat ${TPC_DS_DIR}/segment_hosts.txt); do
    ssh -n -f $i "bash -c 'cd ~/; ./stop_gpfdist.sh'" &
  done
  wait
}

function start_gpfdist() {
  stop_gpfdist
  sleep 1
  get_gpfdist_port
  if [ "${VERSION}" == "gpdb_5" ]; then
    SQL_QUERY="select rank() over (partition by g.hostname order by p.fselocation), g.hostname, p.fselocation as path from gp_segment_configuration g join pg_filespace_entry p on g.dbid = p.fsedbid join pg_tablespace t on t.spcfsoid = p.fsefsoid where g.content >= 0 and g.role = '${GPFDIST_LOCATION}' and t.spcname = 'pg_default' order by g.hostname"
  else
    SQL_QUERY="select rank() over(partition by g.hostname order by g.datadir), g.hostname, g.datadir from gp_segment_configuration g where g.content >= 0 and g.role = '${GPFDIST_LOCATION}' order by g.hostname"
  fi

  flag=10
  for i in $(psql -v ON_ERROR_STOP=1 -q -A -t -c "${SQL_QUERY}"); do
    CHILD=$(echo ${i} | awk -F '|' '{print $1}')
    EXT_HOST=$(echo ${i} | awk -F '|' '{print $2}')
    GEN_DATA_PATH=$(echo ${i} | awk -F '|' '{print $3}'| sed 's#//#/#g')
    GEN_DATA_PATH="${GEN_DATA_PATH}/dsbenchmark"
    PORT=$((GPFDIST_PORT + flag))
    let flag=$flag+1
    echo "ssh -n -f ${EXT_HOST} \"bash -c 'cd ~${ADMIN_USER}; ./start_gpfdist.sh $PORT ${GEN_DATA_PATH}'\""
    ssh -n -f ${EXT_HOST} "bash -c 'cd ~${ADMIN_USER}; ./start_gpfdist.sh $PORT ${GEN_DATA_PATH}'" &
  done
  wait
}

copy_script
start_gpfdist

# need to wait for all the gpfdist processes to start
sleep 10

for i in ${PWD}/*.${filter}.*.sql; do
  start_log

  id=$(echo ${i} | awk -F '.' '{print $1}')
  export id
  schema_name=$(echo ${i} | awk -F '.' '{print $2}')
  table_name=$(echo ${i} | awk -F '.' '{print $3}')

  log_time "psql -v ON_ERROR_STOP=1 -f ${i} | grep INSERT | awk -F ' ' '{print \$3}'"
  tuples=$(
    psql -v ON_ERROR_STOP=1 -f ${i} | grep INSERT | awk -F ' ' '{print $3}'
    exit ${PIPESTATUS[0]}
  )

  print_log ${tuples}
done

log_time "finished loading tables"

stop_gpfdist

echo "Finished ${step}"
log_time "Step ${step} finished"
printf "\n"