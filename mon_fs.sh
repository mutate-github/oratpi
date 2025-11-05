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
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST: "$HOST
#-- skip for host
  skip_outer_loop=0
  for EXCL in $(xargs -n1 echo <<< $SCRIPTS_EXCLUDE); do
     SCRIPTS=$(cut -d':' -f3- <<< $EXCL)
     if [[ $(awk -F: '{print $1}' <<< $EXCL) = "$HOST" ]] && (grep -q "$SCRIPT_NAME" <<< "$SCRIPTS"); then
       echo "Find EXCLUDE HOST: $HOST   in   EXCL: $EXCL"
       echo "Find EXCLUDE SCRIPT: $SCRIPT_NAME   in   SCRIPTS: $SCRIPTS" ; skip_outer_loop=1; break
     fi
  done
  if [ "$skip_outer_loop" -eq 1 ]; then echo "SKIP and continue outher loop!"; continue; fi
#-- end skip for host

  LOGF=$LOGDIR/mon_fs_${HOST}.log
  LOGF_FS_DIFF=$LOGDIR/mon_fs_${HOST}_diff.log
  LOGF_FS_OLD=$LOGDIR/mon_fs_${HOST}_old.log
  touch $LOGF_FS_OLD

  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  OS=$($SSHCMD $HOST "uname")
  case "$OS" in
    Linux) $SSHCMD "$HOST" "df -kP -x squashfs -x tmpfs | awk '{print \$1\" \"\$6}'" > $LOGF
        ;;
    AIX)   $SSHCMD "$HOST" "df -k | awk '{print \$1\" \"\$7}'" > $LOGF
        ;;
    SunOS) $SSHCMD "$HOST" "df -k | awk '{print \$1\" \"\$6}'" > $LOGF
        ;;
  esac
  if [ -s $LOGF ]; then
    diff $LOGF_FS_OLD $LOGF > $LOGF_FS_DIFF

    if [ -s $LOGF_FS_DIFF ]; then
       cat $LOGF_FS_DIFF | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST NULL "FS mountpoint has been changed:"
    fi
    cp $LOGF $LOGF_FS_OLD
    rm $LOGF_FS_DIFF $LOGF
  fi
done

