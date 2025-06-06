--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: ssa_hip.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: Show all (hidden and regular) init parameter
--  Usage.....: @hip <PARAMETER> or % for all
--  Notes.....: Called  DBA or user with access to x$ksppi, x$ksppcv, 
--              x$ksppsv, v$parameter
--  Reference.: 
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
--------------------------------------------------------------------------------
COL Parameter for a40
COL Session for a9
COL Instance for a30
COL S for a1
COL I for a1
COL D for a1
COL Description for a60 
SET VERIFY OFF
SET TERMOUT OFF

column 1 new_value 1
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
define parameter = '&1'

SET TERMOUT ON

SELECT  
  a.ksppinm  "Parameter", 
  decode(p.isses_modifiable,'FALSE',NULL,NULL,NULL,b.ksppstvl) "Session", 
  c.ksppstvl "Instance",
  decode(p.isses_modifiable,'FALSE','F','TRUE','T') "S",
  decode(p.issys_modifiable,'FALSE','F','TRUE','T','IMMEDIATE','I','DEFERRED','D') "I",
  decode(p.isdefault,'FALSE','F','TRUE','T') "D",
  a.ksppdesc "Description"
FROM x$ksppi a, x$ksppcv b, x$ksppsv c, v$parameter p
WHERE a.indx = b.indx AND a.indx = c.indx
  AND p.name(+) = a.ksppinm
  AND upper(a.ksppinm) LIKE upper(DECODE('&parameter', '', '%', '%&parameter%'))
ORDER BY a.ksppinm;

SET HEAD OFF
SELECT 'Filter on parameter => '||NVL('&parameter','%') FROM dual;    
SET HEAD ON
undefine 1
-- EOF -------------------------------------------------------------------------