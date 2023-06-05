--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: taln.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: List user with unlimited quota on one or any 
--              tablespace. Query is doing a like &1	on tablespace
--  Usage.....: @tsq <TABLESPACE_NAME> or % for all
--  Notes.....: 
--  Reference.: Called as DBA or user with access to dba_ts_quotas
--              dba_sys_privs,dba_role_privs,dba_users
--  License...: Licensed under the Universal Permissive License v 1.0 as 
--              shown at http://oss.oracle.com/licenses/upl.
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
col tsq_username head "User Name" for a30
col tsq_tablespace_name head "Tablespace Name" for a30
col tsq_privilege head "Privilege" for a25

SET VERIFY OFF
SET TERMOUT OFF

column 1 new_value 1
SELECT '' "1" FROM dual WHERE ROWNUM = 0;
define ts = '&1'

SET TERMOUT ON

SELECT 
  username tsq_username,
  tablespace_name tsq_tablespace_name,
  privilege tsq_privilege
FROM (
  SELECT 
    grantee username, 'Any Tablespace' tablespace_name, privilege
  FROM (
    -- first get the users with direct grants
    SELECT 
      p1.grantee grantee, privilege
    FROM 
      dba_sys_privs p1
    WHERE 
      p1.privilege='UNLIMITED TABLESPACE'
    UNION ALL
    -- and then the ones with UNLIMITED TABLESPACE through a role...
    SELECT 
      r3.grantee, granted_role privilege
    FROM 
      dba_role_privs r3
      START WITH r3.granted_role IN (
          SELECT 
            DISTINCT p4.grantee 
          FROM 
            dba_role_privs r4, dba_sys_privs p4 
          WHERE 
            r4.granted_role=p4.grantee AND p4.privilege = 'UNLIMITED TABLESPACE')
    CONNECT BY PRIOR grantee = granted_role)
    -- we just whant to see the users not the roles
  WHERE grantee IN (SELECT username FROM dba_users) OR grantee = 'PUBLIC'
  UNION ALL 
  -- list the user with unimited quota on a dedicated tablespace
  SELECT 
    username,tablespace_name,'DBA_TS_QUOTA' privilege 
  FROM 
    dba_ts_quotas 
  WHERE 
    max_bytes <0)
WHERE tablespace_name LIKE UPPER('%&ts%') OR tablespace_name = 'Any Tablespace'
ORDER BY tsq_username,tsq_tablespace_name,tsq_privilege;

SET HEAD OFF
select 'Filter on tablespace name => '||NVL('&ts','%') from dual;    
SET HEAD ON
undefine 1
-- EOF ---------------------------------------------------------------------