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

# $1 is clietn name
# $2 is optional parameter, sample usage:
# $0 ipoteka vhost0:jet:nas:REDUNDANCY:1:nocatalog:0   - start single backup archivelogs with partucular parameters
# $0 ipoteka vhost0                                    - start multiple backups archivelogs with partucular parameters from mon.ini.$CONFIG
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
   if ( grep -q ":" <<< "$HDSALL" ); then
    HDSLST=$HDSALL
  else
    HDSLST=`$BASEDIR/iniget.sh $CONFIG backup host:db:set | grep "$HDSALL"`
  fi
fi
echo "HDSLST: "$HDSLST

for HDS in `echo "$HDSLST" | xargs -n1 echo`; do
  HOST=`echo $HDS | awk -F: '{print $1}'`
  DB=`echo $HDS | awk -F: '{print $2}'`
  NAS=`echo $HDS | awk -F: '{print $3}'`
  echo "DEBUG HOST="$HOST"   DB="$DB"   NAS="$NAS

  logf="$LOGDIR/bck_logs_${HOST}_${DB}.log"
  exec >> $logf 2>&1

  CATALOG=`echo $HDS | awk -F: '{print $6}'`
  shopt -s nocasematch
  if [[ "$CATALOG" = nocatalog ]]; then
     TNS_CATALOG=""
  fi
  shopt -u nocasematch

cat << EOF_CREATE_F1 > $ONE_EXEC_F
#!/bin/bash
sid=\$1
# echo "sid="\$sid
$SET_ENV
export ORACLE_SID=\$sid

INF_STR="HOST: $HOST, DB: $DB, NAS: $NAS, CATALOG: $CATALOG $TNS_CATALOG"

echo "START ARCHIVELOGS BACKUP > \$INF_STR  at `date`"
echo "==========================================================================================================================="

\$ORACLE_HOME/bin/rman target $TARGET $CATALOG $TNS_CATALOG << EOF
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/$NAS/$DB/ctl_%d_%F';
run{
  allocate channel cpu1 type disk;
  allocate channel cpu2 type disk;
  sql 'alter system archive log current';
  backup archivelog until time 'sysdate' not backed up 1 times format '/$NAS/$DB/logs_%d_%t_%U' delete input tag 'ARCHIVELOGS';
}
EOF
echo "FINISH ARCHIVELOGS BACKUP > \$INF_STR at `date`"
echo "==========================================================================================================================="
EOF_CREATE_F1

  cat ${ONE_EXEC_F} | $SSHCMD $HOST "/bin/bash -s $DB" >> $logf
  rm $ONE_EXEC_F
done

