#!/bin/bash
set -f
# usage: startall_purge_traces.sh client_name

CLIENT="$1"
BASEDIR=`dirname $0`
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
SET_ENV_F="$BASEDIR/set_env"
SET_ENV=$(cat $SET_ENV_F)
SCRIPT_NAME="$BASEDIR/purge_traces.sh"

cat <<EOFF >  $SCRIPT_NAME
#!/bin/bash
set -f
# ps -ef | awk -F_ '/[p]mon/{print \$NF}' | while read i; do ./purge_traces.sh \$i; done
#
# usage purge_traces.sh \$ORACLE_SID
if [ "\$1" = "" ]; then
    echo "Usage: \$0 sid"
    exit
fi

sid=\$1

# 3600  - 2.5 days
# 4320  - 3 days
# 5760  - 4 days
# 10080 - 7 days

age=1440         # min
audit=7          # days
# size_lim=1073741824c    # size limit ~1Gb for lsn.log in bytes -nc
size_lim=536870912c    # size limit ~500Mb for lsn.log in bytes -nc

$SET_ENV


export ORACLE_SID=\$sid

VALUE=\$(sqlplus -s '/as sysdba' <<'EOS'
set lines 250  heading off feedback off pagesize 0 trimspool on timing off
select value from v\$system_parameter where name='diagnostic_dest';
EOS
)

echo "diagnostic_dest: "\$VALUE
cd \$VALUE
adrci exec="show homes"

trc=\$(echo "show homes;"  | adrci | grep 'diag/rdbms/.*/'\$sid'$')
tns3=\$(echo "show homes;"  | adrci | grep 'diag/tnslsnr/.*/')
echo "trc: "\$trc
echo "tns3: "\$tns3

echo "set home for diag/rdbms traces: "\$trc
echo "set home for listener tns3: "\$tns3
echo "age: "\$age

for trc_ in \$(echo \$trc | xargs); do
  echo "purge diag/rdbms/ ALERT TRACE INCIDENT CDUMP: "\$trc_
  adrci exec="set home \$trc_ ; migrate schema"
  adrci exec="set home \$trc_ ; purge -age \$age -type ALERT"
  adrci exec="set home \$trc_ ; purge -age \$age -type TRACE"
  adrci exec="set home \$trc_ ; purge -age \$age -type INCIDENT"
  adrci exec="set home \$trc_ ; purge -age \$age -type CDUMP"
done

for tns3_ in \$(echo \$tns3 | xargs); do
  echo "purge listener ALERT TRACE: "\$tns3_
  adrci exec="set home \$tns3_ ; migrate schema"
  adrci exec="set home \$tns3_ ; purge -age \$age -type ALERT"
  adrci exec="set home \$tns3_ ; purge -age \$age -type TRACE"
  find \$VALUE/\$tns3_/trace -type f -name "*lsn*.log" -size +\$size_lim
  find \$VALUE/\$tns3_/trace -type f -name "*lsn*.log" -size +\$size_lim -exec cp /dev/null {} \;
done

echo "BEGIN purge non-standard listener:"
echo find "\$ORACLE_BASE/diag/tnslsnr/\$(hostname)/ -type f -name '*.'"
find \$ORACLE_BASE/diag/tnslsnr/\$(hostname)/ -type f -name "*.log" -size +\$size_lim  -exec cp /dev/null {} \;
find \$ORACLE_BASE/diag/tnslsnr/\$(hostname)/ -type f -name "*.*" -mtime +\$audit  -exec rm {} \; 
echo "END purge non-standard listener"

echo "BEGIN find old and huge rfs trace files \$(hostname) \$sid :"
find \$VALUE/diag/rdbms -type f -name "*rfs*.tr[cm]" -mtime +\$audit -exec rm -f {} \;
find \$VALUE/diag/rdbms -type f -name "*rfs*.tr[cm]" -size +\$size_lim  -exec cp /dev/null {} \;

VALUE=\$(sqlplus -S '/ as sysdba' <<'END'
  set pagesize 0 feedback off verify off heading off echo off timing off
  col value for a200
  select value from v\$parameter where name='audit_file_dest';
END
)

echo "purge audit logs for \$VALUE :"
case \$(uname | awk -F_ '{print \$1}') in
  Linux)   find \$VALUE  -type f -mtime +\$audit -name "*.aud" | xargs -i -P20 rm {} ;;
  *)       find \$VALUE  -type f -mtime +\$audit -name "*.aud" -exec rm {} \; ;;
esac
EOFF

chmod u+x $SCRIPT_NAME

for HOST in $(echo "$HOSTS" | xargs -n1 echo); do
  DBS=$($BASEDIR/iniget.sh $CONFIG $HOST db)
  for DB in  $(echo "$DBS" | xargs -n1 echo); do
    echo "========================================================================================================================="
    echo "HOST=$HOST  DB=$DB  "$(date)
    cat $SCRIPT_NAME | $SSHCMD $HOST "/bin/bash -s $DB"
  done # DB
done # HOST

# rm $SCRIPT_NAME

