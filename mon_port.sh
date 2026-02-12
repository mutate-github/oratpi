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
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
  SSHUSER=$($BASEDIR/iniget.sh $CONFIG $HOST sshuser)
  SUDO=$($BASEDIR/iniget.sh $CONFIG $HOST sudo)
  
#  $BASEDIR/test_ssh.sh $CLIENT $HOST
#  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  PORTS=$($BASEDIR/iniget.sh $CONFIG $HOST port)
  for PORT in $(xargs -n1 echo <<< "$PORTS"); do
    echo "PORT="$PORT

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

    LOGF=$LOGDIR/mon_port_${HOST}_${PORT}.log

    printf "$PORT " > $LOGF
    $SSHCMD $SSHUSER $HOST "$SUDO bash" <<-EOF >> $LOGF
       perl -e 'use IO::Socket; \$SIG{ALRM}=sub{die}; alarm 3; \$s=IO::Socket::INET->new(PeerAddr=>"'$PORT'")?1:0; alarm 0; exit(\$s?0:1)' && echo OPEN || echo CLOSED
EOF

    LOGF_PORT_DIFF=$LOGDIR/mon_port_${HOST}_${PORT}_diff.log
    LOGF_PORT_OLD=$LOGDIR/mon_port_${HOST}_${PORT}_old.log
    touch $LOGF_PORT_OLD
    diff $LOGF_PORT_OLD $LOGF > $LOGF_PORT_DIFF

    if [ -s $LOGF_PORT_DIFF ]; then 
	cat $LOGF
        cat $LOGF_PORT_DIFF | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST $PORT "PORT status has been changed:"
    fi
    cp $LOGF $LOGF_PORT_OLD
    rm $LOGF_PORT_DIFF $LOGF
  done
done


