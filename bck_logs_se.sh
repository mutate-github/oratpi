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

etime=`ps -eo 'pid,etime,args' | grep $0 | awk '!/grep|00:0[0123]/{print $2}' | head -1`
echo "etime: "$etime
if [[ -n "$etime" ]] && [[ ! "$etime" =~ "00:0[0123]" ]]; then
   echo "Previous script did not finish. "`date`
   ps -eo 'pid,ppid,lstart,etime,args' | grep $0 | awk '!/grep|00:0[0123]/'
   echo "Cancelling today's backup and exiting ..."
   exit 127
fi

# $1 is client name
# $2 is optional parameter, sample usage:
# $0 nomad aisprod:aisutf:nas:REDUNDANCY:1:nocatalog:0   - start single backup archivelogs with partucular parameters
# $0 nomad aisprod                                    - start multiple backups archivelogs with partucular parameters from mon.ini.$CLIENT
HDSALL=$1
echo `date`"   HDSALL: "$HDSALL

LOGDIR="$BASEDIR/../log"
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi
ADMINS=`$BASEDIR/iniget.sh $CONFIG admins email`
TARGET=`$BASEDIR/iniget.sh $CONFIG backup target`
TNS_CATALOG=`$BASEDIR/iniget.sh $CONFIG backup tns_catalog`
HOST_DB_SET=`$BASEDIR/iniget.sh $CONFIG backup host:db:set`
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
SET_ENV_F="$BASEDIR/set_env"
SET_ENV=`cat $SET_ENV_F`
me=$$
ONE_EXEC_F=$BASEDIR/one_exec_bck_logs_${me}.sh

if [ -z "$HDSALL" ]; then
  HDSLST=$HOST_DB_SET
else
  if [[ "$HDSALL" =~ ":" ]]; then
    HDSLST=$HDSALL
  else
    HDSLST=`$BASEDIR/iniget.sh $CONFIG backup host:db:set | grep "$HDSALL"`
  fi
fi

for HDS in `echo "$HDSLST" | xargs -n1 echo`; do
  HOST=`echo $HDS | awk -F: '{print $1}'`
  DB=`echo $HDS | awk -F: '{print $2}'`
  NAS=`echo $HDS | awk -F: '{print $3}'`
  HOST_STB_SE=`$BASEDIR/iniget.sh $CONFIG standby $HOST`
  logf="$LOGDIR/bck_logs_${HOST}_${DB}.log"
  exec >> $logf 2>&1
  echo "DEBUG HOST="$HOST"   DB="$DB"   NAS="$NAS"  HOST_STB_SE="$HOST_STB_SE

  CATALOG=`echo $HDS | awk -F: '{print $6}'`
  shopt -s nocasematch
  if [[ "$CATALOG" = nocatalog ]]; then
     TNS_CATALOG=""
  fi
  shopt -u nocasematch


HOST_STB_DB=`echo $HOST_STB_SE | awk -F: '{print $1}'`
HOST_STB_STB=`echo $HOST_STB_SE | awk -F: '{print $2}'`
if [ -n "$HOST_STB_SE" -a "$HOST_STB_DB" = "$DB" ]; then
  VALUE_STB=$(cat << EOF | $SSHCMD $HOST_STB_STB "/bin/bash -s $HOST_STB_DB"
#!/bin/bash
sid=\$1
$SET_ENV
export ORACLE_SID=\$sid
  sqlplus -S '/as sysdba' <<- 'END'
  set pagesize 0 feedback off verify off heading off echo off timing off
  select max(fhrba_Seq) from x\$kcvfh;
END
EOF
)
 VALUE_STB=`echo $VALUE_STB | sed -e 's/^ //'`
 VALUE_STB=`expr $VALUE_STB - 1`
 LOGS="until logseq=$VALUE_STB not backed up 1 times"
 if [ -z "$VALUE_STB" ]; then
   echo "standby don't answer, then:  until logseq=0"
   LOGS="until logseq=0 not backed up 1 times"
 fi
else
#   LOGS="until time 'sysdate' not backed up 1 times"
   LOGS="all"
fi
echo "LOGS: "$LOGS



cat << EOF_CREATE_F1 > $ONE_EXEC_F
#!/bin/bash
sid=\$1
# echo "sid="\$sid
$SET_ENV
export ORACLE_SID=\$sid

INF_STR="HOST: $HOST, DB: $DB, NAS: $NAS, CATALOG: $CATALOG $TNS_CATALOG, HOST_STB_SE: $HOST_STB_SE"

echo "START ARCHIVELOGS BACKUP > \$INF_STR  at `date`"
echo "==========================================================================================================================="

\$ORACLE_HOME/bin/rman target $TARGET $CATALOG $TNS_CATALOG << EOF
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/$NAS/$DB/ctl_%d_%F';
CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;
run{
  allocate channel cpu1 type disk;
  allocate channel cpu2 type disk;
  sql 'alter system archive log current';
#  backup AS COMPRESSED BACKUPSET archivelog until time 'sysdate' not backed up 1 times format '/$NAS/$DB/logs_%d_%t_%U' delete input tag 'ARCHIVELOGS';
  backup AS COMPRESSED BACKUPSET archivelog $LOGS format '/$NAS/$DB/logs_%d_%t_%U' delete input tag 'ARCHIVELOGS';
}
EOF
echo "FINISH ARCHIVELOGS BACKUP > \$INF_STR at `date`"
echo "==========================================================================================================================="
EOF_CREATE_F1

  cat ${ONE_EXEC_F} | $SSHCMD $HOST "/bin/bash -s $DB" >> $logf
  rm $ONE_EXEC_F
done

