-- ------------------------------------------------------------------------------
-- Name.......: customer_query.sql
-- Purpose....: Example customer SQL script
-- Usage......: SQL> @customer_query.sql
-- Notes......: This script is automatically in SQLPATH when extension loads
-- ------------------------------------------------------------------------------

SET PAGESIZE 100
SET LINESIZE 200

PROMPT ===================================
PROMPT Customer Query - Example Extension
PROMPT ===================================
PROMPT

-- Show database information
SELECT 
    'Database Name: ' || name,
    'DB Unique Name: ' || db_unique_name,
    'Open Mode: ' || open_mode,
    'Created: ' || TO_CHAR(created, 'YYYY-MM-DD HH24:MI:SS')
FROM v$database;

PROMPT
PROMPT This is an example SQL script demonstrating the extension system.
PROMPT Replace this with your own customer-specific queries.
PROMPT
