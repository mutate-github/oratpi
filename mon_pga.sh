#!/bin/bash

CLIENT="$1"
BASEDIR=$(dirname $0)
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
HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host)
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
SET_ENV_F="$BASEDIR/set_env"
SET_ENV=$(<$SET_ENV_F)
PERCENT=90

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "HOST="$HOST
#  $BASEDIR/test_ssh.sh $CLIENT $HOST
#  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  DBS=$($BASEDIR/iniget.sh $CONFIG $HOST db)
  for DB in $(xargs -n1 echo <<< "$DBS"); do
    echo "DB="$DB

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

    if [[ "$VALUE" -gt "$PERCENT" ]]; then
      echo "" | $BASEDIR/send_msg.sh $CONFIG $HOST $DB "PGA usage warning: (current: ${VALUE} %, threshold: ${PERCENT} %)"
    fi
  done # DB
done # HOST

