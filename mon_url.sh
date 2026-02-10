#!/bin/bash
set -f

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
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)
TIMEOUT=10

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
  
#  $BASEDIR/test_ssh.sh $CLIENT $HOST
#  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  URLS=$($BASEDIR/iniget.sh $CONFIG $HOST url)
  for URL in $(xargs -n1 echo <<< "$URLS"); do
    echo "URL="$URL

#-- skip for host
  skip_outer_loop=0
  for EXCL in $(xargs -n1 echo <<< $SCRIPTS_EXCLUDE); do
     HOST_=$(awk -F: '{print $1}' <<< $EXCL)
     SCRIPTS_=$(cut -d':' -f3- <<< $EXCL)
     if [[ "$HOST_" = "$HOST" || "$HOST_" = %  ]] && [[ "$SCRIPTS_" == *"$SCRIPT_NAME"* || "$SCRIPTS_" == *%* ]]; then
       echo "Find EXCLUDE HOST: $HOST   in   EXCL: $EXCL"
       echo "Find EXCLUDE SCRIPT: $SCRIPT_NAME   in   SCRIPTS_: $SCRIPTS_" ; skip_outer_loop=1; break
     fi
  done
  if [ "$skip_outer_loop" -eq 1 ]; then echo "SKIP and continue outher loop!"; continue; fi
#-- end skip for host

    LOGF=$LOGDIR/mon_url_${HOST}.log
#    $WRTPI $HOST $URL db | sed -n '/V$INSTANCE:/{p;n;p;n;n;p;}' > $LOGF

    if ! command -v curl &> /dev/null
      then
        HTTP_CODE=$(wget -qS -O /dev/null --timeout=$TIMEOUT --no-check-certificate "$URL" 2>&1 | grep "HTTP/" | tail -1 | awk '{print $2}')
      else
        HTTP_CODE=$(curl -skf --max-time $TIMEOUT -o /dev/null -w "%{http_code}" "$URL")
    fi


    if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ || "$HTTP_CODE" == "302" ]]; then
        echo "YES: ALIVE! (HTTP: $HTTP_CODE)" > $LOGF
    elif [[ "$HTTP_CODE" == "000" ]]; then
        echo "NO: DEAD! Timeout or NOT Answer. HTTP: $HTTP_CODE" > $LOGF
    else
        echo "UNKNOWN: returned HTTP: $HTTP_CODE" > $LOGF
    fi

    LOGF_URL_DIFF=$LOGDIR/mon_url_${HOST}_url_diff.log
    LOGF_URL_OLD=$LOGDIR/mon_url_${HOST}_url_old.log
    touch $LOGF_URL_OLD
    diff $LOGF_URL_OLD $LOGF > $LOGF_URL_DIFF

    if [ -s $LOGF_URL_DIFF ]; then 
        cat $LOGF_URL_DIFF | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST $URL "URL status has been changed:"
    fi
    cp $LOGF $LOGF_URL_OLD
    rm $LOGF_URL_DIFF $LOGF
  done
done

