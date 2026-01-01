-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name.......: rowid.sql
-- Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor.....: Stefan Oehrli
-- Date.......: 2026.01.01
-- Revision...: 0.9.5
-- Purpose....: Decode ROWID information for table rows
-- Notes......: Requires two parameters: table name and WHERE clause
-- Usage......: @rowid TABLE_NAME "WHERE_CLAUSE"
-- Reference..: https://github.com/oehrlis/oradba
-- License....: Apache License Version 2.0, January 2004 as shown
--              at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------
SELECT
     decode(dbms_rowid.ROWID_TYPE (rowid),0,'restricted', 1 ,'extended')  type
    , dbms_rowid.ROWID_OBJECT (rowid) object#
    , dbms_rowid.ROWID_RELATIVE_FNO(rowid) rfile#
    , dbms_rowid.ROWID_BLOCK_NUMBER(rowid) block#
    , dbms_rowid.ROWID_ROW_NUMBER(rowid)   row#
    , rowid
FROM
    &1
WHERE
    &2
/


