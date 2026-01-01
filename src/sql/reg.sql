-- -----------------------------------------------------------------------------
-- OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
-- -----------------------------------------------------------------------------
-- Name......: reg.sql
-- Author....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
-- Editor....: Stefan Oehrli
-- Date......: 2026.01.01
-- Revision..: 0.9.5
-- Purpose...: Display Oracle Database Registry information
-- Notes.....: Simple wrapper script for dba_registry query
-- Usage.....: @reg
-- Reference.: https://github.com/oehrlis/oradba
-- License...: Apache License Version 2.0, January 2004 as shown
--             at http://www.apache.org/licenses/
-- -----------------------------------------------------------------------------

col reg_comp_name head "Component Name" for a50
col reg_version head "Version" for a15
col reg_status head "Status" for a11
col reg_schema head "Schema" for a15
col reg_modified head "Modified" for a20
 
select 
       COMP_NAME reg_comp_name,
       VERSION reg_version,
       STATUS reg_status, 
       SCHEMA reg_schema,
       MODIFIED reg_modified
from 
       dba_registry;
