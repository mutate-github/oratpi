#!/bin/bash

if [ -f ~/.keychain/${HOSTNAME}-sh ]; then source ~/.keychain/${HOSTNAME}-sh ; fi

CLIENT="$1"
BASEDIR=`dirname $0`
echo $BASEDIR
# cd $BASEDIR
mkdir -p $BASEDIR/../log
CONFIG="mon.ini"
if [ -n "$CLIENT" ]; then
  shift
  CONFIG=${CONFIG}.${CLIENT}
  if [ ! -s "$BASEDIR/$CONFIG" ]; then echo "Exiting... Config not found: "$CONFIG ; exit 128; fi
fi
echo "Using config: ${CONFIG}"

echo "Checking if previous script did finish... "$(date)
echo $0
etime=`ps -eo 'pid,etime,args' | egrep "$0 $CLIENT" | awk '!/grep|00:0[0123]/{print $2}'`
if [[ -n "$etime" ]] && [[ ! "$etime" =~ "00:0[0123]" ]]; then
   echo "Previous script did not finish. "$(date)
   ps -eo 'pid,ppid,lstart,etime,args' | egrep "$0 $CLIENT" | awk '!/grep|00:0[0123]/'
   echo "Cancelling running now, send alert message and exiting ..."
   ps -fu oracle | $BASEDIR/send_msg.sh $CONFIG "Script: " $0 " did not finish, do check for hung previous"
   exit 127
fi

echo ""
echo "START ALL MONITORING *****************************************************************************"$(date)
echo "Monitor: ================================================================================ mon_ping.sh "$(date)
$BASEDIR/mon_ping.sh $CLIENT >> $BASEDIR/../log/mon_ping.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_ssh.sh "$(date)
$BASEDIR/mon_ssh.sh $CLIENT >> $BASEDIR/../log/mon_ssh.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_db.sh "$(date)
$BASEDIR/mon_db.sh $CLIENT >> $BASEDIR/../log/mon_db.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_tnslsnr.sh "$(date)
$BASEDIR/mon_tnslsnr.sh $CLIENT >> $BASEDIR/../log/mon_tnslsnr.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_url.sh "$(date)
$BASEDIR/mon_url.sh $CLIENT >> $BASEDIR/../log/mon_url.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_port.sh "$(date)
$BASEDIR/mon_port.sh $CLIENT >> $BASEDIR/../log/mon_port.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_fs.sh "$(date)
$BASEDIR/mon_fs.sh $CLIENT >> $BASEDIR/../log/mon_fs.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_disksp.sh "$(date)
$BASEDIR/mon_disksp.sh $CLIENT >> $BASEDIR/../log/mon_disksp.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_swap.sh "$(date)
$BASEDIR/mon_swap.sh $CLIENT >> $BASEDIR/../log/mon_swap.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_load.sh "$(date)
$BASEDIR/mon_load.sh $CLIENT >> $BASEDIR/../log/mon_load.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_alert.sh "$(date)
$BASEDIR/mon_alert.sh $CLIENT >> $BASEDIR/../log/mon_alert.sh.log 2>&1 &
sleep 1
#$BASEDIR/mon_adrcial.sh $CLIENT
echo "Monitor: ================================================================================ mon_fra.sh "$(date)
$BASEDIR/mon_fra.sh $CLIENT >> $BASEDIR/../log/mon_fra.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_tbs.sh "$(date)
echo "Monitor: ================================================================================ mon_fs.sh "$(date)
$BASEDIR/mon_fs.sh $CLIENT >> $BASEDIR/../log/mon_fs.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_disksp.sh "$(date)
$BASEDIR/mon_disksp.sh $CLIENT >> $BASEDIR/../log/mon_disksp.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_swap.sh "$(date)
$BASEDIR/mon_swap.sh $CLIENT >> $BASEDIR/../log/mon_swap.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_load.sh "$(date)
$BASEDIR/mon_load.sh $CLIENT >> $BASEDIR/../log/mon_load.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_alert.sh "$(date)
$BASEDIR/mon_alert.sh $CLIENT >> $BASEDIR/../log/mon_alert.sh.log 2>&1 &
sleep 1
#$BASEDIR/mon_adrcial.sh $CLIENT
echo "Monitor: ================================================================================ mon_fra.sh "$(date)
$BASEDIR/mon_fra.sh $CLIENT >> $BASEDIR/../log/mon_fra.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_tbs.sh "$(date)
$BASEDIR/mon_tbs.sh $CLIENT >> $BASEDIR/../log/mon_tbs.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_stb.sh "$(date)
$BASEDIR/mon_stb.sh $CLIENT >> $BASEDIR/../log/mon_stb.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_bck.sh "$(date)
$BASEDIR/mon_bck.sh $CLIENT >> $BASEDIR/../log/mon_bck.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_db_files.sh "$(date)
$BASEDIR/mon_db_files.sh $CLIENT >> $BASEDIR/../log/mon_db_files.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_reslim.sh "$(date)
$BASEDIR/mon_reslim.sh $CLIENT >> $BASEDIR/../log/mon_reslim.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_resumab.sh "$(date)
$BASEDIR/mon_resumab.sh $CLIENT >> $BASEDIR/../log/mon_resumab.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_pga.sh "$(date)
$BASEDIR/mon_pga.sh $CLIENT >> $BASEDIR/../log/mon_pga.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_lock.sh "$(date)
$BASEDIR/mon_lock.sh $CLIENT >> $BASEDIR/../log/mon_lock.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_forlog.sh "$(date)
$BASEDIR/mon_forlog.sh $CLIENT >> $BASEDIR/../log/mon_forlog.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_aas.sh "$(date)
$BASEDIR/mon_aas.sh $CLIENT >> $BASEDIR/../log/mon_aas.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ mon_oratop.sh "$(date)
$BASEDIR/mon_oratop.sh $CLIENT >> $BASEDIR/../log/mon_oratop.sh.log 2>&1 &
sleep 1
echo "Monitor: ================================================================================ kill_sniped.sh "$(date)
$BASEDIR/kill_sniped.sh $CLIENT >> $BASEDIR/../log/mon_kill_sniped.sh.log 2>&1 &
wait
echo "FINISH ALL MONITORING ****************************************************************************"$(date)

