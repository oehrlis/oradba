PROMPT Extension template SQL sample;
PROMPT Replace this with your own query;

SET PAGESIZE 200
SET LINESIZE 200

SELECT name,
       open_mode,
       created,
       log_mode
FROM   v$database;
