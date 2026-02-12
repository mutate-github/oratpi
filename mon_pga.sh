#!/bin/bash

CLIENT="$1"
HOST="$2"
FILEPATH=$0
BASEDIR=${FILEPATH%/*}
SCRIPT_NAME=${FILEPATH##*/}
LOCKFILE="/tmp/${SCRIPT_NAME}_${CLIENT}.pid"
trap 'rm -f $LOCKFILE' EXIT TERM INT
echo "Starting $0 at: "$(date +%d/%m/%y-%H:%M:%S)
if ! $BASEDIR/checkalrun.sh $LOCKFILE $$; then exit 1; fi

CONFIG="mon.ini"
if [ -n "$CLIENT" ]; then
  shift
  CONFIG=${CONFIG}.${CLIENT}
  if [ ! -s "$BASEDIR/$CONFIG" ]; then echo "Exiting... Config not found: "$CONFIG ; exit 128; fi
fi
echo "Using config: ${CONFIG}"

LOGDIR="$BASEDIR/../log"
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi
WRTPI="$BASEDIR/rtpi"
[[ -z "$HOST" ]] && HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host) || HOSTS="$HOST"
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
SET_ENV_F="$BASEDIR/set_env"
SET_ENV=$(<$SET_ENV_F)
PGA_USAGE_LIMIT=$($BASEDIR/iniget.sh $CONFIG threshold PGA_USAGE_LIMIT)
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)
echo "PGA_USAGE_LIMIT: "$PGA_USAGE_LIMIT

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
  SSHUSER=$($BASEDIR/iniget.sh $CONFIG $HOST sshuser)
  SUDO=$($BASEDIR/iniget.sh $CONFIG $HOST sudo)

  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  DBS=$($BASEDIR/iniget.sh $CONFIG $HOST db)
  for DB in $(xargs -n1 echo <<< "$DBS"); do
    echo "DB="$DB
#--- skip for host:db:script1:script2
    skip_outer_loop_db=0
    for EXCL in $(xargs -n1 echo <<< $SCRIPTS_EXCLUDE); do
       HOST_=$(awk -F: '{print $1}' <<< $EXCL)
       DB_=$(awk -F: '{print $2}' <<< $EXCL)
       SCRIPTS_=$(cut -d':' -f3- <<< $EXCL)
       if [[ "$HOST_" = "$HOST" || "$HOST_" = % ]] && [[ "$DB_" = "$DB" || "$DB_" = % ]]  && [[ "$SCRIPTS_" == *"$SCRIPT_NAME"* || "$SCRIPTS_" == *%* ]]; then
         echo "Find EXCLUDE HOST:   $HOST in   EXCL: $EXCL"
         echo "Find EXCLUDE DB:     $DB   in   EXCL: $EXCL"
         echo "Find EXCLUDE SCRIPT: $SCRIPT_NAME   in   SCRIPTS_: $SCRIPTS_" ; skip_outer_loop_db=1; break
       fi
    done
    if [ "$skip_outer_loop_db" -eq 1 ]; then echo "SKIP and continue outher loop db!"; continue; fi
#--- end skip for db

#    PGA_USAGE=$($WRTPI $HOST $DB pga usage |  awk '/PGA_USAGE/{f=1;getline;getline}f' | head -1)

PGA_USAGE=$(echo -e "#!/bin/bash
sid=\$1
# echo 'sid='\$sid
$SET_ENV
export ORACLE_SID=\$sid
INTVAL=\$(sqlplus -s '/ as sysdba' <<'END'
whenever sqlerror exit 1;
set pagesize 0 feedback off verify off heading off echo off timing off
col pga_usage for 999
SELECT
    CASE
        WHEN p.value = '0' OR p.value IS NULL THEN
            (SELECT (i.value / t.value) * 100
             FROM v\$pgastat i, v\$pgastat t
             WHERE i.name = 'total PGA inuse'
               AND t.name = 'aggregate PGA target parameter')
        ELSE 0
    END as pga_usage
FROM v\$database d
LEFT JOIN v\$parameter p ON p.name = 'memory_target'
WHERE d.database_role = 'PRIMARY';
END
) || INTVAL=0
echo \$INTVAL
" | $SSHCMD $SSHUSER $HOST "$SUDO /bin/bash -s $DB" | tr -d '[[:cntrl:]]' | sed -e 's/^[ \t]*//')

    echo "PGA_USAGE: "$PGA_USAGE

    if [[ "$PGA_USAGE" -gt "$PGA_USAGE_LIMIT" ]]; then
      echo "" | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST $DB "PGA usage warning: (current: ${PGA_USAGE} %, threshold: ${PGA_USAGE_LIMIT} %)"
    fi
  done # DB
done # HOST


