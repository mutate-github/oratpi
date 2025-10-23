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
echo "Starting $0 at: "$(date +%d/%m/%y-%H:%M:%S)
echo "Using config: ${CONFIG}"

LOGDIR="$BASEDIR/../log"
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi
SCRIPT_NAME=$(basename $0)
HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
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
               echo $MSG | $BASEDIR/send_msg.sh $CONFIG $0 $HOST NULL "TRIGGER REPEAT: $(date +%H:%M:%S-%d/%m/%y) $MSG REPEAT_MINUTES=${REPEAT_MINUTES} REPEAT_AT=${REPEAT_AT}"
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
      echo "recover at: $(date +%H:%M:%S-%d/%m/%y)" | $BASEDIR/send_msg.sh $CONFIG $0 $HOST NULL "RECOVER: $MSG"
    fi
  fi
done

