#!/bin/bash

PWD=$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)
echo ${PWD}

if [ $# -eq 0 ]; then
  echo "Usage: $0 <no_of_segments>"
  exit 1
fi

echo "Cleaning generated sql files: 05_sql/*.sql"
<<<<<<< HEAD
rm -f ${PWD}/05_sql/*.sql
echo "Cleaning binaries: 00_compile_tpcds/tools"
cd ${PWD}/00_compile_tpcds/tools || exit 1
make clean
cd - || exit 1
echo "Cleaning multi-user sql scripts(default 5CU): 07_multi_user/[1-5]"
rm -rf ${PWD}/07_multi_user/[1-5]
echo "Cleaning all tpcds remnents from segment nodes: binary, logs, data, etc."
for i in $(cat ${PWD}/segment_hosts.txt); do
  ssh ${i} 'rm -f dsdgen generate_data.*.log generate_data.sh gpfdist.*.log hosts-all hosts-segments start_gpfdist.sh stop_gpfdist.sh tpcds.idx; find /data* -type d -name dsbenchmark -exec rm -rf {} \;' &
done
=======
rm -f "${HOME}"/TPC-DS/05_sql/*.sql
echo "Cleaning binaries: 00_compile_tpcds/tools"
cd "${HOME}"/TPC-DS/00_compile_tpcds/tools || exit 1
make clean
cd - || exit 1
echo "Cleaning multi-user sql scripts(default 5CU): 07_multi_user/[1-5]"
rm -rf "${HOME}"/TPC-DS/07_multi_user/[1-5]
echo "Cleaning all tpcds remnents from segment nodes: binary, logs, data, etc."
while IFS= read -r line; do
  ssh -n "${line}" 'rm -f dsdgen generate_data.*.log generate_data.sh gpfdist.*.log hosts-all hosts-segments start_gpfdist.sh stop_gpfdist.sh tpcds.idx; find /gpdata -type d -name dsbenchmark -exec rm -rf {} \;' &
done < "${HOME}"/segments_hosts.txt
>>>>>>> 5ce4aba2007df43fc92d6de186240cfc0eedb336
wait
