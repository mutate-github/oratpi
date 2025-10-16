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

LOGDIR="$BASEDIR/../log"
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi
HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host)
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
limPER=$($BASEDIR/iniget.sh $CONFIG load limitPER)


for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  LOGF=$LOGDIR/mon_swap_${HOST}.log
  LOGF_HEAD=$LOGDIR/mon_swap_${HOST}_head.log
  echo "HOST: "$HOST
#  $BASEDIR/test_ssh.sh $CLIENT $HOST
#  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  OS=$($SSHCMD $HOST "uname")
  case "$OS" in
   Linux)
          $SSHCMD "$HOST" "cat /proc/loadavg | awk '{printf (\"%3.0f\", \$2)}'" > $LOGF
          PCT=$(head -1 $LOGF)
          ;;
   AIX)   $SSHCMD "$HOST" "lparstat 6 1 | tail -1 | awk '{printf (\"%3.0f\", \$7)}'" > $LOGF
          PCT=$(head -1 $LOGF)
          ;;
   SunOS) $SSHCMD "$HOST" "uptime | awk '{printf (\"%3.0f\", \$(NF-1))}'" > $LOGF
          PCT=$(head -1 $LOGF)
          ;;
  esac
  if [ -s $LOGF ]; then
    if [[ "$PCT" -ge "$limPER" ]]; then
      echo -e "Fired: "$0"\n" > $LOGF_HEAD
      cat $LOGF_HEAD $LOGF | $BASEDIR/send_msg.sh $CONFIG $HOST NULL "Overall OS Load warning: (current: ${PCT} %, threshold: ${limPER} %)"
      rm $LOGF_HEAD
    fi
    rm $LOGF
  fi
done


