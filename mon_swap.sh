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
limPER=$($BASEDIR/iniget.sh $CONFIG threshold swap)
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)

echo "limPER: "$limPER

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST: "$HOST
  SSHUSER=$($BASEDIR/iniget.sh $CONFIG $HOST sshuser)
  SUDO=$($BASEDIR/iniget.sh $CONFIG $HOST sudo)
  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi

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

  LOGF=$LOGDIR/mon_swap_${HOST}.log
  LOGF_HEAD=$LOGDIR/mon_swap_${HOST}_head.log
  OS=$($SSHCMD $HOST "uname")
  case "$OS" in
   Linux) $SSHCMD $SSHUSER $HOST "$SUDO bash <<-'EOF'
	  free | grep 'Swap' | awk '{t = \$2+1; u = \$3; printf (\"%3.0f\", u/(t/100))}'
	EOF
        " > $LOGF
          PCT=$(head -1 $LOGF)
          ;;
   AIX)   $SSHCMD $SSHUSER $HOST "$SUDO bash <<-'EOF'
	  lsps -s | tail +2  | cut -d% -f1 | awk '{printf \$2}'
	EOF
        " > $LOGF
          PCT=$(head -1 $LOGF)
          ;;
   SunOS) # virtual limit  $SSHCMD $SSHUSER $HOST "$SUDO used=\$(/usr/sbin/swap -s | awk '{print \$9}' | tr -d 'k'); avail=\$(/usr/sbin/swap -s | awk '{print \$11}' | tr -d 'k'); total=\$((used + avail)); percent=\$(( used * 100 / total )); echo -n \$percent" > $LOGF
          $SSHCMD $SSHUSER $HOST "$SUDO bash <<-'EOF'
	  /usr/sbin/swap -l | awk 'NR > 1 { total += \$4; free += \$5 } END { if (total>0) { percent = (total-free) * 100 / total ; printf \"%.0f\", percent } }'
	EOF
        " > $LOGF
          PCT=$(head -1 $LOGF)
          ;;
  esac
  echo "PCT: "$PCT
  if [ -s $LOGF ]; then
    if [ "$PCT" -ge "$limPER" ]; then
      echo -e "Fired: "$0"\n" > $LOGF_HEAD
      cat $LOGF_HEAD $LOGF | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST NULL "Swap % usage warning: (current: ${PCT} %, threshold: ${limPER} %)"
      rm $LOGF_HEAD
    fi
    rm $LOGF
  fi
done


