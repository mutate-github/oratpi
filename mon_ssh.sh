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
[[ -z "$HOST" ]] && HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host) || HOSTS="$HOST"
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST

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

  TRG_FILE="$LOGDIR/${SCRIPT_NAME}_${HOST}.trg"
  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then
    MSG="SSH is NOT responding"
    if [ ! -f $TRG_FILE ]; then
      echo "created at: $(date +%H:%M:%S-%d/%m/%y)  by  ${SCRIPT_NAME}" > $TRG_FILE
      echo "$TRG_FILE is not exists. created. For host: $HOST $MSG"
      echo "" | $BASEDIR/send_msg.sh $CONFIG $0 $HOST NULL "TRIGGER: $MSG"
    else
      echo "$TRG_FILE is exists."
      HH=$(date +%H)
      REPEAT_AT=$($BASEDIR/iniget.sh $CONFIG mail repeat_at)
      REPEAT_AT="+($REPEAT_AT)"
      shopt -s extglob         # enables pattern lists like +(...|...)
      case "$HH" in
        ${REPEAT_AT})
           REPEAT_MINUTES=$($BASEDIR/iniget.sh $CONFIG mail repeat_minutes)
           FF=$(find "$TRG_FILE" -mmin +$REPEAT_MINUTES 2>/dev/null | wc -l)
           if [ "$FF" -eq 1 ]; then
               echo $MSG | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST NULL "TRIGGER REPEAT: $(date +%H:%M:%S-%d/%m/%y) $MSG REPEAT_MINUTES=${REPEAT_MINUTES} REPEAT_AT=${REPEAT_AT}"
               echo "TRIGGER REPEAT: $(date +%H:%M:%S-%d/%m/%y) $MSG REPEAT_MINUTES=${REPEAT_MINUTES} REPEAT_AT=${REPEAT_AT}   host: "${HOST}
	       touch $TRG_FILE
           fi
        ;;
      esac
    fi
    echo "test_ssh.sh not return 0, continue"
    continue
  else 
    if [ -f $TRG_FILE ]; then
      rm $TRG_FILE
      MSG="SSH responds"
      echo "recover at: $(date +%H:%M:%S-%d/%m/%y)" | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST NULL "RECOVER: $MSG"
    fi
  fi
done

