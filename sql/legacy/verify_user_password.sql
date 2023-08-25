--------------------------------------------------------------------------------
--  OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
--------------------------------------------------------------------------------
--  Name......: verify_user_password.sql
--  Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
--  Editor....: Stefan Oehrli
--  Date......: 2018.12.11
--  Revision..:  
--  Purpose...: Wrapper script to check if a user in sys.user$  
--              has a weak password. Passwords will be displayed
--  Usage.....: @verify_user_password
--  Notes.....: 
--  Reference.: requires execute on dbms_crypto
--  License...: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
----------------------------------------------------------------------------
--  Modified..:
--  see git revision history for more information on changes/updates
----------------------------------------------------------------------------
--     Revision history.:  see svn log
----------------------------------------------------------------------------
@verify_passwords.sql TRUE &1 60
-- EOF ---------------------------------------------------------------------