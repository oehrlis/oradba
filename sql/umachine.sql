----------------------------------------------------------------------------
--  Trivadis AG, Infrastructure Managed Services
--  Saegereistrasse 29, 8152 Glattbrugg, Switzerland
----------------------------------------------------------------------------
--  Name......: umachine.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: Show user sessions based on Machine name.
--  Usage.....: @umachine <MACHINE>
--  Notes.....: 
--  Reference.: Idea based on a script from tanel@tanelpoder.com
--  License...: Licensed under the Universal Permissive License v 1.0 as 
--              shown at http://oss.oracle.com/licenses/upl.
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
col u_username head USERNAME for a23
col u_sid head SID for a14 
col u_audsid head AUDSID for 9999999999
col u_osuser head OSUSER for a16
col u_machine head MACHINE for a18
col u_program head PROGRAM for a20

select s.username u_username, ' ''' || s.sid || ',' || s.serial# || '''' u_sid, 
       s.audsid u_audsid,
       s.osuser u_osuser, 
       substr(s.machine,instr(s.machine,'\')) u_machine, 
       substr(s.program,instr(s.program,'('),20) u_program,
       p.spid, 
       -- s.sql_address, 
       s.sql_hash_value, 
       s.last_call_et lastcall, 
       s.status 
       --, s.logon_time
from 
    v$session s,
    v$process p
where
    s.paddr=p.addr
and s.machine in ('&1')
--and s.status='ACTIVE'
/
-- EOF ---------------------------------------------------------------------