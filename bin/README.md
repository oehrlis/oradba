# Scripts and Tools

This folder contains scripts and tools to administer TNS Names with OpenLDAP.
These are in particular:

- [exp_jobs.ksh](./exp_jobs.ksh) Monitor the current running DataPump jobs in
  v$session_longops
- [mos_download_url.sh](./mos_download_url.sh) Download Patch's from MOS
  (My Oracle Support)
- [rman_jobs.ksh](./rman_jobs.ksh) Monitor the current runing RMAN jobs in
  v$session_longops
- [test_scripts.sh](./test_scripts.sh) Script to test / verify all TNS utilities
- [test_unit.sh](./test_unit.sh) Script to test / verify all TNS utilities
- [tns_add.sh](./tns_add.sh) Script to add an *Oracle Net Service Name* with
  corresponding *Oracle Net Service Description* in one or more Base DN.
- [tns_delete.sh](./tns_delete.sh) Script to delete an *Oracle Net Service Name*
  in one / more Base DN.
- [tns_dump.sh](./tns_dump.sh) Script to create a *tnsnames.ora* file for one /
  more Base DN.
- [tns_functions.sh](./tns_functions.sh) common functions for the scripts.
- [tns_load.sh](./tns_load.sh) script to do bulk load one or more *tnsnames.ora*
  files.
- [tns_modify.sh](./tns_modify.sh) Script to modify an *Oracle Net Service Name*
  with corresponding *Net Service Description* in one or more Base DN.
- [tns_search.sh](./tns_search.sh) Script to search *Oracle Net Service Names* in
  one or more Base DN.
- [tns_test.sh](./tns_test.sh) Script to test *Oracle Net Service Names* in one or
  more base DN. The tests are done with *tnsping* and *sqlplus*.
