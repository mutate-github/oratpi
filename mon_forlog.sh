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

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
#  $BASEDIR/test_ssh.sh $CLIENT $HOST
#  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
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
select force_logging from v\$database where exists (select 1 from v\$instance where ARCHIVER='STARTED' and OPEN_MODE='READ WRITE');
END
" | $SSHCMD $HOST "/bin/bash -s $DB" | tr -d '[[:cntrl:]]' | sed -e 's/^[ \t]*//')

    echo "VALUE: "$VALUE

    if [[ "$VALUE" = "NO" ]]; then
      echo "" | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "Warning: Force logging is not enabled"
    fi
  done # DB
done # HOST

