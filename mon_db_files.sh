#!/bin/bash

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
WRTPI="$BASEDIR/rtpi"
HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host)
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
SET_ENV_F="$BASEDIR/set_env"
SET_ENV=$(<$SET_ENV_F)
DB_FILES_USAGE_LIMIT=$($BASEDIR/iniget.sh $CONFIG threshold DB_FILES_USAGE_LIMIT)
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)
ME=$(basename $0)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
#--- skip for host:db:script1:script2
    skip_outer_loop_db=0
    for EXCL in $(xargs -n1 echo <<< $SCRIPTS_EXCLUDE); do
       HOST_=$(awk -F: '{print $1}' <<< $EXCL)
       DB_=$(awk -F: '{print $2}' <<< $EXCL)
       SCRIPTS_=$(cut -d':' -f3- <<< $EXCL)
       if [[ "$HOST_" = "$HOST" || "$HOST_" = % ]] && [[ "$DB_" = "$DB" || "$DB_" = % ]]  && [[ "$SCRIPTS_" == *"$ME"* || "$SCRIPTS_" == *%* ]]; then
         echo "Find EXCLUDE HOST:   $HOST in   EXCL: $EXCL"
         echo "Find EXCLUDE DB:     $DB   in   EXCL: $EXCL"
         echo "Find EXCLUDE SCRIPT: $ME   in   SCRIPTS_: $SCRIPTS_" ; skip_outer_loop_db=1; break
       fi
    done
    if [ "$skip_outer_loop_db" -eq 1 ]; then echo "SKIP and continue outher loop db!"; continue; fi
#--- end skip for db

  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  DBS=$($BASEDIR/iniget.sh $CONFIG $HOST db)
  for DB in $(xargs -n1 echo <<< "$DBS"); do
    echo "DB="$DB

VALUE=$(echo -e "#!/bin/bash
sid=\$1
# echo 'sid='\$sid
$SET_ENV
export ORACLE_SID=\$sid
sqlplus -s '/ as sysdba' <<'END'
set pagesize 0 feedback off verify off heading off echo off timing off
select trunc((select count(1) from v\$datafile)/value*100) from v\$parameter where NAME='db_files';
END
" | $SSHCMD $HOST "/bin/bash -s $DB" | tr -d '[[:cntrl:]]' | sed -e 's/^[ \t]*//')

    echo "VALUE: "$VALUE

    if [[ "$VALUE" -gt "$DB_FILES_USAGE_LIMIT" ]]; then
      echo "" | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "db_files usage warning: (current: ${VALUE} %, threshold: ${DB_FILES_USAGE_LIMIT} %)"
    fi
  done # DB
done # HOST

