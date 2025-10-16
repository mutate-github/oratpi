#!/bin/bash
set -f

CLIENT="$1"
BASEDIR=`dirname $0`
CONFIG="mon.ini"
if [ -n "$CLIENT" ]; then
  shift
  CONFIG=${CONFIG}.${CLIENT}
  if [ ! -s "$BASEDIR/$CONFIG" ]; then echo "Exiting... Config not found: "$CONFIG ; exit 128; fi
fi
echo "Using config: ${CONFIG}"

etime=`ps -eo 'pid,etime,args' | grep $0 | awk '!/grep|00:0[0123]/{print $2}'`
echo "etime: "$etime
if [[ -n "$etime" ]] && ( ! grep -q "00:0[0123]" <<< "$etime" ); then
   echo "Previous script did not finish. "`date`
   ps -eo 'pid,ppid,lstart,etime,args' | grep $0 | awk '!/grep|00:0[0123]/'
   echo "Cancelling today's backup and exiting ..."
   exit 127
fi
# this scriopt optimized for for oracle 9i
# $1 client name
# $2 is optional parameter, sample usage:
# $0 ipoteka vhost0:jet:nas:RECOVERY_WINDOW:1:nocatalog:2   - start single backup with partucular parameters
# $0 ipoteka vhost0:jet:nas:RECOVERY_WINDOW:7:nocatalog:3   - start single backup with partucular parameters LEVEL [7] more than "2" will execute with:  "not backed up since time 'sysdate-1'"
# $0 ipoteka vhost0                                         - start multiple backups with partucular parameters from mon.ini.$CONFIG
HDSALL=$1
DS_=`date '+%m%d_%H-%M'`
echo $DS_"   HDSALL: "$HDSALL

LOGDIR="$BASEDIR/../log"
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi
MAILS=`$BASEDIR/iniget.sh $CONFIG mail script`
WMMAIL="$BASEDIR/$MAILS"
MPREFIX=`$BASEDIR/iniget.sh $CONFIG mail prefix`
ADMINS=`$BASEDIR/iniget.sh $CONFIG admins email`
TARGET=`$BASEDIR/iniget.sh $CONFIG backup target`
TNS_CATALOG=`$BASEDIR/iniget.sh $CONFIG backup tns_catalog`
HOST_DB_SET=`$BASEDIR/iniget.sh $CONFIG backup host:db:set`
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
shopt -s extglob
LEVEL0="+("`$BASEDIR/iniget.sh $CONFIG backup level0 | sed 's/,/|/g'`")"
LEVEL1="+("`$BASEDIR/iniget.sh $CONFIG backup level1 | sed 's/,/|/g'`")"
LEVEL2="+("`$BASEDIR/iniget.sh $CONFIG backup level2 | sed 's/,/|/g'`")"
SET_ENV_F="$BASEDIR/set_env"
SET_ENV=`cat $SET_ENV_F`
me=$$
ONE_EXEC_F=$BASEDIR/one_exec_bck_db_${me}.sh

if [ -z "$HDSALL" ]; then
  HDSLST=$HOST_DB_SET
else
  if ( grep -q ":" <<< "$HDSALL" ); then
    HDSLST=$HDSALL
  else
    HDSLST=`$BASEDIR/iniget.sh $CONFIG backup host:db:set | grep "$HDSALL"`
  fi
fi

LOGF_TOTAL="$LOGDIR/bck_db_total_${DS_}.log"
echo "Start time: "$DS_  > $LOGF_TOTAL

for HDS in `echo $HDSLST | xargs -n1 echo`; do
  HOST=`echo $HDS | awk -F: '{print $1}'`
  DB=`echo $HDS | awk -F: '{print $2}'`
  NAS=`echo $HDS | awk -F: '{print $3}'`
  RP=`echo $HDS | awk -F: '{print $4}' | sed 's/_/ /g'`
  RP2=`echo $HDS | awk -F: '{print $5}'`
  CATALOG=`echo $HDS | awk -F: '{print $6}'`
  LVL=`echo $HDS | awk -F: '{print $7}'`

  logf="$LOGDIR/bck_db_${HOST}_${DB}_`date '+%m%d_%H-%M'`.log"
  exec > $logf 2>&1
  #exec &> >(tee -a "$logf")

  shopt -s nocasematch
  if ( grep -q "WINDOW" <<< "$RP" ); then DAYS="DAYS"; else DAYS=""; fi
  RETENTION="CONFIGURE RETENTION POLICY TO "$RP" "$RP2" ${DAYS};"
  if [[ "$CATALOG" = nocatalog ]]; then
     TNS_CATALOG=""
  fi
  shopt -u nocasematch

  if [ -z "$LVL" ]; then
    WD=`date +"%a"`
    case $WD in
      ${LEVEL0}) LVL=0 ;;
      ${LEVEL1}) LVL=1 ;;
      ${LEVEL2}) LVL=2 ;;
      *)         LVL=2 ;;
    esac
  else
    case "$LVL" in
      0|1|2) : ;;
      *)     LVL=0 ;  not_backed="not backed up since time 'sysdate-1'" ;;
    esac
  fi
  echo "DEBUG: LVL="${LVL} "   not_backed: "$not_backed



cat << EOF_CREATE_F1 > $ONE_EXEC_F
#!/bin/bash
sid=\$1
# echo "sid="\$sid
$SET_ENV
export ORACLE_SID=\$sid

INF_STR="HOST: $HOST, DB: $DB, NAS: $NAS, RET_POL: $RP $RP2, CATALOG: $CATALOG, LEVEL: $LVL"

echo "START BACKUP > \$INF_STR at `date`"
echo "=============================================================================================================="

echo "alter system set control_file_record_keep_time=60;" | sqlplus '/as sysdba'

\$ORACLE_HOME/bin/rman target $TARGET $CATALOG $TNS_CATALOG << EOF
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE CHANNEL DEVICE TYPE DISK MAXPIECESIZE 2G;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/$NAS/$DB/ctl_%d_%F';
run {
  allocate channel cpu1 type disk;
  allocate channel cpu2 type disk;
  backup incremental level = $LVL database filesperset 1 $not_backed
  format '/$NAS/$DB/level_${LVL}_%d_%t_%U' TAG 'LEVEL_${LVL}';
  backup archivelog all format '/$NAS/$DB/logs_%d_%t_%U' delete input TAG 'ARCHIVELOGS';
  backup spfile format '/$NAS/$DB/spfile_%d_%U.bck' TAG 'SPFILE';
}
EOF

echo "FINISH BACKUP > \$INF_STR at `date`"
echo "=============================================================================================================="

echo "START DELETE REDUNDANT BACKUPSET > \$INF_STR at `date`"
echo "--------------------------------------------------------------------------------------------------------------"

VALUE=\`sqlplus -s '/as sysdba' <<'END'
set pagesize 0 feedback off verify off heading off echo off
select database_role from v\$database;
END\`
echo "VALUE of database_role: "\$VALUE
if ( grep -q "PRIMARY" <<< "\$VALUE" ); then
  RETENTION_="$RETENTION"
fi

\$ORACLE_HOME/bin/rman target $TARGET $CATALOG $TNS_CATALOG <<EOF
allocate channel for maintenance type disk;
\$RETENTION_
delete noprompt obsolete;
EOF

echo "FINISH DELETE REDUNDANT BACKUPSET > \$INF_STR at `date`"
echo "--------------------------------------------------------------------------------------------------------------"
EOF_CREATE_F1

  cat $ONE_EXEC_F | $SSHCMD $HOST "/bin/bash -s $DB" >> $logf
  rm $ONE_EXEC_F
  exec >> $logf 2>&1

  if ( grep -q "RMAN-" <<< $(cat $logf) ); then
    BCK_STATUS=" completed with FAILURE"
    FAILURE_LIST=$DB" "$FAILURE_LIST
  else
    BCK_STATUS=" completed with SUCCESS"
    SUCCESS_LIST=$DB" "$SUCCESS_LIST
  fi
  HOST_DB=$HOST"/"$DB" "$HOST_DB

  echo "" > $logf.mail.log
  sed -n '/Backups last/,$p' $logf  >> $logf.mail.log
  echo "" >> $logf.mail.log
  echo "Details:" >> $logf.mail.log
  echo "----------------------------------------------------------------------" >> $logf.mail.log
  egrep -i "input |oradata|LEVEL-|/oracle|error|REDUNDANT|RMAN-" $logf          >> $logf.mail.log
  echo "----------------------------------------------------------------------" >> $logf.mail.log

  echo "Backup Report for:" >> $LOGF_TOTAL
  echo "HOST: $HOST, DB: $DB, NAS: $NAS, LVL: $LVL  -  $BCK_STATUS" >> $LOGF_TOTAL
  cat $logf.mail.log  >> $LOGF_TOTAL

  rm ${logf}.mail.log

done  # for $HDS


exec >> $logf 2>&1
cat $LOGF_TOTAL | $WMMAIL -s "$MPREFIX BACKUP Report (HOST/DB: $HOST_DB) Success list (${SUCCESS_LIST}) / Failure list (${FAILURE_LIST})" $ADMINS  # 2>/dev/null

find $LOGDIR -name "bck_db_*.log" -mtime +31 -exec rm -f {} \;

