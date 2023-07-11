# Decision Support Benchmark for HashData database.

This tool is based on the benchmark tool [pivotal TPC-DS](https://github.com/pivotal/TPC-DS).
This repo contains automation of running the DS benchmark on an existing Hashdata cluster.

## Context


### Supported TPC-DS Versions

TPC has published the following TPC-DS standards over time:
| TPC-DS Benchmark Version | Published Date | Standard Specification |
|-|-|-|
| 3.2.0 (latest) | 2021/06/15 | http://www.tpc.org/tpc_documents_current_versions/pdf/tpc-ds_v3.2.0.pdf |
| 2.1.0 | 2015/11/12 | http://www.tpc.org/tpc_documents_current_versions/pdf/tpc-ds_v2.1.0.pdf |
| 1.3.1 (earliest) | 2015/02/19 | http://www.tpc.org/tpc_documents_current_versions/pdf/tpc-ds_v1.3.1.pdf |

As of version 1.2 of this tool TPC-DS 3.2.0 is used.

## Setup
### Prerequisites

1. A running HashData Database with `gpadmin` access
2. `gpadmin` database is created
3. `root` access on the master node `mdw` for installing dependencies
4. `ssh` connections between `mdw` and the segment nodes `sdw1..n`

All the following examples are using standard host name convention of HashData using `mdw` for master node, and `sdw1..n` for the segment nodes.

### TPC-DS Tools Dependencies

Install the dependencies on `mdw` for compiling the `dsdgen` (data generation) and `dsqgen` (query generation).

```bash
ssh root@mdw
yum -y install gcc make byacc
```

The original source code is from http://tpc.org/tpc_documents_current_versions/current_specifications5.asp.

### Download and Install

Visit the repo at https://github.com/RyanWei/TPC-DS-HashData/releases/and download the tarball to the `mdw` node. You can always use the latest version.

```bash
ssh gpadmin@mdw
curl -LO https://github.com/RyanWei/TPC-DS-HashData/archive/refs/tags/v1.1.tar.gz
tar xzf v1.1.tar.gz
mv TPC-DS-HashData-1.1 TPC-DS-HashData
```
Put the folder under /home/gpadmin/ and change owner to gpadmin.

```
chown -R gpadmin.gpadmin TPC-DS-HashData
```

## Usage

To run the benchmark, login as `gpadmin` on `mdw:

```
ssh gpadmin@mdw
cd ~/TPC-DS-HashData
./run.sh
```

By default, it will run a scale 1 (1G) and with 1 concurrent users from data generation to score computation in the background.
Log will be stored with name `tpcds_<time_stamp>.log` in ~/TPC-DS-HashData.

### Configuration Options

By changing the `tpcds_variables.sh`, we can control how to run this benchmark.

This is the default example at [tpcds_variables.sh](https://github.com/RyanWei/TPC-DS-HashData/blob/main/tpcds_variables.sh)

```shell
# environment options
export ADMIN_USER="gpadmin"
export BENCH_ROLE="dsbench"
export SCHEMA_NAME="tpcds"
export GREENPLUM_PATH=$GPHOME/greenplum_path.sh
# set chip type to arm or x86 to avoid compiling TPC-DS tools from source code.
export CHIP_TYPE="arm"  
 
# default port used is configed via env setting of $PGPORT for user $ADMIN_USER
# confige the port to connect for miltiuser test if you want to use connection pools.
export PSQL_OPTIONS="-p 5432"

# benchmark options
export GEN_DATA_SCALE="1"
export MULTI_USER_COUNT="2"

# step options
# step 00_compile_tpcds
export RUN_COMPILE_TPCDS="true"

# step 01_gen_data
# To run another TPC-DS with a different BENCH_ROLE using existing tables and data
# the queries need to be regenerated with the new role
# change BENCH_ROLE and set RUN_GEN_DATA to true and GEN_NEW_DATA to false
# GEN_NEW_DATA only takes affect when RUN_GEN_DATA is true, and the default setting
# should true under normal circumstances
export RUN_GEN_DATA="true"
export GEN_NEW_DATA="true"

# step 02_init
export RUN_INIT="true"
# set this to true if binary location changed
export RESET_ENV_ON_SEGMENT='false'

# step 03_ddl
# To run another TPC-DS with a different BENCH_ROLE using existing tables and data
# change BENCH_ROLE and set RUN_DDL to true and DROP_EXISTING_TABLES to false
# DROP_EXISTING_TABLES only takes affect when RUN_DDL is true, and the default setting
# should true under normal circumstances
export RUN_DDL="true"
export DROP_EXISTING_TABLES="true"

# step 04_load
export RUN_LOAD="true"

# step 05_sql
export RUN_SQL="true"
export RUN_ANALYZE="true"
# set wait time between each query execution
export QUERY_INTERVAL="1"
# set to 1 if you want to stop when error occurs
export ON_ERROR_STOP="0"

# step 06_single_user_reports
export RUN_SINGLE_USER_REPORTS="true"

# step 07_multi_user
export RUN_MULTI_USER="false"
export RUN_QGEN="true"

# step 08_multi_user_reports
export RUN_MULTI_USER_REPORTS="false"

# step 09_score
export RUN_SCORE="false"

# misc options
export SINGLE_USER_ITERATIONS="1"
export EXPLAIN_ANALYZE="false"
export RANDOM_DISTRIBUTION="false"
export STATEMENT_MEM="2GB"
export STATEMENT_MEM_MULTI_USER="1GB"

# Set gpfdist location where gpfdist will run p (primary) or m (mirror)
export GPFDIST_LOCATION="p"
export OSVERSION=$(uname)
export MASTER_HOST=$(hostname -s)
export LD_PRELOAD=/lib64/libz.so.1 ps
```

`tpcds.sh` will validate existence of those variables.

#### Environment Options

```shell
# environment options
ADMIN_USER="gpadmin"
BENCH_ROLE="dsbench"
SCHEMA_NAME="tpcds"
GREENPLUM_PATH=$GPHOME/greenplum_path.sh
CHIP_TYPE="arm"
```

These are the setup related variables:
- `ADMIN_USER`: default `gpadmin`.
  It is the default database administrator account, as well as the user accessible to all `mdw` and `sdw1..n` machines.

- `CHIP_TYPE`: default `arm` can be set to `x86`. 
  Set this according to the CPU type of the machince running this test. If included binaries works, compiling will be skipped, otherwise, will try to compile from source code. 
  
  Included binaries: x86 on Centos7 and ARM on Centos7.

  Note: The benchmark related files for each segment node are located in the segment's `${PGDATA}/dsbenchmark` directory.
  If there isn't enough space in this directory in each segment, you can create a symbolic link to a drive location that does have enough space.

In most cases, we just leave them to the default.

#### Benchmark Options

```shell
# benchmark options
GEN_DATA_SCALE="1"
MULTI_USER_COUNT="2"
```

These are the benchmark controlling variables:
- `GEN_DATA_SCALE`: default `1`.
  Scale 1 is 1G.
- `MULTI_USER_COUNT`: default `2`.
  It's also usually referred as `CU`, i.e. concurrent user.
  It controls how many concurrent streams to run during the throughput run.


If evaluating Greenplum cluster across different platforms, we recommend to change this section to 3TB with 5CU:
```shell
# benchmark options
MULTI_USER_COUNT="5"
GEN_DATA_SCALE="3000"
```
#### Step Options

```shell
# step options
RUN_COMPILE_TPCDS="true"
RUN_GEN_DATA="true"
RUN_INIT="true"
RUN_DDL="true"
RUN_LOAD="true"
RUN_SQL="true"
RUN_SINGLE_USER_REPORT="true"
RUN_MULTI_USER="true"
RUN_MULTI_USER_REPORTS="true"
RUN_SCORE="true"
```

There are multiple steps running the benchmark and controlled by these variables:
- `RUN_COMPILE_TPCDS`: default `true`.
  It will compile the `dsdgen` and `dsqgen`.
  Usually we only want to compile those binaries once.
  In the rerun, just set this value to `false`.
- `RUN_GEN_DATA`: default `true`.
  It will use the `dsdgen` compiled above to generate the flat files for the benchmark.
  The flat files are generated in parallel on all segment nodes.
  Those files are stored under `${PGDATA}/dsbenchmark` directory.
  In the rerun, just set this value to `false`.
- `RUN_INIT`: default `true`.
  It will setup the GUCs for the Greenplum as well as remember the segment configurations.
  It's only required if the Greenplum cluster is reconfigured.
  It can be always `true` to ensure proper Greenplum cluster configuration.
  In the rerun, just set this value to `false`.
- `RUN_DDL`: default `true`.
  It will recreate all the schemas and tables (including external tables for loading).
  If you want to keep the data and just rerun the queries, please set this value to `false`, otherwise all the existing loaded data will be gone.
- `RUN_LOAD`: default `true`.
  It will load data from flat files into tables.
  After the load, the statistics will be computed in this step.
  If you just want to rerun the queries, please set this value to `false`.
- `RUN_SQL`: default `true`.
  It will run the power test of the benchmark.
- `RUN_SINGLE_USER_REPORTS`: default `true`.
  It will upload the results to the Greenplum database `gpadmin` under schema `tpcds_reports`.
  These tables are required later on in the `RUN_SCORE` step.
  Recommend to keep it `true` if above step of `RUN_SQL` is `true`.
- `RUN_MULTI_USER`: default `true`.
  It will run the throughput run of the benchmark.
  Before running the queries, multiple streams will be generated by the `dsqgen`.
  `dsqgen` will sample the database to find proper filters.
  For very large database and a lot of streams, this process can take a long time (hours) to just generate the queries.
- `RUN_MULTI_USER_REPORTS`: default `true`.
  It will upload the results to the Greenplum database `gpadmin` under schema `tpcds_reports`.
  Recommend to keep it `true` if above step of `RUN_MULTI_USER` is `true`.
- `RUN_SCORE`: default `true`.
  It will query the results from `tpcds_reports` and compute the `QphDS` based on supported benchmark standard.
  Recommend to keep it `true` if you want to see the final score of the run.

If any above variable is missing or invalid, the script will abort and show the missing or invalid variable name.

**WARNING**: Now TPC-DS does not rely on the log folder to run or skip the steps. It will only run the steps that are specified explicitly as `true`  in the `tpcds_variables.sh`. If any necessary step is speficied as `false` but has never been executed before, the script will abort when it tries to access something that does not exist in the database or under the directory.

#### Miscellaneous Options

```shell
# misc options
EXPLAIN_ANALYZE="false"
RANDOM_DISTRIBUTION="false"
SINGLE_USER_ITERATIONS="1"
```

These are miscellaneous controlling variables:
- `EXPLAIN_ANALYZE`: default `false`.
  If you set to `true`, you can have the queries execute with `EXPLAIN ANALYZE` in order to see exactly the query plan used, the cost, the memory used, etc.
  This option is for debugging purpose only, since collecting those query statistics will disturb the benchmark.
- `RANDOM_DISTRIBUTION`: default `false`.
  If you set to `true`, the fact tables are distributed randomly other than following a pre-defined distribution column.
- `SINGLE_USER_ITERATION`: default `1`.
  This controls how many times the power test will run.
  During the final score computation, the minimal/fastest query elapsed time of multiple runs will be used.
  This can be used to ensure the power test is in a `warm` run environment.

### Storage Options

Table storage is defined in `functions.sh` and is configured for optimal performance.
`get_version()` function defines different storage options for different scale of the benchmark.
- `SMALL_STORAGE`: All the dimension tables
- `MEDIUM_STORAGE`: `catalog_returns` and `store_returns`
- `LARGE_STORAGE`: `catalog_sales`, `inventory`, `store_sales`, and `web_sales`

Table distribution keys are defined in `../03_ddl/distribution.txt`, you can modify tables' distribution keys by changing this file. You can set the distribution method to hash with colunm names or "REPLICATED".


### Execution

Running the benchmark as a background process:

```bash
sh run.sh
```

### Play with different options
- Change different storage options in `functions.sh` to try with different compress options and whether use AO/CO storage.
- Replace some of the tables' DDL with the `*.sql.partition` files in folder `03_ddl` to use partition for some of the non-dimension tables. No partition is used by default.
- Steps `RUN_COMPILE_TPCDS` and `RUN_GEN_DATA` only need to be executed once. 


## Benchmark Minor Modifications

### 1. Change to SQL queries that subtracted or added days were modified slightly:

Old:
```sql
and (cast('2000-02-28' as date) + 30 days)
```

New:

```sql
and (cast('2000-02-28' as date) + '30 days'::interval)
```

This was done on queries: 5, 12, 16, 20, 21, 32, 37, 40, 77, 80, 82, 92, 94, 95, and 98.

### 2. Change to queries with ORDER BY on column alias to use sub-select.

Old:
```sql
select  
    sum(ss_net_profit) as total_sum
   ,s_state
   ,s_county
   ,grouping(s_state)+grouping(s_county) as lochierarchy
   ,rank() over (
 	partition by grouping(s_state)+grouping(s_county),
 	case when grouping(s_county) = 0 then s_state end 
 	order by sum(ss_net_profit) desc) as rank_within_parent
 from
    store_sales
   ,date_dim       d1
   ,store
 where
    d1.d_month_seq between 1212 and 1212+11
 and d1.d_date_sk = ss_sold_date_sk
 and s_store_sk  = ss_store_sk
 and s_state in
             ( select s_state
               from  (select s_state as s_state,
 			    rank() over ( partition by s_state order by sum(ss_net_profit) desc) as ranking
                      from   store_sales, store, date_dim
                      where  d_month_seq between 1212 and 1212+11
 			    and d_date_sk = ss_sold_date_sk
 			    and s_store_sk  = ss_store_sk
                      group by s_state
                     ) tmp1 
               where ranking <= 5
             )
 group by rollup(s_state,s_county)
 order by
   lochierarchy desc
  ,case when lochierarchy = 0 then s_state end
  ,rank_within_parent
 limit 100;
```

New:
```sql
select * from ( --new
select  
    sum(ss_net_profit) as total_sum
   ,s_state
   ,s_county
   ,grouping(s_state)+grouping(s_county) as lochierarchy
   ,rank() over (
 	partition by grouping(s_state)+grouping(s_county),
 	case when grouping(s_county) = 0 then s_state end 
 	order by sum(ss_net_profit) desc) as rank_within_parent
 from
    store_sales
   ,date_dim       d1
   ,store
 where
    d1.d_month_seq between 1212 and 1212+11
 and d1.d_date_sk = ss_sold_date_sk
 and s_store_sk  = ss_store_sk
 and s_state in
             ( select s_state
               from  (select s_state as s_state,
 			    rank() over ( partition by s_state order by sum(ss_net_profit) desc) as ranking
                      from   store_sales, store, date_dim
                      where  d_month_seq between 1212 and 1212+11
 			    and d_date_sk = ss_sold_date_sk
 			    and s_store_sk  = ss_store_sk
                      group by s_state
                     ) tmp1 
               where ranking <= 5
             )
 group by rollup(s_state,s_county)
) AS sub --new
 order by
   lochierarchy desc
  ,case when lochierarchy = 0 then s_state end
  ,rank_within_parent
 limit 100;
```

This was done on queries: 36 and 70.

### 3. Query templates were modified to exclude columns not found in the query.

In these cases, the common table expression used aliased columns but the dynamic filters included both the alias name as well as the original name.
Referencing the original column name instead of the alias causes the query parser to not find the column.

This was done on query 86.

### 4. Added table aliases.
This was done on queries: 2, 14, and 23.

### 5. Added `limit 100` to very large result set queries.
For the larger tests (e.g. 15TB), a few of the TPC-DS queries can output a very large number of rows which are just discarded.

This was done on queries: 64, 34, and 71.
