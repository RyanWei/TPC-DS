#!/bin/bash
set -e

PWD=$(get_pwd ${BASH_SOURCE[0]})
step="compile_tpcds"

log_time "Step ${step} started"
printf "\n"

init_log ${step}
start_log
schema_name="${SCHEMA_NAME}"
export schema_name
table_name="compile"
export table_name

compile_flag="true"

function make_tpc() {
  #compile the tools
  cd ${PWD}/tools
  rm -f ./*.o
  ADDITIONAL_CFLAGS_OPTION="-g -Wno-unused-function -Wno-unused-but-set-variable -Wno-format -fcommon" make
  cd ..
}

function copy_tpc() {
  cp ${PWD}/tools/dsqgen ../*_gen_data/
  cp ${PWD}/tools/dsqgen ../*_multi_user/
  cp ${PWD}/tools/tpcds.idx ../*_gen_data/
  cp ${PWD}/tools/tpcds.idx ../*_multi_user/

  #copy the compiled dsdgen program to the segment nodes
  echo "copy tpcds binaries to segment hosts"
  for i in $(cat ${TPC_DS_DIR}/segment_hosts.txt); do
    scp tools/dsdgen tools/tpcds.idx ${i}: &
  done
  wait
}

function copy_queries() {
  rm -rf ${TPC_DS_DIR}/*_gen_data/query_templates
  rm -rf ${TPC_DS_DIR}/*_multi_user/query_templates
  cp -R query_templates ${TPC_DS_DIR}/*_gen_data/
  cp -R query_templates ${TPC_DS_DIR}/*_multi_user/
}

function check_binary() {
  set +e
  
  cd ${PWD}/tools/
  cp -f dsqgen.${CHIP_TYPE} dsqgen
  cp -f dsdgen.${CHIP_TYPE} dsdgen
  chmod +x dsqgen
  chmod +x dsdgen

  ./dsqgen -help
  if [ $? == 0 ]; then 
    ./dsdgen -help
    if [ $? == 0 ]; then
      compile_flag="false" 
    fi
  fi
  cd ..
  set -e
}

check_binary

if [ "${compile_flag}" == "true" ]; then
  make_tpc
else
  echo "Binary works, no compiling needed."
fi
create_hosts_file
copy_tpc
copy_queries
print_log

echo "Finished ${step}"
log_time "Step ${step} finished"
printf "\n"