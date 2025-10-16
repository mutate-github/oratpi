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
echo "Using config: ${CONFIG}"

etime=$(ps -eo 'pid,etime,args' | grep $0 | awk '!/grep|00:0[0123]/{print $2}')
echo "etime: "$etime
if [[ -n "$etime" ]] && [[ ! "$etime" =~ "00:0[0123]" ]]; then
   echo "Previous script did not finish. "$(date)
   ps -eo 'pid,ppid,lstart,etime,args' | grep $0 | awk '!/grep|00:0[0123]/'
   echo "Cancelling today's backup and exiting ..."
   exit 127
fi

# $1 is clietn name
# $2 is optional parameter, sample usage:
# $0 client kikdb02:cft:u15:REDUNDANCY:1:nocatalog:0   - start single backup archivelogs with partucular parameters
# $0 client kikdb02                                    - start multiple backups archivelogs with partucular parameters from mon.ini.$CONFIG
HDSALL=$1
echo $(date)"   HDSALL: "$HDSALL

LOGDIR="$BASEDIR/../log"
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi
ADMINS=$($BASEDIR/iniget.sh $CONFIG admins email)
TARGET=$($BASEDIR/iniget.sh $CONFIG backup target)
TNS_CATALOG=$($BASEDIR/iniget.sh $CONFIG backup tns_catalog)
HOST_DB_SET=$($BASEDIR/iniget.sh $CONFIG backup host:db:set)
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
SET_ENV_F="$BASEDIR/set_env"
SET_ENV=$(cat $SET_ENV_F)
me=$$
ONE_EXEC_F=$BASEDIR/one_exec_bck_logs_${me}.sh

if [ -z "$HDSALL" ]; then
  HDSLST=$HOST_DB_SET
else
  if [[ "$HDSALL" =~ ":" ]]; then
    HDSLST=$HDSALL
  else
    HDSLST=$($BASEDIR/iniget.sh $CONFIG backup host:db:set | grep "$HDSALL")
  fi
fi

for HDS in $(echo "$HDSLST" | xargs -n1 echo); do
  HOST=$(echo $HDS | awk -F: '{print $1}')
  DB=$(echo $HDS | awk -F: '{print $2}')
  NAS=$(echo $HDS | awk -F: '{print $3}')
  echo "DEBUG HOST="$HOST"   DB="$DB"   NAS="$NAS

  logf="$LOGDIR/bck_logs_${HOST}_${DB}.log"
  exec >> $logf 2>&1

  CATALOG=$(echo $HDS | awk -F: '{print $6}')
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

DB_UNIQUE_NAME=\$(sqlplus -S '/ as sysdba' <<'EOF'
set heading off feedback off pagesize 0 trimspool on
select value  from v\$parameter where name='db_unique_name';
EOF
)

DB_ROLE=\`sqlplus -s '/as sysdba' <<'END'
set pagesize 0 feedback off verify off heading off echo off
select database_role from v\$database;
END\`

if [[ "\$DB_ROLE" =~ "PRIMARY" ]]; then
  SQL1="sql 'alter system archive log current';"
fi

mkdir -p /$NAS/\$DB_UNIQUE_NAME

INF_STR="HOST: $HOST, DB: $DB, DB_UNIQUE_NAME: \$DB_UNIQUE_NAME, DATABASE_ROLE: \$DB_ROLE, NAS: $NAS, CATALOG: $CATALOG $TNS_CATALOG"

echo "START ARCHIVELOGS BACKUP > \$INF_STR  at \$(date)"
echo "==========================================================================================================================="

\$ORACLE_HOME/bin/rman target $TARGET $CATALOG $TNS_CATALOG << EOF
CONFIGURE DEFAULT DEVICE TYPE TO DISK;
CONFIGURE CONTROLFILE AUTOBACKUP ON;
CONFIGURE COMPRESSION ALGORITHM 'MEDIUM';
CONFIGURE CONTROLFILE AUTOBACKUP FORMAT FOR DEVICE TYPE DISK TO '/$NAS/\$DB_UNIQUE_NAME/ctl_%d_%F';
CONFIGURE ARCHIVELOG DELETION POLICY TO APPLIED ON ALL STANDBY;
show all;
run{
  allocate channel cpu1 type disk;
  allocate channel cpu2 type disk;
  \$SQL1
#  backup AS COMPRESSED BACKUPSET filesperset = 20 archivelog all
#  not backed up 1 times
#  format '/$NAS/\$DB_UNIQUE_NAME/logs_%d_%t_%U'
#  delete input;
  backup AS COMPRESSED BACKUPSET archivelog until time 'sysdate' not backed up 1 times format '/$NAS/\$DB_UNIQUE_NAME/logs_%d_%t_%U' delete input tag 'ARCHIVELOGS';
}
EOF
echo "FINISH ARCHIVELOGS BACKUP > \$INF_STR at \$(date)"
echo "==========================================================================================================================="
EOF_CREATE_F1

  cat ${ONE_EXEC_F} | $SSHCMD $HOST "/bin/bash -s $DB" >> $logf
  rm $ONE_EXEC_F
done

