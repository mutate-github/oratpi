#!/bin/bash

# Usage: cat audit_login.sh | ssh server "/bin/bash -s SID"
# Usage: cat audit_login.sh | ssh server "/bin/bash -s SID username/password@tns_string"

sid="$1"

shopt -s nocasematch
case "$sid" in
cft*|kik*|bd*|prov*)        [ -r ~/db12kik.env ] && source ~/db12kik.env ;;
EPS*|creditc)               [ -r ~/db12.env ] && source ~/db12.env ;;
KIKOPDR)                    [ -r ~/db11.env ] && source ~/db11.env ;;
jet|ja)                     [ -r /etc/profile.ora ] && source /etc/profile.ora ;;
aisutf*|unit*|crm)          [ -r ~/.ora_env ] && source ~/.ora_env ;;
askona*|aixtdb*|sbaskona)   [ -r ~/.profile ] && source ~/.profile ;;
egais*|GOLD506*)            [ -r ~/.bashrc ] && source ~/.bashrc ;;
unc*|UKVDEV)                [ -r ~/${sid}_setenv.sh ] && source ~/${sid}_setenv.sh ;;
# opndb)                    [ -r ~/BRSKDB_setenv.sh ] && source ~/BRSKDB_setenv.sh ; login_str="tal/tal@'(DESCRIPTION=(ADDRESS=(COMMUNITY=TCP.WORLD)(PROTOCOL=TCP)(HOST=172.16.104.36)(PORT=1525))(CONNECT_DATA=(SERVICE_NAME=opndb)))'" ;;
opndb*|obk*)                : ;;
INSIS*|alfa)                : ;;
dbprod|dbprog)              : ;;
hathi|PHXPRODLIKE)          [ -r ~/hathi.env ] && source ~/hathi.env ;;
# ares*)                    sidlow=$(echo "$sid" | awk '{print tolower($1)}'); source ~/.profile; [ -f /adm/env.${sidlow} ] && source /adm/env.${sidlow} ;;
# krios*)                   sidlow=$(echo "$sid" | awk '{print tolower($1)}'); source ~/.profile; [ -f /adm/env.${sidlow} ] && source /adm/env.${sidlow} ;;
# AVN19FLY)                   [ -r /adm/env.avn19fly ] && source /adm/env.avn19fly ;;
*) #        if [ -r ~/.bashrc ]; then . ~/.bashrc ; fi
   #        if [ -r ~/.bash_profile ]; then . ~/.bash_profile ; fi
   #        if [ -r ~/.profile ]; then . ~/.profile ; fi
   case $(uname | awk -F_ '{print $1}') in
      Linux)  [ -r ~/.bash_profile ] && source ~/.bash_profile
              rc=$(find . -maxdepth 1 -name "${sid}_setenv.sh" -print -quit)
              if [ -n "$rc" ]; then . ~/${sid}_setenv.sh ; fi
              ;;
      AIX)    [ -r ~/.profile ] && source ~/.profile
              [ -r ~/.bashrc ] && source ~/.bashrc
              ;;
      SunOS)  [ -r ~/.profile ] && source ~/.profile
              sidlow=$(awk '{print tolower($1)}' <<< $sid)
              [ -f /adm/env.${sidlow} ] && source /adm/env.${sidlow}
              ;;
      *)      ;;
   esac
;;
esac


LST='
ADAMS/wood
ADMIN/jetspeed
ADMIN/welcome
ADMINISTRATOR/admin
ALHRO/xxx
ALHRW/xxx
ANDY/swordfish
ANONYMOUS/invalid
APPLSYS/apps
APPLSYS/fnd
APPLSYSPUB/fndpub
APPLSYSPUB/pub
APPLYSYSPUB/fndpub
APPLYSYSPUB/pub
APPLYSYSPUB/unknown
APPS_MRC/apps
APPUSER/apppassword
ATM/sampleatm
AURORA$JIS$UTILITY$/invalid
AURORA$ORB$UNAUTHENTICATED/invalid
BLAKE/paper
BRUGERNAVN/adgangskode
BRUKERNAVN/password
CALVIN/hobbes
CDEMO82/cdemo83
CDEMO82/unknown
CIS/zwerg
CISINFO/zwerg
CLARK/cloth
CLKANA/unknown
CLKRT/unknown
CQSCHEMAUSER/password
CQUSERDBUSER/password
CTXSYS/change_on_install
CTXSYS/unknown
DATA_SCHEMA/laskjdf098ksdaf09
DBI/mumblefratz
DCM/unknown
DDIC/199220706
DIANE/passwo1
DISCOVERER5/unknown
DPF/dpfpass
DSGATEWAY/unknown
EARLYWATCH/support
EJSADMIN/ejsadmin_password
ESTOREUSER/estore
FOO/bar
FROSTY/snowman
HR/change_on_install
HR/unknown
INTERNAL/oracle
INTERNAL/sys_stnt
IP/dip
IX/change_on_install
JAKE/passwo4
JILL/passwo2
JONES/steel
JWARD/airoplane
LIBRARIAN/shelves
MARK/passwo3
MASCARM/manager
MASTER/password
MDDEMO_CLERK/clerk
MDDEMO_CLERK/mgr
MDDEMO_MGR/mgr
MMO2/mmo3
MMO2/unknown
MODTEST/yes
MTS_USER/mts_password
NNEUL/nneulpass
NOMEUTENTE/password
NOME_UTILIZADOR/senha
NOM_UTILISATEUR/mot_de_passe
NUME_UTILIZATOR/parol
OAIHUB902/unknown
OAS_PUBLIC/unknown
OCM_DB_ADMIN/unknown
ODM_MTR/mtrpw
OE/change_on_install
OE/unknown
OEM_REPOSITORY/unknown
OLAPSVR/instance
OLAPSYS/manager
OMWB_EMULATION/oracle
ORACACHE/unknown
ORADBA/oradbapass
ORANGE/unknown
ORCLADMIN/welcome
ORD_SERVER/ods
OSE$HTTP$ADMIN/invalid
OSSAQ_HOST/unknown
OSSAQ_PUB/unknown
OSSAQ_SUB/unknown
OWF_MGR/unknown
PLSQL/supersecret
PM/change_on_install
PM/unknown
PORTAL/unknown
PORTAL30/portal31
PORTAL_APP/unknown
PORTAL_DEMO/unknown
PORTAL_PUBLIC/unknown
QS/change_on_install
QS/unknown
QS_ADM/change_on_install
QS_ADM/unknown
QS_CB/change_on_install
QS_CB/unknown
QS_CBADM/change_on_install
QS_CBADM/unknown
QS_CS/change_on_install
QS_CS/unknown
QS_ES/change_on_install
QS_ES/unknown
QS_OS/change_on_install
QS_OS/unknown
QS_WS/change_on_install
QS_WS/unknown
REPORTS_USER/oem_temp
REP_MANAGER/demo
REP_OWNER/demo
REP_USER/demo
SAP/06071992
SAP/sapr3
SAPR3/sap
SCOTT/tiger
SCOTT/tigger
SH/change_on_install
SH/unknown
SLIDE/slidepw
SPOT/pots
STRAT_USER/strat_passwd
SYS/0racle
SYS/change_on_install
SYS/manager
SYS/oracle
SYS/syspass
SYSADMIN/unknown
SYSMAN/oem_temp
SYSTEM/0racle
SYSTEM/change_on_install
SYSTEM/manager
SYSTEM/oracle
SYSTEM/systempass
TALBOT/mt6ch5
TEC/tectec
TEST/passwd
THINSAMPLE/thinsamplepw
TRACESVR/trace
UDDISYS/unknown
USER_NAME/password
USUARIO/clave
UTLBSTATU/utlestat
VIF_DEVELOPER/vif_dev_pwd
VPD_ADMIN/akf7d98s2
VRR1/unknown
VRR1/vrr2
WEBSYS/manager
WEBUSER/your_pass
WIRELESS/unknown
WKPROXY/change_on_install
WKPROXY/unknown
WKSYS/change_on_install
WK_PROXY/unknown
WK_SYS/unknown
XDB/change_on_install
'
FNAME="tpi_check_passwd.sh"

set -f

_P1_=$1
sid=$(awk -F/ '{print $1}' <<< "$_P1_")
PDB=$(awk -F/ '{print $2}' <<< "$_P1_")
if [ -n "$PDB" ]; then
  SET_PDB_="alter session set container=$PDB;"
fi


_P2_="$2"
if ( grep -q "@" <<< "$_P2_" >/dev/null 2>&1 ); then
  login_str="$_P2_"
  shift
fi


if [ -n "$login_str" ]; then
  ls1=$(awk -F@ '{print $1}' <<< "$login_str")
  ls2=$(awk -F@ '{print $2}' <<< "$login_str")
  ls1=$(xor 127 $ls1)
  ls1=$(dec2ascii $ls1)
#  ls1lower=$(tr '[:upper:]' '[:lower:]' <<< $ls1)
  ls1lower=$(to_lower "$ls1")
  [[ "$ls1lower" =~ "sys/" ]] && login_str=${ls1}"@"\'${ls2}\'" as sysdba" || login_str=${ls1}"@"\'${ls2}\'
  SP="eval sqlplus -S $login_str"
else
  SP="eval sqlplus -S '/ as sysdba'"
fi


if [ -n "${ls2}" ]; then
  TNS="@\"${ls2}"
else 
  TNS="\""
  COND1="and username <> 'SYS'"
fi
echo "set lines 350 pages 0 echo off termout off feedback off" >> login.sql
echo "$SET_PDB_" >> login.sql
export ORACLE_PATH=$(pwd):$ORACLE_PATH
$SP  <<EOF > /dev/null
set lines 350 pages 0 echo off termout off feedback off echo off timing off
col cmd for a350
spool $FNAME
select q'[echo "select ']'||username||'/'||lower(username)||' - CONNECTED'' from dual;" | sqlplus -S '||username||'/'||lower(username)||'${TNS}'||decode(username,'SYS',' as sysdba')||'"' cmd  from dba_users  where account_status='OPEN' $COND1 order by username;
select q'[echo "select ']'||username||'/'||username||' - CONNECTED'' from dual;" | sqlplus -S '||username||'/'||username||'${TNS}'||decode(username,'SYS',' as sysdba')||'"' cmd  from dba_users  where account_status='OPEN' $COND1 order by username;
spool off
EOF

for U in $LST; do
  username=$(echo $U | awk -F"/" '{print $1}')
  if [ "$username" = "SYS" ]; then
      echo "echo 'select "${U}" cmd dual;' | sqlplus -S ${U}${TNS} as sysdba\"" >> $FNAME
  else
     echo "echo 'select "${U}" cmd dual;' | sqlplus -S ${U}${TNS}\"" >> $FNAME
  fi
done

echo "Wait... Check users for account_status='OPEN' and simple password:"
chmod u+x $FNAME
# env | grep ORA
# LOGF="/tmp/tpilog_$$.txt"
./$FNAME | egrep ' \- CONNECTED'  # > $LOGF
rm $FNAME login.sql 


