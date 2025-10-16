Документация: TPI (Total Performance Insight) for Oracle

Краткое описание:
TPI — это мощная консольная система мониторинга и диагностики баз данных Oracle, объединяющая в себе функции Enterprise Manager, AWR/ASH отчетов, SQL-тюнинга и повседневного администрирования. Легковесный инструмент, написанный на bash/perl/SQL, не требующий запущенного агента и потребляющий минимум ресурсов.
Полезна для небольших компаний с БД Oracle, без дорогого инстумента администрирования. Мониторинг легко справляется с 100-150 instances Oracle DB.
Необходим доступ по ssh (предпочтительно) или TNS. (Также можно комбинировать ssh и TNS доступ в скрипте доступа rtpi)

Ключевые преимущества:
Все-in-One: Замена десяткам разрозненных скриптов.
Консольный интерфейс: Быстрый запуск и интеграция. 
Экспертный уровень: Встроенные лучшие практики для глубокой диагностики проблем.
Низкие накладные расходы: Не требует агента, Web-сервера, Java, Docker (но может и в нем) и развертывания сложных систем.
Простота: Всего одна команда в терминале.

Система состоит из трех частей:
1. Скрипты диагностики БД Oracle. Скрипты: rtpi, tpi. Полная документация doc/doc_tpi.txt
2. Скприты мониторинга БД Oracle. Скрипты: mon_all.sh, mon_*.sh. Полная документация doc/doc_mon.txt
3. Скприты первичного аудита БД Oracle. Скрипт: audit_tpi.sh. Полная документация doc/doc_aud.txt

Эта документация представляет инструмент как законченный продукт, с которым можно сразу начать работать. 
Для коммерческого использования, если нужна поддержка, пишите на email: mutate@mail.ru Talgat Mukhametshin

Немного примеров, для представления:
```
сервер:    prod-db
БД Oracle: mprod
```

Список сессий, с ожиданиями:
```
$ rtpi prod-db mprod a
DB=mprod 16/10/25-14:25:52 ver=15.10.25  [in=INST_ID] [con=[CON_ID]] "" - ACTIVE | a - Allsess | in - INACTIVE | k - KILLED | [access OBJECT] | P.SPID\S.SID\S.PROCESS [bind] [PEEKED_BINDS OUTLINE all ALLSTATS ADVANCED last adaptive PREDICATE partition] | p [param_name] ] - sess param info, p - from V$SES_OPTIMIZER_ENV by [param_name]

SPID        SID SERIAL# INS CON USERNAME             OSUSER            MACHINE           PROGRAM / MODULE / ACTION                                 PGAU CMD    SQL_ID        EVENT                            SW LOGON          LAST S
-------- ------ ------- --- --- -------------------- ----------------- ----------------- ------------------------------------------------------- ------ ------ ------------- --------------------------- ------- ----------- ------- -
3707374     188   41335   1   0 IBS                  mb                WIN-IM1JGQJFHHM   JDBC Thin Client / CFT Platform IDE /                        6 PL/SQL 16y6ymdvh4faq SQL*Net message from client  134741 10/10 08:20  134742 I
399088       77   15335   1   0 IBS                  DELL              WORKGROUP\DESKTOP plsqldev.exe / PL/SQL Developer / SQL Window                 6                      SQL*Net message from client  104421 15/10 07:56  104422 I
464966      254   28607   1   0 IBS                  DELL              WORKGROUP\DESKTOP plsqldev.exe / PL/SQL Developer / Upd_Main_docum_Change      6                      SQL*Net message from client   76945 15/10 16:34   76946 I
398631      430   52503   1   0 IBS                  DELL              WORKGROUP\DESKTOP plsqldev.exe / PL/SQL Developer / Process_Opers.sql         28                      SQL*Net message from client   74964 15/10 07:47   74965 I
481762       67    9414   1   0 IBS                  DELL              WORKGROUP\DESKTOP plsqldev.exe / PL/SQL Developer / SQL Window                 6                      SQL*Net message from client   68783 15/10 18:30   68784 I
600395      368   57262   1   0 AUDM                 oracle            prod-db.nc152.cmp oracle@prod-db.nc152.cmp.nkz.icdc.io (J000) / AUD_MGR /      2 PL/SQL               PL/SQL lock timer                 9 16/10 10:00   15934 A
455619      313   18423   1   0 IBS                  DELL              WORKGROUP\DESKTOP UAdm.exe / Администратор доступа /                           7                      SQL*Net message from client    7531 15/10 15:21    7532 I
339803       72    5120   1   0 IBS                  mb                WIN-IM1JGQJFHHM   JDBC Thin Client / CFT Platform IDE /                        5                      SQL*Net message from client      60 15/10 00:50      60 I
397442      255   44601   1   0 IBS                  DELL              WORKGROUP\DESKTOP plsqldev.exe / PL/SQL Developer / Primary Session            6                      SQL*Net message from client      49 15/10 07:45      49 I
604358      365   33577   1   0 IBS                  DELL              WORKGROUP\DESKTOP plsqldev.exe / PL/SQL Developer / SQL Window                 6                      SQL*Net message from client      29 16/10 09:40      29 I
396970        9   15116   1   0 IBS                  DELL              WORKGROUP\DESKTOP Novo121_97.exe / Автоматизированное рабочее место / 14:     44                      SQL*Net message from client      18 15/10 07:36      18 I
585552      194   27751   1   0 IBS                  DELL              DESKTOP-KV785D7   JDBC Thin Client / CFT Platform IDE /                        5                      SQL*Net message from client       1 16/10 07:10       1 I
480708       14   36051   1   0 IBS                  DELL              WORKGROUP\DESKTOP OraMon.exe / Монитор коммуникационного канала / 18:16:D      5                      SQL*Net message from client       1 15/10 18:16       1 I
640413      178   38616   1   0 SYS                  oracle            prod-db.nc152.cmp sqlplus@prod-db.nc152.cmp.nkz.icdc.io (TNS V1-V3 / tpi       3 SELECT 20gymysxkb0bv SQL*Net message to client         0 16/10 14:25       0 A
```

Детали сессии 876:
```
$ rtpi prod-db mprod 876
DB=mprod 16/10/25-12:10:04 ver=15.10.25  [in=INST_ID] [con=[CON_ID]] "" - ACTIVE | a - Allsess | in - INACTIVE | k - KILLED | [access OBJECT] | P.SPID\S.SID\S.PROCESS [bind] [PEEKED_BINDS OUTLINE all ALLSTATS ADVANCED last adaptive PREDICATE partition] | p [param_name] ] - sess param info, p - from V$SES_OPTIMIZER_ENV by [param_name] process_info
===============================================================================
S.sid / S.serial#                      : 876  5933
P.spid / P.program / Parent SID        : 50135952 / oracle@srvoradb (J002) / 65532
P.pid / S.process / S.audsid           : 779 / 50135952 / 425342190
S.terminal / P.terminal                : UNKNOWN / UNKNOWN
S.username / S.osuser / S.machine      : GAL_ASUP / oracle / srvoradb
S.program / S.module / S.action        : oracle@srvoradb (J002) / DBMS_SCHEDULER / UPD_HOURLY_JOB
Object_name / PLSQL_ENTRY_OBJECT_ID    : GAL_ASUP.UPD_HOURLY / 23360344
S.status / S.servers / S.type          : ACTIVE / DEDICATED / USER
Tran Active (S.taddr)                  : NONE
S.logon_time                           : Thu 12:05:00
S.last_call_et                         : Thu 12:05:00 -        5.1 min
S.lockwait / P.latchwait / P.latchspin : NONE / NONE / NONE
WAITING: db file sequential read, file#=665, block#=880643, blocks=1
V$SESS_IO: BLOCK_GETS=5217  CONSISTENT_GETS=8269370  PHYSICAL_READS=872120  BLOCK_CHANGES=3759
V$PROCESS_MEMORY: Category(AllocMb/UsedMb/MaxMb): SQL(1/1/35)  PL/SQL(0/0/0)  Other(9//9)  Freeable(28/0/)
Explain plan from dbms_xplan.display_cursor:
SQL_ID  7csrgwvctww32, child number 1
-------------------------------------
SELECT (SELECT NAME FROM GAL_VEK.FILIALS WHERE ATL_NREC =
TS.FATL_BRANCH) MYFIL, (SELECT FNAME FROM GAL_VEK.KATPODR WHERE FNREC =
TS.FCPODR) MYPODR, (SELECT FNAME FROM GAL_VEK.KATMOL WHERE FNREC =
TS.FCMOL) MYMOL, (SELECT FNAME FROM GAL_VEK.KATMC WHERE FNREC =
TS.FCMC) MYMC, (SELECT FNAME FROM GAL_VEK.KATPARTY WHERE FNREC =
TS.FCPARTY) MYPARTY, TS.FCMC TSCMC, TS.FATL_BRANCH TSBRANCH, TS.FKOL
TSKOL, TS.FSTAT TSSTAT, TS.FNREC TSNREC, TS.FRES TSRES, NVL(DR2.FKOL,0)
+ NVL(SD.FKOL,0) DRKOL, TM.FNREC TMNREC, TM.FRESERVE TMRES, DECODE
(SIGN(TS.FKOL-NVL(DR2.FKOL,0)-NVL(SD.FKOL,0)),1,1,0) NEWSTAT, SO.FNREC
SONREC, SO.FRES SORES, TS.FCPODR TSCPODR, TS.FATL_BRANCH TSCBRANCH,
TS.FCMOL TSCMOL, TS.FCPARTY TSCPARTY, NVL(SD.FKOL,0) RSDKOL FROM
GAL_VEK.TEKSALDO TS LEFT JOIN (SELECT DR1.FATL_BRANCH,
DR1.FCPODR,DR1.FCMOL, DR1.FCPARTY, DR1.FCMCUSL, SUM(DR1.FKOL) FKOL FROM
(SELECT DR.FATL_BRANCH, DR.FCPODR,DR.FCMOL, DR.FCPARTY, SP.FCMCUSL,
DR.FKOL FROM GAL_VEK.DORES DR JOIN GAL_VEK.SPSTEP SP ON SP.FNREC =
Plan hash value: 849291086
--------------------------------------------------------------------------------------------------------
| Id  | Operation                          | Name      | Rows  | Bytes |TempSpc| Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT                   |           |       |       |       |   709K(100)|          |
|   1 |  TABLE ACCESS BY INDEX ROWID       | FILIALS   |     1 |    31 |       |     1   (0)| 00:00:01 |
|   2 |   INDEX UNIQUE SCAN                | FILIALS2  |     1 |       |       |     0   (0)|          |
|   3 |  TABLE ACCESS BY INDEX ROWID       | KATPODR   |     1 |    67 |       |     2   (0)| 00:00:01 |
|   4 |   INDEX UNIQUE SCAN                | KATPODR0  |     1 |       |       |     1   (0)| 00:00:01 |
|   5 |  TABLE ACCESS BY INDEX ROWID       | KATMOL    |     1 |    58 |       |     2   (0)| 00:00:01 |
|   6 |   INDEX UNIQUE SCAN                | KATMOL0   |     1 |       |       |     1   (0)| 00:00:01 |
|   7 |  TABLE ACCESS BY INDEX ROWID       | KATMC     |     1 |    69 |       |     3   (0)| 00:00:01 |
|   8 |   INDEX UNIQUE SCAN                | KATMC0    |     1 |       |       |     2   (0)| 00:00:01 |
|   9 |  TABLE ACCESS BY INDEX ROWID       | KATPARTY  |     1 |    72 |       |     2   (0)| 00:00:01 |
|  10 |   INDEX UNIQUE SCAN                | KATPARTY0 |     1 |       |       |     1   (0)| 00:00:01 |
|  11 |  FILTER                            |           |       |       |       |            |          |
|  12 |   HASH JOIN RIGHT OUTER            |           |   478K|   208M|       |   709K  (1)| 00:00:35 |
|  13 |    VIEW                            |           |     1 |    98 |       |   235K  (1)| 00:00:12 |
|  14 |     HASH GROUP BY                  |           |     1 |   163 |       |   235K  (1)| 00:00:12 |
|  15 |      NESTED LOOPS                  |           |       |       |       |            |          |
|  16 |       NESTED LOOPS                 |           |     1 |   163 |       |   235K  (1)| 00:00:12 |
|  17 |        INLIST ITERATOR             |           |       |       |       |            |          |
|  18 |         TABLE ACCESS BY INDEX ROWID| SPSOPR    | 10813 |   865K|       |   202K  (1)| 00:00:10 |
|  19 |          INDEX RANGE SCAN          | SPSOPR5   |  1378K|       |       | 13576   (1)| 00:00:01 |
|  20 |        INDEX UNIQUE SCAN           | KATSOPR0  |     1 |       |       |     2   (0)| 00:00:01 |
|  21 |       TABLE ACCESS BY INDEX ROWID  | KATSOPR   |     1 |    81 |       |     3   (0)| 00:00:01 |
|  22 |    HASH JOIN RIGHT OUTER           |           |   480K|   163M|    15M|   474K  (1)| 00:00:24 |
|  23 |     VIEW                           |           |   146K|    13M|       |   445K  (1)| 00:00:22 |
|  24 |      HASH GROUP BY                 |           |   146K|    19M|    21M|   445K  (1)| 00:00:22 |
|  25 |       NESTED LOOPS                 |           |       |       |       |            |          |
|  26 |        NESTED LOOPS                |           |   146K|    19M|       |   441K  (1)| 00:00:22 |
|  27 |         TABLE ACCESS FULL          | DORES     |   146K|    12M|       |  1374   (1)| 00:00:01 |
|  28 |         INDEX UNIQUE SCAN          | SPSTEP0   |     1 |       |       |     2   (0)| 00:00:01 |
|  29 |        TABLE ACCESS BY INDEX ROWID | SPSTEP    |     1 |    51 |       |     3   (0)| 00:00:01 |
|  30 |     HASH JOIN RIGHT OUTER          |           |   480K|   119M|    43M| 21750   (1)| 00:00:02 |
|  31 |      TABLE ACCESS FULL             | SKLOST    |   530K|    37M|       |  3317   (1)| 00:00:01 |
|  32 |      HASH JOIN RIGHT OUTER         |           |   480K|    85M|    39M| 11772   (2)| 00:00:01 |
|  33 |       TABLE ACCESS FULL            | TEKMC     |   601K|    32M|       |  2758   (1)| 00:00:01 |
|  34 |       TABLE ACCESS FULL            | TEKSALDO  |   480K|    59M|       |  3840   (4)| 00:00:01 |
--------------------------------------------------------------------------------------------------------
Previous SQL statement for SQL_ID: 7r3b94hah60p4
DELETE OVERALL_TEMP WHERE OWNER = 'RESERV_RECALC_TEKSALDO_TEKMC'
===============================================================================
```

График нагрузки БД с 96 CPU:
```
$ rtpi prod-db mprod ash cchart
DB=mprod 16/10/25-12:09:20 ver=15.10.25  ash [in=INST_ID] [con=[CON_ID]] [dd/mm/yy-HH:MI-HH:MI(hours) - def1h] [ event | sess [SID SERIAL# [all|nosqlid|tchcnt] | SQL_ID] | where [FIELD CONDITION] | sql [top [event]] [all [event]] [SQL_ID|SQL_TEXT] | plan SQL_ID [fmt display plan] | sqlstat [SQL_ID|par|inv|fch|sor|exe|pio|lio|row|cpu|ela|iow|mem] [executions] | insection [username|service|machine|program,module,action|sql_opname,sql_plan_operation,sql_plan_options|event|wait_class] | temp [sizeMb] | (umc)chart ] - Top SQL, Events, Sessions GV$ACTIVE_SESSION_HISTORY , for: cchart

"Top activity chart from gv$active_session_history in sample_time between to_date('16/10/25 12:09:21','dd/mm/yy hh24:mi:ss') - interval '1' hour and sysdate"

  IN BEGIN_TIME       AAS PCT1 FIRST           PCT2 SECOND                      PCT3 THIRD                       CHART  *** CPU ***, ### IO ###, +++ WAIT +++,  cpu_count: 96
---- -------------- ----- ---- --------------- ---- --------------------------- ---- --------------------------- ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
   1 16/10/25-11:09    18   73 CPU               16 db file sequential read       10 log file sync               *****************####++                                                                                                        96
   1 16/10/25-11:10    29   77 CPU               12 db file sequential read        9 log file sync               *****************************#####++++                                                                                         96
   1 16/10/25-11:11    27   79 CPU               13 db file sequential read        6 log file sync               *****************************#####++                                                                                           96
   1 16/10/25-11:12    23   81 CPU               10 db file sequential read        6 log file sync               ************************####++                                                                                                 96
   1 16/10/25-11:13    26   77 CPU               12 db file sequential read        7 log file sync               **************************#####+++                                                                                             96
   1 16/10/25-11:14    24   75 CPU               14 db file sequential read        7 log file sync               ************************#####+++                                                                                               96
   1 16/10/25-11:15    38   77 CPU               15 db file sequential read        5 log file sync               ***************************************########+++                                                                             96
   1 16/10/25-11:16    38   71 CPU               18 db file sequential read       10 log file sync               ************************************#########+++++                                                                             96
   1 16/10/25-11:17    32   75 CPU               19 db file sequential read        4 log file sync               ********************************#########++                                                                                    96
   1 16/10/25-11:18    32   77 CPU               16 db file sequential read        3 log file sync               *********************************########+                                                                                     96
   1 16/10/25-11:19    33   81 CPU               11 db file sequential read        5 log file sync               ************************************######+++                                                                                  96
   1 16/10/25-11:20    40   82 CPU               11 db file sequential read        6 log file sync               ********************************************######++++                                                                         96
   1 16/10/25-11:21    35   80 CPU               10 db file sequential read        8 log file sync               *************************************#####++++                                                                                 96
   1 16/10/25-11:22    32   79 CPU               13 db file sequential read        6 log file sync               **********************************######+++                                                                                    96
   1 16/10/25-11:23    33   76 CPU               14 db file sequential read        8 log file sync               **********************************######++++                                                                                   96
   1 16/10/25-11:24    35   80 CPU               14 db file sequential read        4 log file sync               *************************************#######++                                                                                 96
   1 16/10/25-11:25    37   84 CPU               10 db file sequential read        4 log file sync               *****************************************#####++                                                                               96
   1 16/10/25-11:26    34   82 CPU               11 db file sequential read        5 log file sync               *************************************######++                                                                                  96
   1 16/10/25-11:27    34   86 CPU                7 db file sequential read        5 log file sync               ***************************************####++                                                                                  96
   1 16/10/25-11:28    32   81 CPU               10 db file sequential read        6 log file sync               ***********************************#####+++                                                                                    96
   1 16/10/25-11:29    29   81 CPU               10 db file sequential read        5 log file sync               ********************************#####++                                                                                        96
   1 16/10/25-11:30    35   81 CPU               13 db file sequential read        2 log file sync               **************************************#######++                                                                                96
   1 16/10/25-11:31    31   73 CPU               18 db file sequential read        4 log file sync               ******************************########+++                                                                                      96
   1 16/10/25-11:32    29   75 CPU               18 db file sequential read        5 log file sync               *****************************########++                                                                                        96
   1 16/10/25-11:33    26   83 CPU               13 db file sequential read        3 log file sync               ****************************#####+                                                                                             96
   1 16/10/25-11:34    24   81 CPU               15 db file sequential read        2 log file sync               **************************#####+                                                                                               96
   1 16/10/25-11:35    27   80 CPU               15 db file sequential read        2 log file sync               *****************************######+                                                                                           96
   1 16/10/25-11:36    25   84 CPU               12 db file sequential read        2 log file sync               ****************************#####+                                                                                             96
   1 16/10/25-11:37    27   82 CPU               13 db file sequential read        4 log file sync               ******************************#####+                                                                                           96
   1 16/10/25-11:38    23   84 CPU               11 db file sequential read        3 log file sync               **************************####+                                                                                                96
   1 16/10/25-11:39    20   86 CPU               10 db file sequential read        2 log file sync               ***********************###+                                                                                                    96
   1 16/10/25-11:40    25   83 CPU               10 db file sequential read        5 log file sync               ***************************####++                                                                                              96
   1 16/10/25-11:41    20   83 CPU               11 db file sequential read        3 log file sync               **********************####+                                                                                                    96
   1 16/10/25-11:42    19   83 CPU               14 db file sequential read        2 log file sync               *********************####+                                                                                                     96
   1 16/10/25-11:43    18   87 CPU               10 db file sequential read        1 log file sync               *********************###                                                                                                       96
   1 16/10/25-11:44    19   82 CPU               12 db file sequential read        3 log file sync               *********************####+                                                                                                     96
   1 16/10/25-11:45    21   87 CPU               10 db file sequential read        2 log file sync               ************************###+                                                                                                   96
   1 16/10/25-11:46    18   88 CPU                9 db file sequential read        3 log file sync               *********************##+                                                                                                       96
   1 16/10/25-11:47    20   88 CPU               10 db file sequential read        1 db file parallel read       ************************###                                                                                                    96
   1 16/10/25-11:48    26   89 CPU                7 db file sequential read        3 log file sync               *******************************###+                                                                                            96
   1 16/10/25-11:49    21   87 CPU               10 db file sequential read        1 log file sync               *************************###+                                                                                                  96
   1 16/10/25-11:50    25   85 CPU               11 db file sequential read        2 log file sync               *****************************####+                                                                                             96
   1 16/10/25-11:51    25   87 CPU               11 db file sequential read        1 log file sync               *****************************####                                                                                              96
   1 16/10/25-11:52    24   85 CPU               13 db file sequential read        1 log file sync               ***************************####                                                                                                96
   1 16/10/25-11:53    22   84 CPU               14 db file sequential read        1 log file sync               *************************####+                                                                                                 96
   1 16/10/25-11:54    21   80 CPU               16 db file sequential read        2 log file sync               **********************#####+                                                                                                   96
   1 16/10/25-11:55    22   79 CPU               16 db file sequential read        3 log file sync               ***********************#####+                                                                                                  96
   1 16/10/25-11:56    21   84 CPU               14 db file sequential read        2 db file parallel read       ************************####                                                                                                   96
   1 16/10/25-11:57    23   81 CPU               17 db file sequential read        2 log file sync               *************************#####+                                                                                                96
   1 16/10/25-11:58    22   82 CPU               16 db file sequential read        1 log file sync               ************************#####                                                                                                  96
   1 16/10/25-11:59    24   82 CPU               15 db file sequential read        1 db file parallel read       **************************#####                                                                                                96
   1 16/10/25-12:00    35   82 CPU               14 db file sequential read        2 log file sync               ***************************************#######+                                                                                96
   1 16/10/25-12:01    28   78 CPU               19 db file sequential read        2 log file sync               *****************************########+                                                                                         96
   1 16/10/25-12:02    23   82 CPU               14 db file sequential read        2 log file sync               *************************#####+                                                                                                96
   1 16/10/25-12:03    24   83 CPU               15 db file sequential read        2 db file parallel read       ***************************#####                                                                                               96
   1 16/10/25-12:04    20   81 CPU               16 db file sequential read        2 log file sync               *********************#####+                                                                                                    96
   1 16/10/25-12:05    19   82 CPU               14 db file sequential read        3 log file sync               ********************####+                                                                                                      96
   1 16/10/25-12:06    16   80 CPU               16 db file sequential read        2 log file sync               *****************####+                                                                                                         96
   1 16/10/25-12:07    18   80 CPU               15 db file sequential read        3 log file sync               *******************####+                                                                                                       96
   1 16/10/25-12:08    18   84 CPU               14 db file sequential read        1 db file parallel read       ********************####                                                                                                       96
   1 16/10/25-12:09     6   83 CPU               16 db file sequential read        1 log file sync               *******#                                                                                                                       96
```

График нагрузки IO datafiles
```
$ rtpi prod-db mprod dhash 01/10/25-09:03-24 iostat | diagram.sh  2 3 4 5 6 7 8 9 10 11 12 13
Legend:
TRE_MBS  - TotalReads           SRE_MBS  - SingleReadsMBS      SMRE_LAT - Small_read_servicetime/Small_read_reqs
TRE_IOPS - TotalReadsIOPS       SRE_IOPS - SingleReadsIOPS     SMWR_LAT - Small_write_servicetime/Small_write_reqs
TWR_MBS  - TotalWrites          SWR_MBS  - SingleWritesMBS     LARE_LAT - Large_read_servicetime/Large_read_reqs
TWR_IOPS - TotoalWritesIOPS     SWR_IOPS - SingleWritesIOPS    LAWR_LAT - Large_write_servicetime/Large_rwrite_reqs
IN       - Instance_number
dba_hist_iostat_filetype param 'Archive Log' 'Control File' 'Data File' 'Log File'  'Other' 'Temp File' for  Data File

BEGIN_TIME      TRE_MBS  LEVELS           TRE_IOPS  LEVELS           TWR_MBS  LEVELS           TWR_IOPS  LEVELS          SRE_MBS  LEVELS           SRE_IOPS  LEVELS           SWR_MBS  LEVELS           SWR_IOPS  LEVELS           SMRE_LAT  LEVELS           SMWR_LAT  LEVELS           LARE_LAT  LEVELS           LAWR_LAT  LEVELS
01/10/25-10:00  78.62    |                8470.56   |=====           10.35    |=======         550.47    |=========      66.54    |=====           8456.66   |=====           5.69     |=======         513.17    |=========       0.08      |                0.49      |                1.16      |                0.19      |
01/10/25-11:00  645.45   |===========     14832.32  |=========       9.41     |=======         618.31    |==========     112.05   |=========       14297.00  |=========       6.17     |========        592.43    |==========      0.07      |                1.55      |                3.92      |                0.37      |
01/10/25-12:00  144.20   |=               10107.79  |======          9.28     |=======         612.93    |==========     78.95    |======          10041.93  |======          6.08     |========        587.34    |==========      0.07      |                0.45      |                3.36      |                0.27      |
01/10/25-13:00  134.21   |=               8670.99   |=====           8.47     |======          514.45    |========       68.83    |=====           8601.41   |=====           5.29     |=======         488.99    |========        0.07      |                0.42      |                2.39      |                0.20      |
01/10/25-14:00  145.79   |=               9155.75   |=====           14.48    |===========     679.60    |===========    71.64    |=====           9078.43   |=====           8.47     |============    631.53    |===========     0.07      |                0.44      |                3.70      |                0.20      |
01/10/25-15:00  668.32   |============    14918.11  |=========       15.50    |============    689.97    |===========    112.77   |=========       14359.80  |=========       8.32     |============    632.51    |===========     1257.47   |                5.42      |=               4.13      |                4.94      |===
01/10/25-16:00  270.17   |====            6940.86   |===             12.35    |=========       603.01    |==========     53.20    |===             6721.71   |===             7.01     |=========       560.26    |==========      0.08      |                0.40      |                3.30      |                0.17      |
01/10/25-17:00  56.21    |                4559.60   |==              9.74     |=======         498.61    |========       35.82    |==              4536.74   |==              5.19     |=======         462.24    |========        1592.08   |                0.42      |                0.53      |                0.16      |
01/10/25-18:00  33.65    |                3377.76   |=               5.98     |====            357.71    |=====          26.53    |=               3370.29   |=               3.53     |====            338.09    |=====           0.07      |                0.39      |                1.28      |                0.15      |
01/10/25-19:00  491.67   |========        8498.96   |=====           3.80     |==              246.81    |===            63.24    |====            8069.20   |====            2.28     |==              234.68    |===             3227.69   |                0.43      |                3.66      |                0.29      |
01/10/25-20:01  39.38    |                3102.58   |=               3.39     |=               224.00    |===            24.36    |=               3086.55   |=               2.10     |==              213.64    |===             5065.78   |=               0.39      |                0.84      |                0.17      |
01/10/25-21:00  242.19   |===             5528.08   |==              11.95    |=========       569.66    |=========      44.21    |===             5322.54   |==              6.69     |=========       527.57    |=========       15760.60  |========        16.09     |======          58303.75  |==============  2.90      |=
01/10/25-22:00  165.97   |==              6154.08   |===             7.82     |=====           412.19    |======         48.42    |===             6033.09   |===             4.56     |======          386.08    |======          20731.27  |===========     0.57      |                9753.61   |=               0.51      |
01/10/25-23:00  566.94   |==========      3229.51   |=               11.84    |=========       709.81    |============   22.42    |=               2680.77   |                8.07     |===========     679.60    |============    1787.19   |                0.74      |                3.30      |                0.53      |
02/10/25-00:00  171.79   |==              13186.47  |========        12.43    |=========       701.34    |============   103.48   |========        13116.21  |========        7.85     |===========     664.73    |============    16959.60  |========        8.15      |==              17116.39  |===             8.18      |=====
02/10/25-01:00  203.86   |===             4875.59   |==              13.92    |===========     802.09    |=============  38.66    |==              4696.18   |==              8.77     |============    760.85    |==============  0.12      |                0.39      |                3.26      |                0.17      |
02/10/25-02:00  413.50   |=======         4200.18   |==              13.22    |==========      684.93    |===========    35.78    |==              3529.41   |=               7.66     |===========     640.49    |===========     1.03      |                7.81      |==              21.87     |                0.94      |
02/10/25-03:00  575.69   |==========      4392.61   |==              10.63    |========        440.17    |=======        30.34    |=               3845.68   |=               5.31     |=======         397.63    |======          0.07      |                0.65      |                3.39      |                0.29      |
02/10/25-04:00  47.54    |                2678.24   |                8.78     |======          356.25    |=====          20.88    |                2651.41   |                4.09     |=====           318.69    |=====           0.06      |                0.33      |                1.23      |                0.14      |
02/10/25-05:00  50.49    |                4178.05   |=               8.83     |======          379.52    |======         32.73    |==              4158.30   |==              4.29     |=====           343.20    |=====           0.05      |                0.32      |                0.35      |                0.13      |
02/10/25-06:00  312.33   |=====           12548.15  |=======         13.80    |==========      555.14    |=========      102.86   |========        12322.56  |========        7.38     |==========      503.83    |========        1265.72   |                0.33      |                3.33      |                0.13      |
02/10/25-07:00  749.78   |==============  20987.33  |==============  13.87    |==========      490.87    |========       160.36   |==============  20394.70  |==============  6.36     |========        430.79    |=======         25603.08  |==============  0.47      |                2030.64   |                4.98      |===
02/10/25-08:00  330.62   |=====           15443.92  |==========      17.37    |==============  779.22    |=============  120.02   |==========      15227.11  |==========      9.57     |==============  716.86    |=============   13405.54  |======          32.29     |==============  6.57      |                18.13     |==============
02/10/25-09:00  282.62   |====            18591.74  |============    6.53     |====            439.35    |=======        147.85   |============    18452.48  |============    4.20     |=====           420.64    |=======         3281.97   |                0.90      |                4.38      |                1.08      |
```
