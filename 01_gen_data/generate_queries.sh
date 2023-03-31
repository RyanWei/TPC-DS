#!/bin/bash

PWD=$(get_pwd "${BASH_SOURCE[0]}")

set -e

query_id=1
file_id=101

if [ "${GEN_DATA_SCALE}" == "" ] || [ "${BENCH_ROLE}" == "" ]; then
  echo "Usage: generate_queries.sh scale rolename"
  echo "Example: ./generate_queries.sh 100 dsbench"
  echo "This creates queries for 100GB of data."
  exit 1
fi

rm -f "${PWD}"/query_0.sql

<<<<<<< HEAD
echo "${PWD}/dsqgen -input ${PWD}/query_templates/templates.lst -directory ${PWD}/query_templates -dialect hashdata -scale ${GEN_DATA_SCALE} -verbose y -output ${PWD}"
${PWD}/dsqgen -input ${PWD}/query_templates/templates.lst -directory ${PWD}/query_templates -dialect hashdata -scale ${GEN_DATA_SCALE} -verbose y -output ${PWD}
=======
echo "${PWD}/dsqgen -input ${PWD}/query_templates/templates.lst -directory ${PWD}/query_templates -dialect pivotal -scale ${GEN_DATA_SCALE} -verbose y -output ${PWD}"
"${PWD}"/dsqgen -input "${PWD}"/query_templates/templates.lst -directory "${PWD}"/query_templates -dialect pivotal -scale "${GEN_DATA_SCALE}" -verbose y -output "${PWD}"
>>>>>>> 5ce4aba2007df43fc92d6de186240cfc0eedb336

rm -f "${TPC_DS_DIR}"/05_sql/*."${BENCH_ROLE}".*.sql*

for p in $(seq 1 99); do
  q=$(printf %02d "${query_id}")
  filename=${file_id}.${BENCH_ROLE}.${q}.sql
  template_filename=query${p}.tpl
  start_position=""
  end_position=""
  while IFS= read -r pos; do
    if [ "${start_position}" == "" ]; then
      start_position=${pos}
    else
      end_position=${pos}
    fi
  done < <(grep -n "${template_filename}" "${PWD}"/query_0.sql | awk -F ':' '{print $1}')

<<<<<<< HEAD
	echo "Creating: ${TPC_DS_DIR}/05_sql/${filename}"
	printf "set role ${BENCH_ROLE};\nset search_path=${SCHEMA_NAME},public;\n" > ${TPC_DS_DIR}/05_sql/${filename}

	for o in $(cat ${TPC_DS_DIR}/01_gen_data/optimizer.txt); do
        q2=$(echo ${o} | awk -F '|' '{print $1}')
        if [ "${p}" == "${q2}" ]; then
          optimizer=$(echo ${o} | awk -F '|' '{print $2}')
        fi
    done
	printf "set optimizer=${optimizer};\n" >> ${TPC_DS_DIR}/05_sql/${filename}
	printf "set statement_mem=\"${STATEMENT_MEM}\";\n" >> ${TPC_DS_DIR}/05_sql/${filename}
	printf ":EXPLAIN_ANALYZE\n" >> ${TPC_DS_DIR}/05_sql/${filename}
	
	sed -n ${start_position},${end_position}p ${PWD}/query_0.sql >> ${TPC_DS_DIR}/05_sql/${filename}
	query_id=$((query_id + 1))
	file_id=$((file_id + 1))
	echo "Completed: ${TPC_DS_DIR}/05_sql/${filename}"
=======
  echo "Creating: ${TPC_DS_DIR}/05_sql/${filename}"
  printf "set role %s;\n:EXPLAIN_ANALYZE\n" "${BENCH_ROLE}" > "${TPC_DS_DIR}"/05_sql/"${filename}"
  sed -n "${start_position}","${end_position}"p "${PWD}"/query_0.sql >> "${TPC_DS_DIR}"/05_sql/"${filename}"
  query_id=$((query_id + 1))
  file_id=$((file_id + 1))
  echo "Completed: ${TPC_DS_DIR}/05_sql/${filename}"
>>>>>>> 5ce4aba2007df43fc92d6de186240cfc0eedb336
done

echo ""
echo "queries 114, 123, 124, and 139 have 2 queries in each file.  Need to add :EXPLAIN_ANALYZE to second query in these files"
echo ""
arr=("114.${BENCH_ROLE}.14.sql" "123.${BENCH_ROLE}.23.sql" "124.${BENCH_ROLE}.24.sql" "139.${BENCH_ROLE}.39.sql")

for z in "${arr[@]}"; do
<<<<<<< HEAD
	myfilename=${TPC_DS_DIR}/05_sql/${z}
	echo "Modifying: ${myfilename}"
	pos=$(grep -n ";" ${myfilename} | awk -F ':' ' { if (NR > 4) print $1 }' | head -1)
	pos=$((pos + 1))
	sed -i ''${pos}'i\'$'\n'':EXPLAIN_ANALYZE'$'\n' ${myfilename}
	echo "Modified: ${myfilename}"
=======
  myfilename=${TPC_DS_DIR}/05_sql/${z}
  echo "Modifying: ${myfilename}"
  # shellcheck disable=SC2086
  pos=$(grep -n ";" < ${myfilename} | awk -F ':' ' { if (NR > 1) print $1 }' | head -1)
  pos=$((pos + 1))
  # shellcheck disable=SC2086
  sed -i "${pos}i:EXPLAIN_ANALYZE" ${myfilename}
  echo "Modified: ${myfilename}"
>>>>>>> 5ce4aba2007df43fc92d6de186240cfc0eedb336
done

echo "COMPLETE: dsqgen scale ${GEN_DATA_SCALE}"
