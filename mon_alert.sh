#!/bin/bash
set -f
#exec 5> debug_output.txt
#BASH_XTRACEFD="5"
#PS4='$LINENO: '
#set -x

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

export NLS_LANG=AMERICAN_AMERICA.CL8MSWIN1251
# export NLS_LANG=AMERICAN_AMERICA.AL32UTF8

LOGDIR="$BASEDIR/../log"
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi
WRTPI="$BASEDIR/rtpi"
LINES=$($BASEDIR/iniget.sh $CONFIG alert lines)
EXCLUDE=$($BASEDIR/iniget.sh $CONFIG alert exclude)
[[ -z "$HOST" ]] && HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host) || HOSTS="$HOST"
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  DBS=$($BASEDIR/iniget.sh $CONFIG $HOST db)
  for DB in $(xargs -n1 echo <<< "$DBS"); do
    echo "DB="$DB
#--- skip for host:db:script1:script2
    skip_outer_loop_db=0
    for EXCL in $(xargs -n1 echo <<< $SCRIPTS_EXCLUDE); do
       HOST_=$(awk -F: '{print $1}' <<< $EXCL)
       DB_=$(awk -F: '{print $2}' <<< $EXCL)
       SCRIPTS_=$(cut -d':' -f3- <<< $EXCL)
       if [[ "$HOST_" = "$HOST" || "$HOST_" = % ]] && [[ "$DB_" = "$DB" || "$DB_" = % ]]  && [[ "$SCRIPTS_" == *"$SCRIPT_NAME"* || "$SCRIPTS_" == *%* ]]; then
         echo "Find EXCLUDE HOST:   $HOST in   EXCL: $EXCL"
         echo "Find EXCLUDE DB:     $DB   in   EXCL: $EXCL"
         echo "Find EXCLUDE SCRIPT: $SCRIPT_NAME   in   SCRIPTS_: $SCRIPTS_" ; skip_outer_loop_db=1; break
       fi
    done
    if [ "$skip_outer_loop_db" -eq 1 ]; then echo "SKIP and continue outher loop db!"; continue; fi
#--- end skip for db

    LOGF=$LOGDIR/mon_alert_${HOST}_${DB}.log
    LOGF_HEAD=$LOGDIR/mon_alert_${HOST}_${DB}_head.log
    LASTALERTTIME=$LOGDIR/mon_alert_${HOST}_${DB}_lastalerttime.tmp
    EXCLFILE=$LOGDIR/mon_alert_${HOST}_${DB}_exclude.tmp
    echo $EXCLUDE > $EXCLFILE
    $BASEDIR/iniget.sh $CONFIG alert:${HOST}:${DB} exclude >> $EXCLFILE
    AWKFILE=$LOGDIR/mon_alert_${HOST}_${DB}_awkfile.awk

    $WRTPI $HOST $DB alert $LINES > $LOGF
    sed -i '1d' $LOGF
    head -1 $LOGF > $LOGF_HEAD
    sed -i '1d' $LOGF

cat > $AWKFILE <<!EOF
BEGIN {
  # first get excluded error list
  excldata="";
  while (getline < "$EXCLFILE" > 0) { excldata=excldata " " \$0; }
  # print excldata
  # get time of last error
  if (getline < "$LASTALERTTIME" < 1)  
     { olddate = "00000000 00:00:00" }
  else  { olddate=\$0 }
  errct = 0; errfound = 0;
}

{ if ( \$0 ~ /Sun/ || /Mon/ || /Tue/ || /Wed/ || /Thu/ || /Fri/ || /Sat/ )
  { if (dtconv(\$3, \$2, \$5, \$4) <= olddate)
    { next; }  # get next record from file
    # here we are now processing errors
    OLDLINE=\$0; # store date, possibly of error, or else to be discarded
    # SAVE to olddate: current values:  dtconv(\$3, \$2, \$5, \$4);
    olddate = dtconv(\$3, \$2, \$5, \$4);

    while (getline > 0)
      { if (\$0 ~ /Sun/ || /Mon/ || /Tue/ || /Wed/ || /Thu/ || /Fri/ || /Sat/ )
        { if (errfound > 0)
          { printf ("%s<BR>",OLDLINE); }
          OLDLINE = \$0; # no error, clear and start again
          errfound = 0;
          # save the date for next run
          olddate = dtconv(\$3, \$2, \$5, \$4);
          continue;
        }
        OLDLINE = sprintf("%s<BR>%s",OLDLINE,\$0);
        if ( \$0 ~ /ORA-/ || /[Ff]uzzy/ )
          { # extract the error
            errloc=index(\$0,"ORA-")
            if (errloc > 0)
              { oraerr=substr(\$0,errloc);
                if (index(oraerr," ") > 0)
                   { oraloc2=index(oraerr," "); }
                oraerr=substr(oraerr,1,oraloc2);
                if (index(oraerr,":") > 0)
                   { oraloc2=index(oraerr,":"); oraloc2=oraloc2-1; oraerr=substr(oraerr,1,oraloc2); }
                if (index(excldata,oraerr) < 1)
                   { errfound = errfound +1;  }
              }
            else # treat fuzzy as errors
              { errfound = errfound +1; }
          }      
      }
   }
}

END {
      if (errfound > 0)
         { printf ("%s<BR>",OLDLINE); }
      print olddate > "$LASTALERTTIME";
}

function dtconv (dd, mon, yyyy, tim, sortdate) {
  mth=index("JanFebMarAprMayJunJulAugSepOctNovDec",mon);
  if (mth < 1)
    { return "00000000 00:00:00" };
  # now get month number - make to complete multiple of three and divide
  mth=(mth+2)/3;
  sortdate=sprintf("%04d%02d%02d %s",yyyy,mth,dd,tim);
  return sortdate;
}
!EOF

ERRMESS=$(awk -f $AWKFILE $LOGF)
ERRCT=$(echo $ERRMESS | awk 'BEGIN {RS="<BR>"} END {print NR}')
# rm $LASTALERTTIME
if [ "$ERRCT" -gt 1 ]; then
 echo "$ERRCT Errors Found \n"
 echo "$ERRMESS" | awk 'BEGIN {FS="<BR>"}{for (i=1;NF>=i;i++) {print $i}}'
 echo " " >> $LOGF_HEAD
 echo "$ERRMESS" | awk 'BEGIN {FS="<BR>"}{for (i=1;NF>=i;i++) {print $i}}' >> $LOGF_HEAD
 cat $LOGF_HEAD | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST $DB "ALERT_LOG warning:"
fi

#rm $LOGF $LOGF_HEAD $EXCLFILE $AWKFILE
# rm $LASTALERTTIME

  done    # DB
done   # HOST

