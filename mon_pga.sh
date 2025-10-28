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
PGA_USAGE_LIMIT=$($BASEDIR/iniget.sh $CONFIG threshold PGA_USAGE_LIMIT)
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)
ME=$(basename $0)
echo "PGA_USAGE_LIMIT: "$PGA_USAGE_LIMIT

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
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
       if [[ "$HOST_" = "$HOST" || "$HOST_" = % ]] && [[ "$DB_" = "$DB" || "$DB_" = % ]]  && [[ "$SCRIPTS_" == *"$ME"* || "$SCRIPTS_" == *%* ]]; then
         echo "Find EXCLUDE HOST:   $HOST in   EXCL: $EXCL"
         echo "Find EXCLUDE DB:     $DB   in   EXCL: $EXCL"
         echo "Find EXCLUDE SCRIPT: $ME   in   SCRIPTS_: $SCRIPTS_" ; skip_outer_loop_db=1; break
       fi
    done
    if [ "$skip_outer_loop_db" -eq 1 ]; then echo "SKIP and continue outher loop db!"; continue; fi
#--- end skip for db

#    VALUE=$($WRTPI $HOST $DB pga usage |  awk '/PGA_USAGE/{f=1;getline;getline}f' | head -1)

VALUE=$(echo -e "#!/bin/bash
sid=\$1
# echo 'sid='\$sid
$SET_ENV
export ORACLE_SID=\$sid
sqlplus -s '/ as sysdba' <<'END'
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
" | $SSHCMD $HOST "/bin/bash -s $DB" | tr -d '[[:cntrl:]]' | sed -e 's/^[ \t]*//')

    echo "VALUE: "$VALUE

    if [[ "$VALUE" -gt "$PGA_USAGE_LIMIT" ]]; then
      echo "" | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "PGA usage warning: (current: ${VALUE} %, threshold: ${PGA_USAGE_LIMIT} %)"
    fi
  done # DB
done # HOST

