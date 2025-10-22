Документация: TPI (Total Performance Insight) for Oracle

Краткое описание:
TPI — это мощная консольная система мониторинга и диагностики баз данных Oracle, объединяющая в себе функции Enterprise Manager, AWR/ASH отчетов, SQL-тюнинга и повседневного администрирования. Легковесный инструмент, написанный на bash/perl/SQL, не требующий запущенного агента и потребляющий минимум ресурсов.
Полезна для небольших компаний с БД Oracle, без дорогого инстумента администрирования. Мониторинг легко справляется с 100-150 instances Oracle DB.
Необходим доступ по ssh (предпочтительно) или TNS. (Также можно комбинировать ssh и TNS доступ в скрипте доступа rtpi)

Ключевые преимущества:
- Все-in-One: Замена десяткам разрозненных скриптов.
- Консольный интерфейс: Быстрый запуск и интеграция. 
- Экспертный уровень: Встроенные лучшие практики для глубокой диагностики проблем.
- Низкие накладные расходы: Не требует агента, Web-сервера, Java, Docker (но может и в нем) и развертывания сложных систем.
- Простота: Всего одна команда в терминале.

Система состоит из трех частей:
1. Скрипты диагностики БД Oracle. Скрипты: rtpi, tpi. Полная документация doc/doc_tpi.txt
2. Скрипты мониторинга БД Oracle. Скрипты: mon_all.sh, mon_*.sh. Полная документация doc/doc_mon.txt
3. Скрипты первичного аудита БД Oracle. Скрипт: audit_tpi.sh. Полная документация doc/doc_aud.txt

Эта документация представляет инструмент как законченный продукт, с которым можно сразу начать работать. 
Для коммерческого использования, если нужна поддержка, пишите на email: mutate@mail.ru Talgat Mukhametshin

Малая часть примеров rtpi \ tpi, для общего представления:
```
Допустим имеем:
сервер:    prod-db
БД Oracle: mprod
```

Список всех сессий БД, с ожиданиями:
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

Детали сессии 876, статистика IO, памяти, запрос, план выполнения:
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

График нагрузки БД по CPU \ IO \ WAIT с 96 CPU:
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

Данные из awr за период с графиками для нагладности:
```
$ rtpi prod-db mprod dhash 19/10/25-07:00-48 awrinfo
Legend:
AAS     - Average Active Sessions     REDO_GB - Redo Size Generated per Hour             PHYREMBT - Physical Read Total (MB)        ENQTXMS - Enqueue TX contention (ms)
DBTIMEM - DB Time                     DBBLC   - Block Changed per Hour                   PHYWRMBT - Physical Write Total (MB)       ENQTMMS - Enqueue TM contention (ms)
DBCPUM  - DB CPU                      PGAMB   - PGA Size                                 PHREMBPS - Physical Read Mb per Second     TRANMIN - DB Transactions per min
LOAD    - CPU Load                    READLAT - Read S\B Latency                         PHWRMBPS - Physical Write Mb per Second    ROLLMIN - DB Rollbacks per min
LOADW   - CPU Load Windows            LFPWLAT - Log File parallel write (ms) Latency     PHREIOPS - Physical Read IOPS              IN      - Instance_number
LIOPSEC - Logical Reads per second    LFSYLAT - Log File sync (ms) Latency               PHWRIOPS - Physical Write IOPS
Data from: dba_hist_sys_time_model  dba_hist_osstat dba_hist_system_event dba_hist_sysstat dba_hist_sysmetric_summary

1                      2       3      4      5      6         7       8           9     10       11       12       13       14       15      16      17      18      19        20       21      22      23   24
BEGIN_TIME           AAS DBTIMEM DBCPUM   LOAD  LOADW   LIOPSEC REDO_GB     DBBLC^3  PGAMB  READLAT  LFPWLAT  LFSYLAT PHYREMBT PHYWRMBT PREMBPS PWRMBPS PREIOPS PWRIOPS   ENQTXMS  ENQTMMS TRANMIN ROLLMIN   IN
----------------- ------ ------- ------ ------ ------ --------- ------- ----------- ------ -------- -------- -------- -------- -------- ------- ------- ------- ------- --------- -------- ------- ------- ----
19/10/25-07:00:36      0       0      0     14     67         0       0           0   4900     0.28     0.41     0.92        0        0       0       0   10888    2937         2        0       0       0    1
19/10/25-08:00:58     18    1062    302     14     69   1072660      27      239301   4463     0.26     0.42     0.54  3466049   199811     969      56   22767    1849        27        0    6768       6    1
19/10/25-09:00:35     11     628    271     17     61   1029701       5       33528   5384     0.29     0.44     0.61   835445    80879     234      23   11135     405         4        0    8520      10    1
19/10/25-10:00:04     11     651    297     10     62   1034054       5       35042   5264     0.30     0.44     0.66  2255825    68947     622      19    8148     532         8        0    9732      14    1
19/10/25-11:00:32     10     618    323     15     57   1237662      10       62228   5946     0.33     0.44     1.43   465061    52574     130      15    3157     623      1785        0   42012     422    1
19/10/25-12:00:01     15     922    433     11     81   1404099      14       85135   6761     0.33     0.56     0.98  2067158    70471     568      19    5188    1907         9        0   11977      34    1
19/10/25-13:00:41     12     728    363     21     75   1514330      17      124136   8181     0.35     0.62     1.05   280700    98372      79      28    3153     889      1060        0    9297      19    1
19/10/25-14:00:04     14     870    396     19     83   1410222       9       59136   7376     0.36     0.71     1.28  2368263   742093     653     205    5428    1596        12        0    9059      16    1
19/10/25-15:00:32     12     701    342     16     77   1211437      14      112170   7373     0.38     0.62     1.16   113342    67802      31      19    2784     668       163        0   23169      69    1
19/10/25-16:00:43     15     921    414     20     93   1620159      13       96837   8011     0.37     0.62     1.10  1742424    71079     489      20    7338    1180         5        0   24643      62    1
19/10/25-17:00:09     11     653    311     18     78   1055919      13       89681   7667     0.36     0.64     1.23   193501    80871      53      22    3044    1228       161        0   25157      66    1
19/10/25-18:00:43     14     832    351     23     84   1207199      12       82979   7726     0.34     0.52     0.87  1772237    64185     495      18    6290    1245       100        0   25786      47    1
19/10/25-19:00:21      9     542    269     13     59    974585      13       86140   7207     0.33     0.52     0.81    88260    63217      25      18    2448    1233       242        0   25401      47    1
19/10/25-20:00:01     10     596    286     13     62   1046275       9       53301   5820     0.29     0.54     0.81  1695326    43533     463      12    6080    1147        38        0    8822      12    1
19/10/25-21:01:00      7     402    187     15     47    757180       6       36467   6597     0.30     0.49     0.88   180559    44331      51      12    3615     491         4        0   19274      56    1
19/10/25-22:00:34      9     560    253     13     53    946821      10       69448   4547     0.32     0.51     0.85  2276265    52646     635      15    7242     950         3        0   26281      48    1
19/10/25-23:00:21      7     448    222     11     50    706022      17      125509   3140     0.33     0.57     0.81   818594    78904     225      22    4347    1217         2        0   21906      17    1
20/10/25-00:00:52      5     320    158     11     48    587365       9       67025   3395     0.31     0.53     0.79  1646004    63352     462      18    1772     908         9        0   23625      43    1
20/10/25-01:00:17      9     516    216     11     49    838839      16       98156   4365     0.37     0.56     2.64  1691986    71446     465      20    8083    1174         2        0   93631     557    1
20/10/25-02:00:55     11     654    247     16     59    825485      59      393682   3706     0.35     0.50     1.74  1857516   274614     521      77    3977    4928         1        0  108653      16    1
20/10/25-03:00:20      9     508    206     11     88    922271      62      482251   2650     0.29     0.43     1.20  1542418   991183     431     277    5137    6318         2        0   75033     114    1
20/10/25-04:00:00      9     540    252      8     52   1122106      44      340299   2816     0.29     0.49     0.74  1372333   206917     379      57    3593    3267         2        0   17494      18    1
20/10/25-05:00:26      9     514    204     12     43    706002       7       47668   3581     0.30     0.54     0.79    95363    38194      27      11    2518     792         3        0    8315       8    1
20/10/25-06:00:09      9     555    258     11     52   1013067       7       48237   5124     0.29     0.59     0.80  1309387   116624     361      32    5187     546        19        0    6251       6    1
20/10/25-07:00:35     11     647    274     19     67    825198       8       54832   5851     0.32     0.65     1.05   867699   699469     243     195    9990    1205         6        0    9993      21    1
20/10/25-08:00:13     16     988    352     18     86   1092007      15      124172   6696     0.34     0.60     1.30  2197795   128345     606      35   23324     827       751        0   21746      66    1
20/10/25-09:00:42     23    1372    522     34    116   1605376      16       92551  12386     0.35     0.55     1.29  1010141    82822     279      23   16997    1306       850        0   29415      98    1
20/10/25-10:00:59     30    1769    659     29    150   2494093      20      139411  10653     0.33     0.46     1.05  1747512   148640     491      42   14234    1761       840        0   31651     521    1
20/10/25-11:00:22     22    1307    590     28    116   1904161      18      110460  11000     0.33     0.51     1.81   499203    93601     138      26    6925    1796     10609        0   58424     650    1
20/10/25-12:00:38     30    1799    687     29    151   2008310      27      160873  11750     0.31     0.65     1.54  2262793   192392     635      54   11124    3202      4372        0   29267     409    1
20/10/25-13:00:04     27    1663    635     29    140   2547270      49      332309  14765     0.00     0.00     0.00   844269   298695     232      82   16007    3527         0        0   28216     341    1


$ rtpi prod-db mprod dhash 19/10/25-07:00-48 awrinfo |  diagram.sh 2 7 8 9 10 11 12 13 16 17 20 21 22 23
BEGIN_TIME         AAS  LEVELS           LIOPSEC  LEVELS           REDO_GB  LEVELS           DBBLC^3  LEVELS           PGAMB  LEVELS           READLAT  LEVELS           LFPWLAT  LEVELS           LFSYLAT  LEVELS           PREMBPS  LEVELS           PWRMBPS  LEVELS           ENQTXMS  LEVELS           ENQTMMS  LEVELS  TRANMIN  LEVELS           ROLLMIN  LEVELS
19/10/25-07:00:36  0    |                0        |                0        |                0        |                4900   |===             0.28     |==========      0.41     |=======         0.92     |====            0        |                0        |                2        |                0        |       0        |                0        |
19/10/25-08:00:58  18   |========        1072660  |=====           27       |=====           239301   |======          4463   |===             0.26     |=========       0.42     |=======         0.54     |==              969      |==============  56       |==              27       |                0        |       6768     |                6        |
19/10/25-09:00:35  11   |====            1029701  |=====           5        |                33528    |                5384   |====            0.29     |==========      0.44     |========        0.61     |==              234      |==              23       |                4        |                0        |       8520     |                10       |
19/10/25-10:00:04  11   |====            1034054  |=====           5        |                35042    |                5264   |====            0.30     |==========      0.44     |========        0.66     |==              622      |========        19       |                8        |                0        |       9732     |                14       |
19/10/25-11:00:32  10   |====            1237662  |======          10       |=               62228    |                5946   |=====           0.33     |============    0.44     |========        1.43     |=======         130      |=               15       |                1785     |=               0        |       42012    |====            422      |========
19/10/25-12:00:01  15   |======          1404099  |=======         14       |==              85135    |=               6761   |=====           0.33     |============    0.56     |==========      0.98     |====            568      |=======         19       |                9        |                0        |       11977    |                34       |
19/10/25-13:00:41  12   |=====           1514330  |=======         17       |===             124136   |==              8181   |=======         0.35     |============    0.62     |============    1.05     |====            79       |                28       |                1060     |                0        |       9297     |                19       |
19/10/25-14:00:04  14   |======          1410222  |=======         9        |=               59136    |                7376   |======          0.36     |=============   0.71     |==============  1.28     |======          653      |=========       205      |==========      12       |                0        |       9059     |                16       |
19/10/25-15:00:32  12   |=====           1211437  |======          14       |==              112170   |==              7373   |======          0.38     |==============  0.62     |============    1.16     |=====           31       |                19       |                163      |                0        |       23169    |==              69       |
19/10/25-16:00:43  15   |======          1620159  |========        13       |==              96837    |==              8011   |=======         0.37     |=============   0.62     |============    1.10     |=====           489      |======          20       |                5        |                0        |       24643    |==              62       |
19/10/25-17:00:09  11   |====            1055919  |=====           13       |==              89681    |=               7667   |======          0.36     |=============   0.64     |============    1.23     |=====           53       |                22       |                161      |                0        |       25157    |==              66       |
19/10/25-18:00:43  14   |======          1207199  |======          12       |=               82979    |=               7726   |======          0.34     |============    0.52     |=========       0.87     |===             495      |======          18       |                100      |                0        |       25786    |==              47       |
19/10/25-19:00:21  9    |===             974585   |====            13       |==              86140    |=               7207   |======          0.33     |============    0.52     |=========       0.81     |===             25       |                18       |                242      |                0        |       25401    |==              47       |
19/10/25-20:00:01  10   |====            1046275  |=====           9        |=               53301    |                5820   |====            0.29     |==========      0.54     |==========      0.81     |===             463      |======          12       |                38       |                0        |       8822     |                12       |
19/10/25-21:01:00  7    |==              757180   |===             6        |                36467    |                6597   |=====           0.30     |==========      0.49     |=========       0.88     |====            51       |                12       |                4        |                0        |       19274    |=               56       |
19/10/25-22:00:34  9    |===             946821   |====            10       |=               69448    |=               4547   |===             0.32     |===========     0.51     |=========       0.85     |===             635      |========        15       |                3        |                0        |       26281    |==              48       |
19/10/25-23:00:21  7    |==              706022   |===             17       |===             125509   |==              3140   |==              0.33     |============    0.57     |===========     0.81     |===             225      |==              22       |                2        |                0        |       21906    |==              17       |
20/10/25-00:00:52  5    |=               587365   |==              9        |=               67025    |=               3395   |==              0.31     |===========     0.53     |==========      0.79     |===             462      |======          18       |                9        |                0        |       23625    |==              43       |
20/10/25-01:00:17  9    |===             838839   |===             16       |==              98156    |==              4365   |===             0.37     |=============   0.56     |==========      2.64     |==============  465      |======          20       |                2        |                0        |       93631    |===========     557      |===========
20/10/25-02:00:55  11   |====            825485   |===             59       |=============   393682   |===========     3706   |==              0.35     |============    0.50     |=========       1.74     |========        521      |=======         77       |===             1        |                0        |       108653   |==============  16       |
20/10/25-03:00:20  9    |===             922271   |====            62       |==============  482251   |==============  2650   |=               0.29     |==========      0.43     |========        1.20     |=====           431      |=====           277      |==============  2        |                0        |       75033    |=========       114      |=
20/10/25-04:00:00  9    |===             1122106  |=====           44       |=========       340299   |=========       2816   |=               0.29     |==========      0.49     |=========       0.74     |===             379      |====            57       |==              2        |                0        |       17494    |=               18       |
20/10/25-05:00:26  9    |===             706002   |===             7        |                47668    |                3581   |==              0.30     |==========      0.54     |==========      0.79     |===             27       |                11       |                3        |                0        |       8315     |                8        |
20/10/25-06:00:09  9    |===             1013067  |====            7        |                48237    |                5124   |====            0.29     |==========      0.59     |===========     0.80     |===             361      |====            32       |                19       |                0        |       6251     |                6        |
20/10/25-07:00:35  11   |====            825198   |===             8        |                54832    |                5851   |====            0.32     |===========     0.65     |============    1.05     |====            243      |==              195      |=========       6        |                0        |       9993     |                21       |
20/10/25-08:00:13  16   |=======         1092007  |=====           15       |==              124172   |==              6696   |=====           0.34     |============    0.60     |===========     1.30     |======          606      |========        35       |                751      |                0        |       21746    |==              66       |
20/10/25-09:00:42  23   |==========      1605376  |========        16       |==              92551    |=               12386  |===========     0.35     |============    0.55     |==========      1.29     |======          279      |===             23       |                850      |                0        |       29415    |===             98       |=
20/10/25-10:00:59  30   |==============  2494093  |=============   20       |===             139411   |===             10653  |=========       0.33     |============    0.46     |========        1.05     |====            491      |======          42       |=               840      |                0        |       31651    |===             521      |===========
20/10/25-11:00:22  22   |==========      1904161  |==========      18       |===             110460   |==              11000  |==========      0.33     |============    0.51     |=========       1.81     |=========       138      |=               26       |                10609    |==============  0        |       58424    |=======         650      |==============
20/10/25-12:00:38  30   |==============  2008310  |==========      27       |=====           160873   |====            11750  |==========      0.31     |===========     0.65     |============    1.54     |=======         635      |========        54       |=               4372     |=====           0        |       29267    |===             409      |========
20/10/25-13:00:04  27   |============    2547270  |==============  49       |==========      332309   |=========       14765  |==============  0.00     |                0.00     |                0.00     |                232      |==              82       |===             0        |                0        |       28216    |==              341      |======
```


Некоторые показатели systemrics
```
$ rtpi prod-db mprod oratop h
DB=mprod 16/10/25-14:12:54 ver=15.10.25  oratop [ h [in=INST_ID] [con=[CON_ID]] | dhsh [in=INST_ID] [con=[CON_ID]] [dd/mm/yy-HH:MI-HH:MI(hours) - def3d] ] - Database and Instance parameters, h - history V$SYSMETRIC_HISTORY V$ACTIVE_SESSION_HISTORY, dhsh - dba_hist_sysmetric_history dba_hist_snapshot
Legend:
NCPU   - Number of CPU                                   AAS    - Average Active Sessions. (! if>#cpu)           IOMBPS - I/O megabytes per second (throughput)
HCPUB  - Host cpu busy %(busy/busy+idle). (! if>90%)     AST    - Active user Sessions Total (ASCPU+ASIO+ASWA)   IOPS   - I/O requests per second
CPUUPS - CPU Usage Per Sec                               ASCPU  - Active Sessions on CPU                         IORL   - I/O avg synch s/b/read latency in msec (! if>10ms)
LOAD   - Current os load. (! if>2*#CPU and high cpu)     ASIO   - Active Sessions waiting on user I/O            LOGR   - Logical reads per sec
DCTR   - DB CPU time ratio  % Cpu/DB_Time                ASWA   - Active Sessions Waiting, (! if>ASCPU+ASIO)     PHYR   - Physical reads per sec
DWTR   - DB WAIT time ratio (! if>50 and high ASWA)      ASPQ   - Active Parallel Sessions                       PHYW   - Physical writes per sec
SPFR   - Shared pool free %                              UTPS   - User transactions per sec                      TEMP   - Temp space used (Mb)
TPGA   - Total pga allocated                             UCPS   - User calls per sec                             DBTM   - Database Time Per Sec
SCT    - Session Count Total                             SSRT   - Sql service response time (T/call)

1                     2      3    4    5    6      7      8     9    10    11    12    13    14    15     16       17       18     19      20     21         22      23      24     25     26   27   29
BEGIN_TIME        HCPUB CPUUPS LOAD DCTR DWTR   SPFR   TPGA   SCT   AAS   AST ASCPU  ASIO  ASWA  ASPQ   UTPS     UCPS     SSRT IOMBPS    IOPS   IORL       LOGR    PHYR    PHYW   TEMP   DBTM   IN NCPU
----------------- ----- ------ ---- ---- ---- ------ ------ ----- ----- ----- ----- ----- ----- ----- ------ -------- -------- ------ ------- ------ ---------- ------- ------- ------ ------ ---- ----
16/10/25-13:11:34    20    895   21   46   53      5   3832  2268    19    17    14     3     1     0    247    34719      479    107   12060      0    1726963   10923     488   1547   1932    1   96
16/10/25-13:12:34    17    795   19   47   52      5   3653  2265    16    16    13     3     0     0    429    34238      408     83   10457      0    1547692    9218     420   1547   1664    1   96
16/10/25-13:13:33    18    809   19   46   53      5   4081  2266    17    18    14     4     0     0    448    34042      433    182   12247      0    1520024   21484    1010   1548   1737    1   96
16/10/25-13:14:33    22    966   22   40   59      5   3689  2278    23    26    20     6     1     0    435    32465      611   1321   17967      0    2139080  166825    1203   1549   2394    1   96
16/10/25-13:15:33    24   1049   23   38   61      5   3977  2260    27    25    19     6     0     0    499    32697      576   1092   20480      0    2082676  136820    1607   1548   2758    1   96
16/10/25-13:16:34    25   1041   24   39   60      5     77  2262    26    24    19     5     1     0    495    34932      615    913   26177      0    1790718  114010    1149   1556   2618    1   96
16/10/25-13:17:33    22    960   23   42   57      5    486  2277    22    21    17     4     0     0    486    31120      591   1214   19635      0    1749034  152026    1388   1811   2278    1   96
16/10/25-13:18:33    22    963   23   41   58      5    890  2274    22    22    17     5     0     0    335    30778      535   2870   12698      0    1921931  365574    1010   1547   2296    1   96
16/10/25-13:19:33    24   1035   25   42   57      5    890  2286    24    26    22     4     0     0    371    34768      540   1750   13665      0    2156275  222159     675   1558   2440    1   96
16/10/25-13:20:34    28   1131   26   38   61      5    931  2273    29    26    21     5     1     0    412    33737      630    718   18021      0    2614708   66925    1037   1551   2911    1   96
16/10/25-13:21:33    24   1040   27   42   57      5   2440  2254    24    21    19     3     0     0    407    33869      544    935   13592      0    2022679  113974    3440   2762   2440    1   96
16/10/25-13:22:33    23    984   24   44   55      5   2176  2280    22    23    19     4     0     0    238    29949      610   1663   10482      0    1946198  208682    1997   3178   2230    1   96
16/10/25-13:23:33    23   1013   25   42   57      5    759  2279    23    23    18     5     0     0    335    35849      536    910   15321      0    1816634  114865     689   1555   2396    1   96
16/10/25-13:24:34    24   1025   26   40   59      5    823  2264    25    25    20     5     0     0    311    37496      520   1672   18750      0    2137743  212121     632   1575   2556    1   96
16/10/25-13:25:33    24   1055   25   41   58      5   1554  2269    25    22    18     3     0     0    312    31884      557   1519   13625      0    2335843  191341    2173   1565   2541    1   96
16/10/25-13:26:33    21    942   24   46   53      5   1639  2267    20    21    17     3     0     0    360    30033      509   1286    8926      0    1972357  162327    1112   1495   2008    1   96
16/10/25-13:27:33    21    946   22   42   57      5   1025  2273    22    21    17     5     0     0    364    30891      516   2215   13990      0    1926989  281451     994   1525   2237    1   96
16/10/25-13:28:34    24   1014   24   41   58      5   1587  2267    24    26    22     5     0     0    374    37240      508   1347   17728      0    1965177  170585     797   1487   2472    1   96
16/10/25-13:29:33    32   1201   30   36   63      5   1344  2297    33    35    27     8     1     0    452    39916      645   1625   17988      0    2410837  205494     681   1491   3317    1   96
16/10/25-13:30:33    35   1233   33   32   67      5   1323  2301    37    34    27     8     0     0    466    45950      642   1449   24677      0    2547012  182514     746   1654   3739    1   96
16/10/25-13:31:34    32   1178   35   34   65      5   1263  2278    34    31    24     8     0     0    358    41183      667   1066   30549      0    2252355  134497     913   1485   3445    1   96
16/10/25-13:32:34    32   1092   35   35   64      5   1504  2288    30    29    24     6     0     0    337    38442      638   1063   20653      0    1855887  134254    1100   1488   3067    1   96
16/10/25-13:33:33    30   1069   33   21   78      5    314  2287    50    28    23     6     1     0    304    36347     1027    525   17759      0    2067069   65248    1070   1295   5027    1   96
16/10/25-13:34:33    32   1110   36   35   64      5    111  2285    30    28    23     5     1     0    357    39915      633    669   18159      0    2219786   65105    1230   1292   3084    1   96
16/10/25-13:35:34    26   1062   30   40   59      5   3996  2286    26    23    19     4     0     0    390    39100      548    480   13126      0    2242834   58368    1553   1327   2649    1   96
16/10/25-13:36:34    25   1050   28   41   58      5    581  2269    25    22    19     3     0     0    412    40914      512    635   14654      0    2057719   78681     798   1331   2507    1   96
16/10/25-13:37:33    21    952   25   48   51      5    587  2295    19    18    17     1     0     0    255    36440      440    427    6616      0    1794964   53660     485   1328   1952    1   96
16/10/25-13:38:33    22   1008   25   48   51      5    187  2311    20    17    17     1     0     0    180    32805      545    241    7778      0    2016095   28983    1591   1300   2065    1   96
16/10/25-13:39:34    22    962   22   48   51      5    445  2301    20    21    19     2     0     0    278    38280      430     68    6266      0    2300702    4783     926   1305   2003    1   96
16/10/25-13:40:34    20    922   22   46   53      5   3802  2303    19    17    15     2     0     0    280    35679      463     83    5740      0    2096930    6451    1090   1300   1979    1   96
16/10/25-13:41:33    18    838   20   52   47      5   3763  2287    16    16    15     1     0     0    226    28222      499    159    4367      0    1857671   18507    1048   1295   1605    1   96
16/10/25-13:42:33    18    875   19   50   49      5   3713  2289    17    15    14     1     1     0    301    30095      495     60    6467      0    1944186    6622     450   1312   1720    1   96
16/10/25-13:43:34    18    857   18   52   47      5   3862  2276    16    15    14     1     0     0    339    31682      443     60    4788      0    1584427    6763     295   1301   1635    1   96
16/10/25-13:44:34    21    956   21   49   50      5   3724  2276    19    20    19     1     0     0    278    26946      548    279    3996      0    2312796   33846    1156   1309   1924    1   96
16/10/25-13:45:33    19    885   20   49   50      5   3716  2290    17    15    14     1     0     0    355    35690      378     47    3957      0    1982363    4380     977   1314   1778    1   96
16/10/25-13:46:33    17    808   20   53   46      5   3733  2277    15    13    13     1     0     0    235    38957      341    139    3951      0    1562974   16691     460   1312   1512    1   96
16/10/25-13:47:33    17    794   18   53   46      5   3721  2280    14    14    14     1     0     0    362    37447      337     28    3432      0    1450190    2327     502   1312   1485    1   96
16/10/25-13:48:34    17    824   19   52   47      5   3901  2288    15    16    15     1     0     0    407    32049      382     54    6802      0    1494000    5586     447   1319   1576    1   96

$ rtpi prod-db mprod oratop h | diagram.sh 3 11 15 17 19 20 22 23 24
usage: ./diagram.sh sysmetric_h.log 25/11/23-0[89]  3 11 15 17 19 20 22 23 24
usage: tpi ... oratop h          | diagram.sh  3 11 15 17 19 20 22 23 24
usage: tpi ... oratop dhsh       | diagram.sh  2 5 6 9 10 11 13 14 15 17 18 21 23 24
usage: tpi ... dhash uchart      | diagram.sh  2 3 6 7 8 9 10 13 16
usage: tpi ... dhash iostat      | diagram.sh  2 3 4 5 6 7 8 9 10 11 12 13
usage: tpi ... dhash segstat . . | diagram.sh  5 6 7 8 9 10 11 12 13 14 15
usage: tpi ... dhash awrinfo     | diagram.sh  2 7 8 9 10 11 12 13 16 17 20 21 22 23

BEGIN_TIME         CPUUPS  LEVELS           AST  LEVELS           ASPQ  LEVELS  UCPS   LEVELS           IOMBPS  LEVELS           IOPS   LEVELS           LOGR     LEVELS           PHYR    LEVELS           PHYW   LEVELS
16/10/25-13:13:33  809     |========        18   |======          0     |       34042  |==========      182     |                12247  |=====           1520024  |=======         21484   |                1010   |
16/10/25-13:14:33  966     |==========      26   |==========      0     |       32465  |=========       1321    |=====           17967  |=======         2139080  |===========     166825  |=====           1203   |
16/10/25-13:15:33  1049    |===========     25   |=========       0     |       32697  |=========       1092    |====            20480  |=========       2082676  |==========      136820  |====            1607   |
16/10/25-13:16:34  1041    |===========     24   |=========       0     |       34932  |==========      913     |===             26177  |===========     1790718  |=========       114010  |===             1149   |
16/10/25-13:17:33  960     |==========      21   |========        0     |       31120  |=========       1214    |=====           19635  |========        1749034  |=========       152026  |=====           1388   |
16/10/25-13:18:33  963     |==========      22   |========        0     |       30778  |=========       2870    |==============  12698  |=====           1921931  |==========      365574  |==============  1010   |
16/10/25-13:19:33  1035    |===========     26   |==========      0     |       34768  |==========      1750    |========        13665  |=====           2156275  |===========     222159  |========        675    |
16/10/25-13:20:34  1131    |============    26   |==========      0     |       33737  |==========      718     |==              18021  |=======         2614708  |==============  66925   |=               1037   |
16/10/25-13:21:33  1040    |===========     21   |========        0     |       33869  |==========      935     |===             13592  |=====           2022679  |==========      113974  |===             3440   |=
16/10/25-13:22:33  984     |==========      23   |========        0     |       29949  |========        1663    |=======         10482  |====            1946198  |==========      208682  |=======         1997   |
16/10/25-13:23:33  1013    |===========     23   |========        0     |       35849  |==========      910     |===             15321  |======          1816634  |=========       114865  |===             689    |
16/10/25-13:24:34  1025    |===========     25   |=========       0     |       37496  |===========     1672    |=======         18750  |========        2137743  |===========     212121  |=======         632    |
16/10/25-13:25:33  1055    |===========     22   |========        0     |       31884  |=========       1519    |======          13625  |=====           2335843  |============    191341  |======          2173   |
16/10/25-13:26:33  942     |==========      21   |========        0     |       30033  |========        1286    |=====           8926   |===             1972357  |==========      162327  |=====           1112   |
16/10/25-13:27:33  946     |==========      21   |========        0     |       30891  |=========       2215    |==========      13990  |=====           1926989  |==========      281451  |==========      994    |
16/10/25-13:28:34  1014    |===========     26   |==========      0     |       37240  |===========     1347    |======          17728  |=======         1965177  |==========      170585  |=====           797    |
16/10/25-13:29:33  1201    |=============   35   |==============  0     |       39916  |============    1625    |=======         17988  |=======         2410837  |============    205494  |=======         681    |
16/10/25-13:30:33  1233    |==============  34   |=============   0     |       45950  |==============  1449    |======          24677  |===========     2547012  |=============   182514  |======          746    |
16/10/25-13:31:34  1178    |=============   31   |============    0     |       41183  |============    1066    |====            30549  |==============  2252355  |===========     134497  |====            913    |
16/10/25-13:32:34  1092    |============    29   |===========     0     |       38442  |===========     1063    |====            20653  |=========       1855887  |=========       134254  |====            1100   |
16/10/25-13:33:33  1069    |============    28   |===========     0     |       36347  |==========      525     |=               17759  |=======         2067069  |==========      65248   |=               1070   |
16/10/25-13:34:33  1110    |============    28   |===========     0     |       39915  |============    669     |==              18159  |=======         2219786  |===========     65105   |=               1230   |
16/10/25-13:35:34  1062    |===========     23   |========        0     |       39100  |===========     480     |=               13126  |=====           2242834  |===========     58368   |=               1553   |
16/10/25-13:36:34  1050    |===========     22   |========        0     |       40914  |============    635     |==              14654  |======          2057719  |==========      78681   |==              798    |
16/10/25-13:37:33  952     |==========      18   |======          0     |       36440  |==========      427     |=               6616   |==              1794964  |=========       53660   |=               485    |
16/10/25-13:38:33  1008    |===========     17   |======          0     |       32805  |=========       241     |                7778   |==              2016095  |==========      28983   |                1591   |
16/10/25-13:39:34  962     |==========      21   |========        0     |       38280  |===========     68      |                6266   |==              2300702  |============    4783    |                926    |
16/10/25-13:40:34  922     |==========      17   |======          0     |       35679  |==========      83      |                5740   |=               2096930  |===========     6451    |                1090   |
16/10/25-13:41:33  838     |=========       16   |=====           0     |       28222  |========        159     |                4367   |=               1857671  |=========       18507   |                1048   |
16/10/25-13:42:33  875     |=========       15   |=====           0     |       30095  |========        60      |                6467   |==              1944186  |==========      6622    |                450    |
16/10/25-13:43:34  857     |=========       15   |=====           0     |       31682  |=========       60      |                4788   |=               1584427  |========        6763    |                295    |
16/10/25-13:44:34  956     |==========      20   |=======         0     |       26946  |=======         279     |                3996   |                2312796  |============    33846   |                1156   |
16/10/25-13:45:33  885     |=========       15   |=====           0     |       35690  |==========      47      |                3957   |                1982363  |==========      4380    |                977    |
16/10/25-13:46:33  808     |========        13   |====            0     |       38957  |===========     139     |                3951   |                1562974  |=======         16691   |                460    |
16/10/25-13:47:33  794     |========        14   |=====           0     |       37447  |===========     28      |                3432   |                1450190  |=======         2327    |                502    |
16/10/25-13:48:34  824     |=========       16   |=====           0     |       32049  |=========       54      |                6802   |==              1494000  |=======         5586    |                447    |
```

Общий список опций и команд tpi:
```
Usage: /cygdrive/c/work/scripts/tpi/tpi <DBSID/PDB> [SPID\SID\OS_client_PID] [a|in|k] [p|ph [FALSE] <param>] [services] [dir] | lock | db | analyze | audit | health | oratop | sga | pga | size | arch | redo | undo | sesstat | segstat | o . | s . | e . | t . | i . | l . | c . | u . | r. | trg . | profile | links | latch | bind | pipe | longops | scheduler | job | rman | get_ddl | trace | kill | exec | alert | report ash/awr | corrupt | sql | ash | dhash | spm
[in=INST_ID] [con=[CON_ID]] "" - ACTIVE | a - Allsess | in - INACTIVE | k - KILLED | [access OBJECT] | P.SPID\S.SID\S.PROCESS [bind] [PEEKED_BINDS OUTLINE all ALLSTATS ADVANCED last adaptive PREDICATE partition] | p [param_name] ] - sess param info, p - from V$SES_OPTIMIZER_ENV by [param_name]
p [FALSE] [PAR1 PAR2 ..] | ph [FALSE] [PARAMETER] | services | dir | resource_limit | resumable - instance parameters or hidden parameters, [FALSE] - only changed parameters, v$services, dba_directories
db [ nls|option|properties|fusage|acl ] - gv$instance, v$database, dba_registry, dba_registry_sqlpatch, nls_database_paramters, v$option, database_properties information
wholink who is querying via dblink. The GTXID will match for both databases
analyze {gather|delete|set|lock} {table TABLE_NAME OWNER [PERCENT] [NUMROWS NUMLBLKS]} | lock\unlock {partition TABLE_NAME OWNER PART_NAME} | {index INDEX_NAME OWNER [PERCENT] [NUMROWS NUMLBLKS NUMDIST]} | {schema SCHEMA} | database | {system [INTERVAL_MIN|stop|show]} | dictionary | fixed - operations with stats
audit [login | logons [dd/mm/yy-HH:MI-HH:MI(hours)] | maxcon [dd/mm/yy-HH:MI-HH:MI(hours)] [CNT] | 1017 [dd/mm/yy-HH:MI-HH:MI(hours)] [USR] | obj [dd/mm/yy-HH:MI-HH:MI(hours)] [OBJ] ] - DDL users audit, login - check all users for simple password, logons - all logon, maxcon - max of db connections above CNT (def 100) for a period (def 1H), 1017 - failed login, obj - obj audit
health [cr | hot] - Database health parameters (HWM sessions, Hit Ratio / Get Misses cache, System Events Waits, Consistent Read buffers in SGA | Hot buffers)
oratop [ h [in=INST_ID] [con=[CON_ID]] | dhsh [in=INST_ID] [con=[CON_ID]] [dd/mm/yy-HH:MI-HH:MI(hours) - def3d] ] - Database and Instance parameters, h - history V$SYSMETRIC_HISTORY V$ACTIVE_SESSION_HISTORY, dhsh - dba_hist_sysmetric_history dba_hist_snapshot
sga - SGA information
pga [usage | pga_detail_get P.pid | pga_detail_cancel P.pid | pga_detail_show P.pid ] - PGA sessions information, pga_detail_show - V$PROCESS_MEMORY_DETAIL
size [days | tbs [free [SORT_COL_NAME]] | temp | sysaux | df [io|usage|lastseg[TBS]] | maxseg TBS | maxext | fra | rbin [all] | grows (days)] - Size of DB+archl (7 def), tablespaces, datafiles (HWM in DF+script), maxseg in all DB\TBS, FRA info + db_recovery_file_dest usage; recyclebin; ( exec 'alter system set "_enable_space_preallocation"=0' )
arch [seq [SEQ|dd/mm/yy-HH:MI] | scn [SCN|dd/mm/yy-HH:MI]] - archivelog, V$LOG V$ARCHIVE_DEST V$ARCHIVE_DEST_STATUS GV$MANAGED_STANDBY V$STANDBY_LOG information
redo [logs] - redo information
undo [recovery] - undo active transaction information, recovery information
sesstat [ list | sess SESS_ID [STATNAME] | STATNAME ] - sesstat information, where 'list' - STATISTIC NAMES, sess SESS_ID - sesstat for session, STATNAME - name particular of STATISTIC NAME
sysstat [ % | STATNAME ] - sysstat information, by startup, by day, by hours, by min, by sec
segstat [SEGMENT_NAME] [OWNER] - top 20 segments statistics information from V$SEGMENT_STATISTICS or SEGMENT_NAME statistics
o OBJECT_NAME | OBJECT_ID | invalid [OWNER] | ddl [last N hours] | depend REFERENCED_OBJ_NAME | depend last_analyzed HH OBJ_NAME - Show what REFERENCED_OBJ_NAME was last analyzed in depended OBJ_NAME - dba_objects information
s SEGMENT_NAME [OWNER] - dba_segments information
e SEGMENT_NAME [OWNER] - dba_extents, dba_tablespaces, dba_data_files - Extents in datafiles information
t [part] TABLE_NAME [OWNER] | last_analyzed HH [OWNER] | chained [PERCENT] - dba_tables, dba_part_tables, dba_tab_partitions, dba_tab_subpartitions information
i [part] INDEX_NAME [OWNER] | candidate [TABLE_NAME|%] [TABLE_OWNER] [TBS] | last_analyzed HH [OWNER] | rebuild TABLE_NAME OWNER [ONLINE [PARALLEL N]] - dba_indexes, dba_part_indexes, dba_ind_partitions, dba_ind_subpartitions information, candidate to rebulld
l [LOB_NAME] | [unused OWNER LOBSEGMENT] - dba_lobs information or show unused segment information -- sum(dbms_lob.getlength(CLOB_COL)/1024/1024)
c [ CONSTRAINT_NAME [OWNER] | T TABLE_NAME OWNER | PK PRIMARY_KEY OWNER | FK (TABLE_NAME [OWNER] | %) ] - dba_constraints, dba_cons_columns information, PK - Who refs to the PK, FK - Tables with non-indexed foreign keys
u [ USERNAME [{sys|role|tab} PRIVILEGE] ] - dba_users, dba_sys_privs, dba_role_privs, dba_tab_privs information
r [ {role|granted_role} ROLE ] - role_role_privs information
trg [ "" | [TRIGGER_NAME] [TRIGGER_OWNER] | t [TABLE_NAME] [TABLE_OWNER] ] - dba_triggers information, "" - LOGON or STARTUP triggers
profile [PROFILE] - profiles information
links [LINK_NAME] - links information
latch - latch information
lock [chain | lib | obj OBJECT_NAME | distrib [commit TRX | rollback TRX | purge TRX (for commited,collecting,prepared) | hardpurge TRX | hardpurge-ORA-02075-prepared TRX ] ] - blocking locks information, lib - library lock information
bind [SQL] - sql not using bind variable information
pipe [PIPE_NAME] - pipes information, read PIPE_NAME
longops [SID | MESSAGE | rman] - active session longops for SID or MESSAGE or rman backup elapsed time
scheduler [JOB_NAME | run JOB_NAME [hours] | log JOB_NAME [hours] | autotask ] - dba_scheduler_jobs information, log | run JOB_NAME [hours] - dba_scheduler_job_log | dba_scheduler_job_run_details for JOB_NAME in last [hours]
job [run] [JOB_ID|OWNER] - dba_jobs, dba_jobs_running information
rman [DAYS|dftb|cfg|last|arch [SEQUENCE] | recovery] - RMAN backups | df_to_backup | v$rman_configuration information | last - hours passed since the last backup | arch - last backup archivelog
get_ddl TYPE OBJECT (OWNER) - dbms_metadata.get_ddl extract dml, OBJECT - may be % or %mask%
trace [SID SERIAL LEVEL] [db {on|off}] - Trace for session, Level: 0-Disable, 1-Enable, 4-Enable with Binds, 8-Enable with Waits, 12-4+8, Trace all db sessions: on \ off
kill [SID SERIAL INST_ID] | [idle NUM_HOURS] | [where USERNAME="\'"SomeUser"\'"] | [ zombie_unix_list | zombie_win_list ] - Kill session, idle 5 - kill idle sessions for 5 hours and more, zombie_unix_list - only show zombie
exec [pt] "sql_statement" - execute "SQL Commands" Note: Must be escaped with \ character: $. ( pt "select * from gv\$sql_shared_cursor where sql_id='bpq3apk5q2c6z'" ) ( exec 'alter system set "_ash_sample_all"=true' )
alert [num] - tail -num alert_[sid].log, default num = 100
report [ash {text|html} -60] -for last hour, [awr {text|html} DD/MM/YYYY HH24_begin HH24_end], [awrdd {text|html} DD1/MM/YYYY HH24_begin HH24_end DD2/MM/YYYY HH24_begin HH24_end], [awrsql {text|html} DD/MM/YYYY HH24_begin HH24_end sql_id], [addm text DD/MM/YYYY HH24_begin HH24_end] - oracle reports
corrupt [{rowid|dba} ID] | [fb (FILE) (BLOCK)] - Find object by ROWID, Find object by DBA, Find DB Object in dba_extents by file/block, v$database_block_corruption v$nonlogged_block information
sql [ [top] | [SQL_ID | SQLTEXT] | [plan SQL_ID] | [expand SQL_ID] | [sqlarea_vercnt] | [child_reason SQL_ID] | sql_bind_metadata SQL_ID | sql_shared_cursor SQL_ID | [sqlstat [SQL_ID|par|inv|fch|sor|exe|pio|lio|row|cpu|ela|iow|mem] [executions] ] - Find out sql_id by SQLTEXT\SQL_ID from V$SQL, plan from VSQL_PLAN by sql_id, sqlstat from V$SQLSTAT by sql_id, GV$\SQLAREA
ash [in=INST_ID] [con=[CON_ID]] [dd/mm/yy-HH:MI-HH:MI(hours) - def1h] [ event | sess [SID SERIAL# [all|nosqlid|tchcnt] | SQL_ID] | where [FIELD CONDITION] | sql [top [event]] [all [event]] [SQL_ID|SQL_TEXT] | plan SQL_ID [fmt display plan] | sqlstat [SQL_ID|par|inv|fch|sor|exe|pio|lio|row|cpu|ela|iow|mem] [executions] | insection [username|service|machine|program,module,action|sql_opname,sql_plan_operation,sql_plan_options|PLSQL_ENTRY_OBJECT_ID|event|wait_class] | temp [sizeMb] | (umc)chart ] - Top SQL, Events, Sessions GV$ACTIVE_SESSION_HISTORY
dhash [in=INST_ID] [con=[CON_ID]] [dd/mm/yy-HH:MI-HH:MI(hours) - def1h] [ event | sess [SID SERIAL# [all|nosqlid|tchcnt] | SQL_ID] | where [FIELD CONDITION] | sql [top [event]] [all [event]] [SQL_ID|SQL_TEXT] | plan SQL_ID PHV [fmt display plan] | sqlstat [SQL_ID|pio|lio|cpu|exe|ela|fch|sor|iow|row] [executions] | insection [username|service|machine|program,module,action|sql_opname,sql_plan_operation,sql_plan_options|PLSQL_ENTRY_OBJECT_ID|event|wait_class] | growseg [TBS] [SEGMENT] | segstat [SEGMENT] [OWNER] [SORT_COL] | temp [sizeMb] | (umc)chart | iostat [df|redo|ctl|temp|arch|other] ] | awrinfo - Top SQL, Events, Sessions DBA_HIST_ACTIVE_SESS_HISTORY
spm [days def7 - baselines] [find %|SQL_HANDLE SQL_PLAN_NAME] [ blplan %|SQL_HANDLE (PLAN_NAME) | blexec [count] | bllpfcc SQL_ID PLAN_HASH_VALUE [SQL_HANDLE] | bllpfawr SQL_ID PLAN_HASH_VALUE MIN_SNAP_ID MAX_SNAP_ID | blchattr SQL_HANDLE PLAN_NAME ATTR VALUE | blchplan NEW_SQL_ID NEW_PHV OLD_SQLSET_NAME | blevolve SQL_HANDLE PLAN_NAME | sqlset_list SQLSET_NAME OWNER | sqlset_plan SQLSET_NAME SQL_ID [PHV] | sqlset_drop SQLSET_NAME | bldrop SQL_HANDLE (PLAN_NAME) | sqltune [SQL_ID | awr SQL_ID begin_snap end_snap] | sqltune_report TASK_NAME | sqltune_accept TASK_NAME | sqltune_create_plan_bl TASK_NAME OWNER PLAN_HASH_VALUE | sqltune_list [TASK_NAME] [cnt] | sqltune_drop TASK_NAME | sql_profiles | import_sql_profile SQL_ID_SRC PHV_SRC SQL_ID_TARGET | sql_profile_chattr TASK_NAME ATTR VALUE | sql_profile_drop NAME | hints profile|baseline|patch NAME | sqlpatch_list | sqlpatch_create SQL_ID 'HINTS"\'"' | sqlpatch_alter PATCHNAME enable|disable | sqlpatch_drop PATCHNAME | report_sql_monitor SQL_ID ]

```
