#!/bin/bash
set -f

CLIENT="$1"
BASEDIR=$(dirname $0)
CONFIG="mon.ini"
if [ -n "$CLIENT" ]; then
  shift
  CONFIG=${CONFIG}.${CLIENT}
  if [ ! -s "$BASEDIR/$CONFIG" ]; then echo "Exiting... Config not found: "$CONFIG ; exit 128; fi
fi
echo "Starting $0 at: "$(date +%d/%m/%y-%H:%M:%S)
echo "Using config: ${CONFIG}"

LOGDIR="$BASEDIR/../log"
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi
HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host)
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
SET_ENV_F="$BASEDIR/set_env"
SET_ENV=$(<$SET_ENV_F)
ONE_EXEC_F=$BASEDIR/one_exec_mon_sysm_se_${me}.sh

cat << EOF_CREATE_F > $ONE_EXEC_F
#!/bin/bash
sid=\$1
# echo "sid="\$sid
$SET_ENV
export ORACLE_SID=\$sid

sqlplus -s '/as sysdba' <<'EOS'
-- NCPU HCPUB CPUUPS LOAD DCTR DWTR   SPFR   TPGA   SCT   AAS   AST ASCPU  ASIO  ASWA  ASPQ   UTPS     UCPS     SSRT   MBPS    IOPS   IORL       LOGR    PHYR    PHYW   TEMP   DBTM
set lines 250 pages 100 numw 7
col BEGIN_TIME for a17
col NCPU for 999
col IORL for 999
SELECT  /*+ OPT_PARAM('_optimizer_adaptive_plans','false') */   /*+ NO_MONITOR */
      to_char(sysdate,'dd/mm/yy-hh24:mi:ss')  BEGIN_TIME,
      ncpu,                           --'NUM_CPUS'
--      inid,                         --   ID        [c,N]: inst_id (instance id)
      trunc(hcpu) HCPUB,              --   %CPU      [m,N]: host cpu busy %(busy/busy+idle). (red if > 90%)
      trunc(dcpu) CPUUPS,             --'CPU Usage Per Sec'  'CentiSeconds Per Second'
      trunc(load) load,               --   LOAD      [m,N]: current os load. (red if > 2*#cpu '&' high cpu)
      trunc(dbcp) DCTR,               --   DCTR      [m,N]: database cpu time ratio
      trunc(dbwa) DWTR,               --   DWTR      [m,N]: database wait time ratio. (red if > 50 '&' high ASW)
      trunc(sgfr) SPFR,               --   %FR       [s,N]: shared pool free %
      round(upga/1024/1024,0) TPGA,   --   PGA       [s,N]: total pga allocated
--      sct,                          --   SCT       from gv\$sysmetric metric_name, 'Session Count',
      isct SCT,                       --   UST       [c,N]: user Sessions Total (ACT/INA) from gv\$session
      trunc(saas) AAS,                --   AAS       [s,N]: Average Active Sessions. (red if > #cpu)
      asct AST,                       --   AST       [c,N]: Active user Sessions Total (ASC+ASI+ASW)
      cpas ASCPU,                     --?  ASC       [c,N]: active Sessions on CPU
      ioas ASIO,                      --?  ASI       [c,N]: active Sessions waiting on user I/O
      waas ASWA,                      --?  ASW       [c,N]: active Sessions Waiting, non-ASI (red if > ASC+ASI)
      aspq ASPQ,                      --'Active Parallel Sessions'
      trunc(utps) utps,               --   UTPS      [s,N]: user transactions per sec
      trunc(ucps) ucps,               --   UCPS    [c,m,N]: user calls per sec
      trunc(ssrt*10000) ssrt,         --   SSRT    [c,m,T]: sql service response time (T/call)
      trunc(mbps) mbps,               --   MBPS      [m,N]: i/o megabytes per second (throughput)
      trunc(iops) iops,               --   IOPS      [m,N]: i/o requests per second
      trunc(iorl) iorl,               --   IORL      [m,T]: avg synchronous single-block read latency. (red > 20ms)
      trunc(logr) logr,               --   LOGR      [s,N]: logical reads per sec
      trunc(phyr) phyr,               --   PHYR      [s,N]: physical reads per sec
      trunc(phyw) phyw,               --   PHYW      [s,N]: physical writes per sec
      round(temp/1024/1024,0) temp,   --   TEMP      [s,N]: temp space used
      trunc(dbtm) dbtm                --'Database Time Per Sec'
  FROM   (  SELECT
                  inst_id  inid,
                     SUM(DECODE (metric_name, 'CPU Usage Per Sec', VALUE, 0)) dcpu,
                     SUM(DECODE (metric_name, 'Host CPU Utilization (%)', VALUE, 0)) hcpu,
                     SUM(DECODE (metric_name, 'I/O Megabytes per Second', VALUE, 0)) mbps,
                     SUM(DECODE (metric_name, 'SQL Service Response Time', VALUE, 0)) ssrt,
                     SUM(DECODE (metric_name, 'Average Synchronous Single-Block Read Latency', VALUE, 0)) iorl,
                     SUM(DECODE (metric_name, 'Current OS Load', VALUE, 0)) load,
                     SUM(DECODE (metric_name, 'Active Parallel Sessions', VALUE, 0)) aspq,
                     SUM(DECODE (metric_name, 'Session Count', VALUE, 0)) sct,
                     SUM(DECODE (metric_name, 'Database CPU Time Ratio', VALUE, 0)) dbcp,
                     SUM(DECODE (metric_name, 'Database Wait Time Ratio', VALUE, 0)) dbwa,
                     SUM(DECODE (metric_name, 'I/O Requests per Second', VALUE, 0)) iops
              FROM   gv\$sysmetric
             WHERE   metric_name IN
                             ('CPU Usage Per Sec',
                              'Host CPU Utilization (%)',
                              'I/O Megabytes per Second',
                              'SQL Service Response Time',
                              'Average Synchronous Single-Block Read Latency',
                              'Current OS Load',
                              'Active Parallel Sessions',
                              'Session Count',
                              'Database CPU Time Ratio',
                              'Database Wait Time Ratio',
                              'I/O Requests per Second')
                     AND GROUP_ID = 2
          GROUP BY   inst_id),
         (  SELECT
                     inst_id id1,
                     SUM(DECODE (metric_name, 'Shared Pool Free %', VALUE, 0)) sgfr,
                     SUM(DECODE (metric_name, 'User Transaction Per Sec', VALUE, 0)) utps,
                     SUM(DECODE (metric_name, 'User Calls Per Sec', VALUE, 0)) ucps,
                     SUM(DECODE (metric_name, 'Average Active Sessions', VALUE, 0)) saas,
                     SUM(DECODE (metric_name, 'Total PGA Allocated', VALUE, 0)) upga,
                     SUM(DECODE (metric_name, 'Logical Reads Per Sec', VALUE, 0)) logr,
                     SUM(DECODE (metric_name, 'Physical Reads Per Sec', VALUE, 0)) phyr,
                     SUM(DECODE (metric_name, 'Physical Writes Per Sec', VALUE, 0)) phyw,
                     SUM(DECODE (metric_name, 'Temp Space Used', VALUE, 0)) temp,
                     SUM(DECODE (metric_name, 'Database Time Per Sec', VALUE, 0)) dbtm
              FROM   gv\$sysmetric
             WHERE   metric_name IN
                             ('Shared Pool Free %',
                              'User Transaction Per Sec',
                              'User Calls Per Sec',
                              'Logical Reads Per Sec',
                              'Physical Reads Per Sec',
                              'Physical Writes Per Sec',
                              'Temp Space Used',
                              'Database Time Per Sec',
                              'Average Active Sessions',
                              'Total PGA Allocated')
                     AND GROUP_ID = 3
          GROUP BY   inst_id),
         (  SELECT   id2,
                     SUM (asct) asct,
                     SUM (isct) isct,
                     SUM (cpas) cpas,
                     SUM (ioas) ioas,
                     SUM (waas) waas
              FROM   (  SELECT
                              inst_id id2,
                                 SUM(DECODE (status, 'ACTIVE', 1, 0)) asct, COUNT ( * ) isct,
                                 SUM(DECODE (status, 'ACTIVE', DECODE (wait_time, 0, 0, 1), 0)) cpas,
                                 SUM(DECODE (status, 'ACTIVE', DECODE (wait_class, 'User I/O', 1, 0), 0)) ioas,
                                 SUM(DECODE (status, 'ACTIVE', DECODE (wait_time, 0, DECODE (wait_class,'User I/O', 0, 1), 0), 0)) waas
                          FROM   gv\$session
                         WHERE       TYPE <> 'BACKGROUND'
                                 AND username IS NOT NULL
                                 AND schema# != 0
                      GROUP BY   inst_id
                      UNION ALL
                      SELECT
                              inst_id
                                     id2,
                                 0 asct,
                                 0 isct,
                                 0 cpas,
                                 0 ioas,
                                 0 waas
                          FROM   gv\$instance)
            GROUP BY   id2),
           (SELECT
                  inst_id id3, TO_NUMBER (VALUE) ncpu
              FROM   gv\$osstat
             WHERE   stat_name = 'NUM_CPUS')
   WHERE   id1 = inid AND id2 = inid AND id3 = inid AND ROWNUM <= 5
ORDER BY   dbtm DESC;
EOS
EOF_CREATE_F

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "HOST="$HOST
  DBS=$($BASEDIR/iniget.sh $CONFIG $HOST db)
  for DB in $(xargs -n1 echo <<< "$DBS"); do
    echo "DB="$DB
    LOGF=$LOGDIR/mon_sysm_se_db_${HOST}_${DB}.log
    cat $ONE_EXEC_F | $SSHCMD $HOST "/bin/bash -s $DB" >> $LOGF
#    exec >> $LOGF 2>&1
  done
done

rm $ONE_EXEC_F

