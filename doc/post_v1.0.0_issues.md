# Post v1.0.0 Issues and Cleanup

## Background

Release v1.0.0 has been installed successfully on production systems which is
primarily used for Oracle Data Safe On-Premise installations. Beside this we
also have an Oracle Client installation, whereby we use an instant and a full
client installation. Additionally we also have the oci-cli installed for Oracle Cloud access.

## Issues Found

During the installation and first usage of v1.0.0 we found some issues that
need to be addressed in future releases:

### Environment without oratab

The current implementation assumes that an oratab file is always present on
the system. While this is true for database servers, it is not the case for
client-only installations. We need to address this and allow operation without
an oratab file. This affects functions in `oradba_env_parser.sh` and
`oradba_env_builder.sh`.

Example Output of the system status command without oratab file:

```bash
oravw@lxf202p2076:~/ [iclient26] u
 
Oracle Environment Status
TYPE (Cluster|DG) : SID/PROCESS  STATUS      HOME
---------------------------------------------------------------------------------
 
  ℹ No database entries found in oratab
 
  The oratab file exists but contains no database entries.
  Add Oracle instances to: /appl/oracle/local/oradba/etc/oratab
 
---------------------------------------------------------------------------------
```

### Unnecessary Function Exports

The environment management libraries currently export functions using
`export -f`, which pollutes the bash environment with `BASH_FUNC_*` entries.
Since these libraries are sourced, the functions are already available without
exporting them. We should remove these exports to clean up the environment.
This affects all six environment management libraries:

- `oradba_env_config.sh`
- `oradba_env_builder.sh`
- `oradba_env_parser.sh`
- `oradba_env_validator.sh`
- `oradba_env_changes.sh`
- `oradba_env_status.sh`   

### Data Safe Home

Registering on-premise Data Safe installations has been done the following way:

```bash
oradba_homes.sh add --name "dsconha1" --path "/appl/oracle/product/exacc-wob-vwg-ha1" --type "datasafe" --alias "dsha1" --desc "DataSafe on Premises Connector ds-conn-exacc-wob-vwg-ha1"
```

Sourcing the environment for this home currently does show the correct product
after wards. See example output below. However, the product type is shown as
 `unknown`.

```bash
oravw@lxf202p2076:~/ [dsha1] dsha1
[WARN] 2026-01-15 15:59:22 - Unknown product type: unknown
[ERROR] 2026-01-15 15:59:22 - sqlplus not found in ORACLE_HOME
 
-------------------------------------------------------------------------------
ORACLE_BASE    : /appl/oracle
ORACLE_HOME    : /appl/oracle/product/exacc-wob-vwg-ha1
TNS_ADMIN      : /appl/oracle/product/23.26.0.0/client/network/admin
ORACLE_VERSION : Unknown
-------------------------------------------------------------------------------
PRODUCT_TYPE   : unknown
-------------------------------------------------------------------------------
```

Below you see the tree of a typical Data Safe on-premise connector installation.
There is a bin folder which has to be adde to the PATH as well as a specific
lib folder which has to be added to the LD_LIBRARY_PATH. The current
implementation does not do this correctly. Unfortunately Oracle does not have
any sqlplus or other database binaries in this home so the validation of the
home fails. Output is generated using find/awk as the tree command is not
available on this system.

```bash
ravw@lxf201p1312:/appl/oracle/product/dsconnect $ cat tree.txt
├── ds-conn-exacc-p1312-wob-vwg
│   ├── log
│   │   ├── setup.log
│   │   ├── start.log
│   │   ├── stop.log
│   │   ├── monitor.log
│   │   ├── status.log
│   ├── downloads
│   │   ├── orapki.zip
│   │   ├── cman.zip
│   │   ├── cmanora.template
│   ├── util
│   │   ├── datasafe_privileges.sql
│   │   ├── connector_osuser_service.sh
│   ├── README
│   ├── wallet
│   │   ├── ewallet.p12
│   │   ├── ewallet.p12.lck
│   │   ├── cwallet.sso.lck
│   │   ├── cwallet.sso
│   │   ├── connector_ca.txt
│   │   ├── exa118r05s15.b2x.vwg.cert
│   ├── setup.py
│   ├── LICENSE
│   ├── connector.conf
│   ├── oracle_cman_home
│   │   ├── bin
│   │   │   ├── adrci
│   │   │   ├── cmadmin
│   │   │   ├── cmctl.bin
│   │   │   ├── cmgw
│   │   │   ├── cmop
│   │   │   ├── lsnrctl
│   │   │   ├── tnsping
│   │   │   ├── tnslsnr
│   │   │   ├── cmctl
│   │   │   ├── mkstore
│   │   │   ├── orapki
│   │   ├── oracore
│   │   │   ├── zoneinfo
│   │   │   │   ├── timezone_18.dat
│   │   │   │   ├── timezlrg_9.dat
│   │   │   │   ├── timezone_1.dat
│   │   │   │   ├── timezone_22.dat
│   │   │   │   ├── timezone_34.dat
│   │   │   │   ├── timezone_13.dat
│   │   │   │   ├── timezone_23.dat
│   │   │   │   ├── timezone_8.dat
│   │   │   │   ├── timezone_10.dat
│   │   │   │   ├── timezone_14.dat
│   │   │   │   ├── timezone_15.dat
│   │   │   │   ├── timezone_19.dat
│   │   │   │   ├── timezone_20.dat
│   │   │   │   ├── timezone_24.dat
│   │   │   │   ├── timezone_26.dat
│   │   │   │   ├── timezone_32.dat
│   │   │   │   ├── timezone_2.dat
│   │   │   │   ├── timezone_33.dat
│   │   │   │   ├── timezone_27.dat
│   │   │   │   ├── timezlrg_7.dat
│   │   │   │   ├── timezone_12.dat
│   │   │   │   ├── timezone_30.dat
│   │   │   │   ├── timezone_31.dat
│   │   │   │   ├── timezone_35.dat
│   │   │   │   ├── timezone_5.dat
│   │   │   │   ├── timezone_7.dat
│   │   │   │   ├── timezone_16.dat
│   │   │   │   ├── timezone_21.dat
│   │   │   │   ├── timezone_25.dat
│   │   │   │   ├── timezone_9.dat
│   │   │   │   ├── timezone_29.dat
│   │   │   │   ├── timezone_4.dat
│   │   │   │   ├── timezone_6.dat
│   │   │   │   ├── timezdif.csv
│   │   │   │   ├── timezone_11.dat
│   │   │   │   ├── timezone_17.dat
│   │   │   │   ├── timezone_28.dat
│   │   │   │   ├── timezone_3.dat
│   │   │   │   ├── timezlrg_10.dat
│   │   │   │   ├── timezlrg_11.dat
│   │   │   │   ├── timezlrg_12.dat
│   │   │   │   ├── timezlrg_13.dat
│   │   │   │   ├── timezlrg_14.dat
│   │   │   │   ├── timezlrg_15.dat
│   │   │   │   ├── timezlrg_16.dat
│   │   │   │   ├── timezlrg_17.dat
│   │   │   │   ├── timezlrg_18.dat
│   │   │   │   ├── timezlrg_19.dat
│   │   │   │   ├── timezlrg_1.dat
│   │   │   │   ├── timezlrg_20.dat
│   │   │   │   ├── timezlrg_21.dat
│   │   │   │   ├── timezlrg_22.dat
│   │   │   │   ├── timezlrg_23.dat
│   │   │   │   ├── timezlrg_24.dat
│   │   │   │   ├── timezlrg_25.dat
│   │   │   │   ├── timezlrg_26.dat
│   │   │   │   ├── timezlrg_27.dat
│   │   │   │   ├── timezlrg_28.dat
│   │   │   │   ├── timezlrg_29.dat
│   │   │   │   ├── timezlrg_2.dat
│   │   │   │   ├── timezlrg_30.dat
│   │   │   │   ├── timezlrg_31.dat
│   │   │   │   ├── timezlrg_32.dat
│   │   │   │   ├── timezlrg_33.dat
│   │   │   │   ├── timezlrg_34.dat
│   │   │   │   ├── timezlrg_35.dat
│   │   │   │   ├── timezlrg_3.dat
│   │   │   │   ├── timezlrg_4.dat
│   │   │   │   ├── timezlrg_5.dat
│   │   │   │   ├── timezlrg_6.dat
│   │   │   │   ├── timezlrg_8.dat
│   │   ├── rdbms
│   │   │   ├── mesg
│   │   │   │   ├── ocius.msb
│   │   │   │   ├── oraus.msb
│   │   ├── lib
│   │   │   ├── libccme_asym.so
│   │   │   ├── libccme_base_non_fips.so
│   │   │   ├── libccme_base.so
│   │   │   ├── libccme_ecc_non_fips.so
│   │   │   ├── libcryptocme.so
│   │   │   ├── libclntsh.so.21.1
│   │   │   ├── libclntshcore.so.21.1
│   │   │   ├── libnnz21.so
│   │   │   ├── libons.so
│   │   ├── log
│   │   │   ├── diag
│   │   │   │   ├── netcman
│   │   │   │   │   ├── lxf201p1312
│   │   │   │   │   │   ├── cust_cman
│   │   │   │   │   │   │   ├── trace
│   │   │   │   │   │   │   │   ├── cust_cman.log
│   │   │   │   │   │   │   │   ├── cust_cman_1.log
│   │   │   │   │   │   │   │   ├── cust_cman_2.log
│   │   │   │   │   │   │   │   ├── cust_cman_3.log
│   │   │   │   │   │   │   │   ├── cust_cman_4.log
│   │   │   │   │   │   │   │   ├── cust_cman_5.log
│   │   │   │   │   │   │   ├── alert
│   │   │   │   │   │   │   │   ├── log.xml
│   │   │   │   │   │   │   │   ├── log_1.xml
│   │   │   │   │   │   │   │   ├── log_2.xml
│   │   │   │   │   │   │   │   ├── log_3.xml
│   │   │   │   │   │   │   │   ├── log_4.xml
│   │   │   │   │   │   │   │   ├── log_5.xml
│   │   │   │   │   │   │   ├── incident
│   │   │   │   │   │   │   ├── metadata
│   │   │   │   │   │   │   │   ├── ADR_CONTROL.ams
│   │   │   │   │   │   │   │   ├── ADR_INVALIDATION.ams
│   │   │   │   │   │   │   │   ├── INC_METER_IMPT_DEF.ams
│   │   │   │   │   │   │   │   ├── INC_METER_PK_IMPTS.ams
│   │   │   │   │   │   │   ├── metadata_pv
│   │   │   │   │   │   │   ├── metadata_dgif
│   │   │   │   │   │   │   ├── incpkg
│   │   │   │   │   │   │   ├── sweep
│   │   │   │   │   │   │   ├── lck
│   │   │   │   │   │   │   │   ├── AM_3216668543_3129272988.lck
│   │   │   │   │   │   │   │   ├── AM_1744845641_3861997533.lck
│   │   │   │   │   │   │   │   ├── AM_1096102193_3488045378.lck
│   │   │   │   │   │   │   │   ├── AM_1096102262_3454819329.lck
│   │   │   │   │   │   │   ├── cdump
│   │   │   │   │   │   │   ├── stage
│   │   │   │   │   │   │   ├── log
│   │   │   │   │   │   │   │   ├── debug
│   │   │   │   │   │   │   │   ├── test
│   │   │   │   │   │   │   │   ├── attention
│   │   │   │   │   ├── lxf202p1312
│   │   │   │   │   │   ├── cust_cman
│   │   │   │   │   │   │   ├── trace
│   │   │   │   │   │   │   │   ├── cust_cman.log
│   │   │   │   │   │   │   ├── alert
│   │   │   │   │   │   │   │   ├── log.xml
│   │   │   │   │   │   │   ├── incident
│   │   │   │   │   │   │   ├── metadata
│   │   │   │   │   │   │   │   ├── ADR_CONTROL.ams
│   │   │   │   │   │   │   │   ├── ADR_INVALIDATION.ams
│   │   │   │   │   │   │   │   ├── INC_METER_IMPT_DEF.ams
│   │   │   │   │   │   │   │   ├── INC_METER_PK_IMPTS.ams
│   │   │   │   │   │   │   ├── metadata_pv
│   │   │   │   │   │   │   ├── metadata_dgif
│   │   │   │   │   │   │   ├── incpkg
│   │   │   │   │   │   │   ├── sweep
│   │   │   │   │   │   │   ├── lck
│   │   │   │   │   │   │   │   ├── AM_3216668543_3129272988.lck
│   │   │   │   │   │   │   │   ├── AM_1744845641_3861997533.lck
│   │   │   │   │   │   │   │   ├── AM_1096102193_3488045378.lck
│   │   │   │   │   │   │   │   ├── AM_1096102262_3454819329.lck
│   │   │   │   │   │   │   ├── cdump
│   │   │   │   │   │   │   ├── stage
│   │   │   │   │   │   │   ├── log
│   │   │   │   │   │   │   │   ├── debug
│   │   │   │   │   │   │   │   ├── test
│   │   │   │   │   │   │   │   ├── attention
│   │   ├── network
│   │   │   ├── mesg
│   │   │   │   ├── tnplel.msb
│   │   │   │   ├── ncxn.msb
│   │   │   │   ├── nncsk.msb
│   │   │   │   ├── snliw.msb
│   │   │   │   ├── nnlja.msb
│   │   │   │   ├── naukja.msb
│   │   │   │   ├── nnfhu.msb
│   │   │   │   ├── nnfd.msb
│   │   │   │   ├── snlel.msb
│   │   │   │   ├── tnplsk.msb
│   │   │   │   ├── gsmzhs.msb
│   │   │   │   ├── npli.msb
│   │   │   │   ├── niqn.msb
│   │   │   │   ├── ncrsk.msb
│   │   │   │   ├── snln.msb
│   │   │   │   ├── niqsf.msb
│   │   │   │   ├── nnfsk.msb
│   │   │   │   ├── tnlsf.msb
│   │   │   │   ├── ncrro.msb
│   │   │   │   ├── niqel.msb
│   │   │   │   ├── nplsf.msb
│   │   │   │   ├── nncpl.msb
│   │   │   │   ├── nnfnl.msb
│   │   │   │   ├── nlcs.msb
│   │   │   │   ├── ncxd.msb
│   │   │   │   ├── ncrzht.msb
│   │   │   │   ├── nmpn.msb
│   │   │   │   ├── nnlro.msb
│   │   │   │   ├── nncru.msb
│   │   │   │   ├── snlf.msb
│   │   │   │   ├── niqpl.msb
│   │   │   │   ├── npln.msb
│   │   │   │   ├── nnlsk.msb
│   │   │   │   ├── tnlus.msb
│   │   │   │   ├── ncius.msb
│   │   │   │   ├── gsmcs.msb
│   │   │   │   ├── ncrus.msb
│   │   │   │   ├── snldk.msb
│   │   │   │   ├── nnlel.msb
│   │   │   │   ├── tnlth.msb
│   │   │   │   ├── nmpe.msb
│   │   │   │   ├── snlus.msb
│   │   │   │   ├── nmpiw.msb
│   │   │   │   ├── nmpzhs.msb
│   │   │   │   ├── nmpcs.msb
│   │   │   │   ├── gsms.msb
│   │   │   │   ├── nnlzht.msb
│   │   │   │   ├── tnpld.msb
│   │   │   │   ├── nplzhs.msb
│   │   │   │   ├── nmpja.msb
│   │   │   │   ├── niqzhs.msb
│   │   │   │   ├── nmri.msb
│   │   │   │   ├── nnlptb.msb
│   │   │   │   ├── nmpnl.msb
│   │   │   │   ├── tnlf.msb
│   │   │   │   ├── tnpls.msb
│   │   │   │   ├── tnshu.msb
│   │   │   │   ├── ncrel.msb
│   │   │   │   ├── tnspl.msb
│   │   │   │   ├── niqcs.msb
│   │   │   │   ├── ncrar.msb
│   │   │   │   ├── nplnl.msb
│   │   │   │   ├── gsmel.msb
│   │   │   │   ├── nnldk.msb
│   │   │   │   ├── nnle.msb
│   │   │   │   ├── nncth.msb
│   │   │   │   ├── tnsptb.msb
│   │   │   │   ├── nnlnl.msb
│   │   │   │   ├── nlru.msb
│   │   │   │   ├── nld.msb
│   │   │   │   ├── nnlpt.msb
│   │   │   │   ├── niqro.msb
│   │   │   │   ├── snlth.msb
│   │   │   │   ├── nnchu.msb
│   │   │   │   ├── snlpl.msb
│   │   │   │   ├── tnle.msb
│   │   │   │   ├── ncxar.msb
│   │   │   │   ├── ncxsk.msb
│   │   │   │   ├── tnsth.msb
│   │   │   │   ├── tnlhu.msb
│   │   │   │   ├── nncn.msb
│   │   │   │   ├── npliw.msb
│   │   │   │   ├── tnpli.msb
│   │   │   │   ├── tnsel.msb
│   │   │   │   ├── niqko.msb
│   │   │   │   ├── nncs.msb
│   │   │   │   ├── tnplru.msb
│   │   │   │   ├── niqhu.msb
│   │   │   │   ├── niqe.msb
│   │   │   │   ├── nplzht.msb
│   │   │   │   ├── nmrja.msb
│   │   │   │   ├── nlro.msb
│   │   │   │   ├── nlth.msb
│   │   │   │   ├── ncrzhs.msb
│   │   │   │   ├── nncpt.msb
│   │   │   │   ├── niqtr.msb
│   │   │   │   ├── snle.msb
│   │   │   │   ├── tnplhu.msb
│   │   │   │   ├── niqs.msb
│   │   │   │   ├── niqf.msb
│   │   │   │   ├── nnczht.msb
│   │   │   │   ├── nnfe.msb
│   │   │   │   ├── nncus.msb
│   │   │   │   ├── ncierrf.msb
│   │   │   │   ├── nlptb.msb
│   │   │   │   ├── ncxzht.msb
│   │   │   │   ├── ncrd.msb
│   │   │   │   ├── ncxro.msb
│   │   │   │   ├── ncinl.msb
│   │   │   │   ├── niqth.msb
│   │   │   │   ├── snlsf.msb
│   │   │   │   ├── ncidlus.msb
│   │   │   │   ├── nmrf.msb
│   │   │   │   ├── tnse.msb
│   │   │   │   ├── ncxru.msb
│   │   │   │   ├── nnlus.msb
│   │   │   │   ├── niqru.msb
│   │   │   │   ├── nmpdk.msb
│   │   │   │   ├── nnci.msb
│   │   │   │   ├── ncrpl.msb
│   │   │   │   ├── ncrru.msb
│   │   │   │   ├── nplth.msb
│   │   │   │   ├── ncrdk.msb
│   │   │   │   ├── nnlth.msb
│   │   │   │   ├── nnciw.msb
│   │   │   │   ├── tnpltr.msb
│   │   │   │   ├── tnlpl.msb
│   │   │   │   ├── nauki.msb
│   │   │   │   ├── ncrko.msb
│   │   │   │   ├── nmpru.msb
│   │   │   │   ├── nmrus.msb
│   │   │   │   ├── nmps.msb
│   │   │   │   ├── ncxth.msb
│   │   │   │   ├── ncre.msb
│   │   │   │   ├── nmrko.msb
│   │   │   │   ├── nlus.msb
│   │   │   │   ├── ncrnl.msb
│   │   │   │   ├── nmpth.msb
│   │   │   │   ├── tnscs.msb
│   │   │   │   ├── nnfru.msb
│   │   │   │   ├── tnple.msb
│   │   │   │   ├── nnln.msb
│   │   │   │   ├── ncxus.msb
│   │   │   │   ├── nnftr.msb
│   │   │   │   ├── ncierrko.msb
│   │   │   │   ├── ncxja.msb
│   │   │   │   ├── nnlko.msb
│   │   │   │   ├── ncrf.msb
│   │   │   │   ├── nncja.msb
│   │   │   │   ├── nncdk.msb
│   │   │   │   ├── tnplf.msb
│   │   │   │   ├── ncxf.msb
│   │   │   │   ├── ncierrja.msb
│   │   │   │   ├── nmpar.msb
│   │   │   │   ├── nncf.msb
│   │   │   │   ├── tnssk.msb
│   │   │   │   ├── gsmar.msb
│   │   │   │   ├── nmpi.msb
│   │   │   │   ├── ncierrnl.msb
│   │   │   │   ├── nnfs.msb
│   │   │   │   ├── tnplpt.msb
│   │   │   │   ├── ncierre.msb
│   │   │   │   ├── nnfsf.msb
│   │   │   │   ├── ncrth.msb
│   │   │   │   ├── ncrn.msb
│   │   │   │   ├── nnfja.msb
│   │   │   │   ├── nncro.msb
│   │   │   │   ├── nmpsk.msb
│   │   │   │   ├── ncierrzhs.msb
│   │   │   │   ├── ncierri.msb
│   │   │   │   ├── gsmja.msb
│   │   │   │   ├── tnlzhs.msb
│   │   │   │   ├── ncxel.msb
│   │   │   │   ├── nlar.msb
│   │   │   │   ├── snlnl.msb
│   │   │   │   ├── nplpl.msb
│   │   │   │   ├── tnsru.msb
│   │   │   │   ├── nltr.msb
│   │   │   │   ├── nmpsf.msb
│   │   │   │   ├── tnplcs.msb
│   │   │   │   ├── ncrcs.msb
│   │   │   │   ├── tnplzht.msb
│   │   │   │   ├── niqar.msb
│   │   │   │   ├── snlzhs.msb
│   │   │   │   ├── nplf.msb
│   │   │   │   ├── tnsus.msb
│   │   │   │   ├── tnpln.msb
│   │   │   │   ├── nplru.msb
│   │   │   │   ├── nmpko.msb
│   │   │   │   ├── niqnl.msb
│   │   │   │   ├── snlsk.msb
│   │   │   │   ├── niqdk.msb
│   │   │   │   ├── nln.msb
│   │   │   │   ├── nncsf.msb
│   │   │   │   ├── nlhu.msb
│   │   │   │   ├── nncptb.msb
│   │   │   │   ├── nmppl.msb
│   │   │   │   ├── nmpel.msb
│   │   │   │   ├── tnliw.msb
│   │   │   │   ├── gsmnl.msb
│   │   │   │   ├── nnfel.msb
│   │   │   │   ├── niqpt.msb
│   │   │   │   ├── npldk.msb
│   │   │   │   ├── snlro.msb
│   │   │   │   ├── ncija.msb
│   │   │   │   ├── nnli.msb
│   │   │   │   ├── pxus.msb
│   │   │   │   ├── nplus.msb
│   │   │   │   ├── gsmru.msb
│   │   │   │   ├── tnld.msb
│   │   │   │   ├── snlko.msb
│   │   │   │   ├── snltr.msb
│   │   │   │   ├── snlpt.msb
│   │   │   │   ├── ncierrd.msb
│   │   │   │   ├── nlja.msb
│   │   │   │   ├── niqzht.msb
│   │   │   │   ├── ncxi.msb
│   │   │   │   ├── tnsdk.msb
│   │   │   │   ├── nnfptb.msb
│   │   │   │   ├── naukf.msb
│   │   │   │   ├── ncxpl.msb
│   │   │   │   ├── nmphu.msb
│   │   │   │   ├── gsme.msb
│   │   │   │   ├── gsmtr.msb
│   │   │   │   ├── nnlsf.msb
│   │   │   │   ├── gsmhu.msb
│   │   │   │   ├── snlzht.msb
│   │   │   │   ├── gsmpt.msb
│   │   │   │   ├── ncxzhs.msb
│   │   │   │   ├── nnfiw.msb
│   │   │   │   ├── nlko.msb
│   │   │   │   ├── gsmko.msb
│   │   │   │   ├── snli.msb
│   │   │   │   ├── ncif.msb
│   │   │   │   ├── ncxko.msb
│   │   │   │   ├── naukzhs.msb
│   │   │   │   ├── gsmiw.msb
│   │   │   │   ├── ncxptb.msb
│   │   │   │   ├── tnss.msb
│   │   │   │   ├── tnlptb.msb
│   │   │   │   ├── nlsk.msb
│   │   │   │   ├── ncrs.msb
│   │   │   │   ├── nplcs.msb
│   │   │   │   ├── nmrd.msb
│   │   │   │   ├── nnfzhs.msb
│   │   │   │   ├── nncar.msb
│   │   │   │   ├── nls.msb
│   │   │   │   ├── nncel.msb
│   │   │   │   ├── nlpl.msb
│   │   │   │   ├── ncrptb.msb
│   │   │   │   ├── tnlro.msb
│   │   │   │   ├── nmptr.msb
│   │   │   │   ├── nlzht.msb
│   │   │   │   ├── npltr.msb
│   │   │   │   ├── gsmd.msb
│   │   │   │   ├── ncri.msb
│   │   │   │   ├── ncxtr.msb
│   │   │   │   ├── tnsro.msb
│   │   │   │   ├── nplel.msb
│   │   │   │   ├── nmppt.msb
│   │   │   │   ├── nlnl.msb
│   │   │   │   ├── nplpt.msb
│   │   │   │   ├── tnplth.msb
│   │   │   │   ├── nnlpl.msb
│   │   │   │   ├── nnfcs.msb
│   │   │   │   ├── gsmsf.msb
│   │   │   │   ├── snld.msb
│   │   │   │   ├── gsmpl.msb
│   │   │   │   ├── ncrpt.msb
│   │   │   │   ├── nnlru.msb
│   │   │   │   ├── tnsn.msb
│   │   │   │   ├── tnpldk.msb
│   │   │   │   ├── nlzhs.msb
│   │   │   │   ├── naukd.msb
│   │   │   │   ├── nnliw.msb
│   │   │   │   ├── ncrtr.msb
│   │   │   │   ├── tnsja.msb
│   │   │   │   ├── nnff.msb
│   │   │   │   ├── tnsd.msb
│   │   │   │   ├── nnctr.msb
│   │   │   │   ├── nldk.msb
│   │   │   │   ├── tnln.msb
│   │   │   │   ├── nnfko.msb
│   │   │   │   ├── nncnl.msb
│   │   │   │   ├── ncxsf.msb
│   │   │   │   ├── npls.msb
│   │   │   │   ├── ncxcs.msb
│   │   │   │   ├── nnfdk.msb
│   │   │   │   ├── tnltr.msb
│   │   │   │   ├── nmpf.msb
│   │   │   │   ├── tnplko.msb
│   │   │   │   ├── nliw.msb
│   │   │   │   ├── gsmzht.msb
│   │   │   │   ├── nli.msb
│   │   │   │   ├── snlptb.msb
│   │   │   │   ├── ncxpt.msb
│   │   │   │   ├── tnssf.msb
│   │   │   │   ├── niqd.msb
│   │   │   │   ├── nmpd.msb
│   │   │   │   ├── nnfpl.msb
│   │   │   │   ├── ncxnl.msb
│   │   │   │   ├── tnplzhs.msb
│   │   │   │   ├── nnld.msb
│   │   │   │   ├── tnli.msb
│   │   │   │   ├── gsmn.msb
│   │   │   │   ├── nciko.msb
│   │   │   │   ├── nplsk.msb
│   │   │   │   ├── ncrja.msb
│   │   │   │   ├── tnsiw.msb
│   │   │   │   ├── snlcs.msb
│   │   │   │   ├── gsmro.msb
│   │   │   │   ├── tnstr.msb
│   │   │   │   ├── nlel.msb
│   │   │   │   ├── nnlar.msb
│   │   │   │   ├── tnsnl.msb
│   │   │   │   ├── nnlcs.msb
│   │   │   │   ├── tnls.msb
│   │   │   │   ├── nnfzht.msb
│   │   │   │   ├── ncxdk.msb
│   │   │   │   ├── ncid.msb
│   │   │   │   ├── tnldk.msb
│   │   │   │   ├── nncd.msb
│   │   │   │   ├── nplko.msb
│   │   │   │   ├── tnlel.msb
│   │   │   │   ├── tnlja.msb
│   │   │   │   ├── tnsi.msb
│   │   │   │   ├── gsmsk.msb
│   │   │   │   ├── tnlnl.msb
│   │   │   │   ├── nnce.msb
│   │   │   │   ├── nnfro.msb
│   │   │   │   ├── tnszhs.msb
│   │   │   │   ├── tnplar.msb
│   │   │   │   ├── gsmdk.msb
│   │   │   │   ├── tnplja.msb
│   │   │   │   ├── tnplnl.msb
│   │   │   │   ├── tnplpl.msb
│   │   │   │   ├── tnplptb.msb
│   │   │   │   ├── tnplro.msb
│   │   │   │   ├── tnplsf.msb
│   │   │   │   ├── tnplus.msb
│   │   │   │   ├── tnsar.msb
│   │   │   │   ├── tnsf.msb
│   │   │   │   ├── tnsko.msb
│   │   │   │   ├── tnspt.msb
│   │   │   │   ├── tnszht.msb
│   │   │   │   ├── gsmf.msb
│   │   │   │   ├── gsmi.msb
│   │   │   │   ├── gsmptb.msb
│   │   │   │   ├── gsmth.msb
│   │   │   │   ├── gsmus.msb
│   │   │   │   ├── nauke.msb
│   │   │   │   ├── nauknl.msb
│   │   │   │   ├── naukus.msb
│   │   │   │   ├── ncie.msb
│   │   │   │   ├── ncierrus.msb
│   │   │   │   ├── ncii.msb
│   │   │   │   ├── ncizhs.msb
│   │   │   │   ├── ncrhu.msb
│   │   │   │   ├── ncriw.msb
│   │   │   │   ├── ncrsf.msb
│   │   │   │   ├── ncxe.msb
│   │   │   │   ├── ncxhu.msb
│   │   │   │   ├── ncxiw.msb
│   │   │   │   ├── ncxs.msb
│   │   │   │   ├── niqi.msb
│   │   │   │   ├── niqiw.msb
│   │   │   │   ├── niqja.msb
│   │   │   │   ├── niqptb.msb
│   │   │   │   ├── niqsk.msb
│   │   │   │   ├── niqus.msb
│   │   │   │   ├── nle.msb
│   │   │   │   ├── nlf.msb
│   │   │   │   ├── nlpt.msb
│   │   │   │   ├── nlsf.msb
│   │   │   │   ├── nmpptb.msb
│   │   │   │   ├── nmpro.msb
│   │   │   │   ├── nmpus.msb
│   │   │   │   ├── nmpzht.msb
│   │   │   │   ├── nmre.msb
│   │   │   │   ├── nmrnl.msb
│   │   │   │   ├── nmrzhs.msb
│   │   │   │   ├── nnccs.msb
│   │   │   │   ├── nncko.msb
│   │   │   │   ├── nnczhs.msb
│   │   │   │   ├── nnfar.msb
│   │   │   │   ├── nnfi.msb
│   │   │   │   ├── nnfn.msb
│   │   │   │   ├── nnfpt.msb
│   │   │   │   ├── nnfth.msb
│   │   │   │   ├── nnfus.msb
│   │   │   │   ├── nnlf.msb
│   │   │   │   ├── nnlhu.msb
│   │   │   │   ├── nnls.msb
│   │   │   │   ├── nnltr.msb
│   │   │   │   ├── nnlzhs.msb
│   │   │   │   ├── nplar.msb
│   │   │   │   ├── npld.msb
│   │   │   │   ├── nple.msb
│   │   │   │   ├── nplhu.msb
│   │   │   │   ├── nplja.msb
│   │   │   │   ├── nplptb.msb
│   │   │   │   ├── nplro.msb
│   │   │   │   ├── snlar.msb
│   │   │   │   ├── snlhu.msb
│   │   │   │   ├── snlja.msb
│   │   │   │   ├── snlru.msb
│   │   │   │   ├── snls.msb
│   │   │   │   ├── tnlar.msb
│   │   │   │   ├── tnlcs.msb
│   │   │   │   ├── tnlko.msb
│   │   │   │   ├── tnlpt.msb
│   │   │   │   ├── tnlru.msb
│   │   │   │   ├── tnlsk.msb
│   │   │   │   ├── tnlzht.msb
│   │   │   │   ├── tnpliw.msb
│   │   │   ├── admin
│   │   │   │   ├── samples
│   │   │   │   │   ├── cman.ora
│   │   │   │   ├── cman.ora
│   │   │   │   ├── cman.ora_soe_orig
│   │   ├── ldap
│   │   │   ├── admin
│   │   │   │   ├── fips.ora
│   │   ├── jlib
│   │   │   ├── cryptojce.jar
│   │   │   ├── cryptojcommon.jar
│   │   │   ├── jcmFIPS.jar
│   │   │   ├── cryptoj.jar
│   │   │   ├── oraclepki.jar
│   │   │   ├── osdt_cert.jar
│   │   │   ├── osdt_core.jar
```

### oraup.sh Output not optimal

For DB environment we have a home and a sid/process associated with it. But for
client installations we just have a home without any sid/process. For Data Safe
on Premises Connector installations we have some kind of a mix. The home is 1:1
related to an on-premises connector instance (sid/process).

Thus, in an environment where we have only Data Safe on Premises Connectors and
an Oracle Client installation, but no database installations, the `oraup.sh`
output looks like below. It is ok to report the client as available home, but the
dummy rdbms entry is not really helpful here.

Data Safe on Premises Connectors should be reported in a way like a SID/PROCESS
to see that a particular connector instance is available / running.

```text
oravw@lxf202p2076:/appl/oracle/product/23.26.0.0/iclient/ [iclient26] u
 
Oracle Environment Status
TYPE (Cluster|DG) : SID/PROCESS  STATUS      HOME
---------------------------------------------------------------------------------
 
Oracle Homes
---------------------------------------------------------------------------------
Data Safe         : dsha1        available   /appl/oracle/product/exacc-wob-vwg-ha1
Data Safe         : dsha2        available   /appl/oracle/product/exacc-wob-vwg-ha2
Data Safe         : dsha3        available   /appl/oracle/product/exacc-wob-vwg-ha3
Data Safe         : dsha4        available   /appl/oracle/product/exacc-wob-vwg-ha4
Data Safe         : dsha5        available   /appl/oracle/product/exacc-wob-vwg-ha5
Client            : iclient26    available   /appl/oracle/product/23.26.0.0/iclient
Dummy rdbms       : cli260       n/a         /appl/oracle/product/23.26.0.0/client

```

Oratab is empty and oradba_homes.conf has the following entries:

```text
 dsconha1:/appl/oracle/product/exacc-wob-vwg-ha1:datasafe:50:dsha1:DataSafe on Premises Connector ds-conn-exacc-wob-vwg-ha1:AUTO
dsconha2:/appl/oracle/product/exacc-wob-vwg-ha2:datasafe:50:dsha2:DataSafe on Premises Connector ds-conn-exacc-wob-vwg-ha2:AUTO
dsconha3:/appl/oracle/product/exacc-wob-vwg-ha3:datasafe:50:dsha3:DataSafe on Premises Connector ds-conn-exacc-wob-vwg-ha3:AUTO
dsconha4:/appl/oracle/product/exacc-wob-vwg-ha4:datasafe:50:dsha4:DataSafe on Premises Connector ds-conn-exacc-wob-vwg-ha4:AUTO
dsconha5:/appl/oracle/product/exacc-wob-vwg-ha5:datasafe:50:dsha5:DataSafe on Premises Connector ds-conn-exacc-wob-vwg-ha5:AUTO
iclient26:/appl/oracle/product/23.26.0.0/iclient:client:50:iclient26:Oracle AI Database Instant Client:AUTO
```

### Possible check for data safe on-premises connector process

below a possible check if datasafe does run for on-premises connector process

```bash
python ./setup.py status
 
CMCTL for Linux: Version 21.0.0.0.0 - Production on 15-JAN-2026 16:48:42
 
Copyright (c) 1996, 2021, Oracle.  All rights reserved.
 
Current instance cust_cman is already started
Connecting to (address_list=(address=(protocol=TCPS)(host=localhost)(port=1560)))
Services Summary...
Proxy service "cmgw" has 1 instance(s).
  Instance "cman", status READY, has 0 handler(s) for this service...
Service "cmon" has 1 instance(s).
  Instance "cman", status READY, has 1 handler(s) for this service...
    Handler(s):
      "cmon" established:2 refused:0 current:1 max:4 state:ready
         <machine: localhost, pid: 1936>
         (ADDRESS=(PROTOCOL=ipc)(KEY=#1936.1)(KEYPATH=/var/tmp/.oracle_327000))
The command completed successfully.
```

### Product Types for Clients and Instant Clients

There is no dedicated product type for Oracle Clients and Instant Clients in
oratab/oradba_homes.conf. Both are listed as `client`. It would be
beneficial to have distinct product types to differentiate between full Oracle
Client installations. In particular, Instant Clients have a different directory
structure and different components compared to full Oracle Clients.

The instant client is missing typical directories like `bin`, `lib`,
`rdbms`, `sqlplus`, `tfa`, etc. Instead, it has everything under the ORACLE_HOME
root and some specific directories like `jlib` for Java libraries.

The regular client has a simmilar installation structure as a database home, just
without the database binaries.

Validation also does not work properly for regular and instant clients as the expected directories and files are missing.

```bash
oravw@lxf202p2076:~/ [iclient26] oradba_env.sh show iclient26
=== Oracle SID Information ===
SID: iclient26
ERROR: SID 'iclient26' not found in oratab
 
oravw@lxf202p2076:~/ [iclient26] oradba_env.sh validate iclient26
=== Validating Oracle Environment ===
ORACLE_SID: not set
ORACLE_HOME: /appl/oracle/product/23.26.0.0/iclient
 
Validating Oracle environment...
Product Type: RDBMS
 
=== Basic Validation ===
✓ ORACLE_HOME is valid: /appl/oracle/product/23.26.0.0/iclient
✓ ORACLE_HOME is in PATH
 
=== Summary ===
Errors: 0, Warnings: 0
```

we once defined something like the function below but never implemented it (see doc/oradba-env-design.md)

```bash
oradba_set_iclient_environment() {
    local oracle_home="$1"
    
    # Instant Client has no bin directory, ORACLE_HOME is the lib directory
    export ORACLE_HOME="$oracle_home"
    
    # Add ORACLE_HOME to LD_LIBRARY_PATH (it IS the library directory)
    export LD_LIBRARY_PATH="${ORACLE_HOME}:${LD_LIBRARY_PATH}"
    
    # Add sqlplus to PATH if sqlplus package is installed
    if [[ -f "${ORACLE_HOME}/sqlplus" ]]; then
        export PATH="${ORACLE_HOME}:${PATH}"
    fi
    
    # Set default NLS_LANG if not set
    export NLS_LANG="${NLS_LANG:-AMERICAN_AMERICA.AL32UTF8}"
    
    # TNS_ADMIN must be set externally (no default location in IC)
    export TNS_ADMIN="${TNS_ADMIN:-${ORADBA_BASE}/network/admin}"
}
```

### PATH setup in general

There is an issue with PATH setup for data safe on-premises connectors and
clients/instant clients. First the bin path which is not valid for data safe
on-premises connectors and it is added twice. beside this we see that the jdk
path is also added twice. It it added by the oradba_custom.config file. And any
time we source an environment the jdk path is added again.

```bash
oravw@lxf202p2076:~/ [dsha1] pth
PATH Directories:
=================
 1. /appl/oracle/product/exacc-wob-vwg-ha1/bin                   [✗ not found]
 2. /appl/oracle/product/exacc-wob-vwg-ha1/bin                   [✗ not found]
 3. /appl/oracle/local/odb_datasafe/bin                          [✓]
 4. /appl/oracle/local/ocicli/bin                                [✓]
 5. /appl/oracle/local/oradba/bin                                [✓]
 6. /home/oravw/.local/bin                                       [✗ not found]
 7. /home/oravw/bin                                              [✗ not found]
 8. /usr/local/bin                                               [✓]
 9. /usr/bin                                                     [✓]
1.  /usr/local/sbin                                              [✓]
2.  /usr/sbin                                                    [✓]
3.  /appl/oracle/product/jdk/bin                                 [✓]
4.  /appl/oracle/product/jdk/bin                                 [✓]
```

after a couple of sourcings of the environment we have multiple jdk entries in PATH

```bash
oravw@lxf202p2076:/appl/oracle/local/oradba/etc/ [dsha1] dsha2
[WARN] 2026-01-15 16:13:31 - Unknown product type: unknown
[ERROR] 2026-01-15 16:13:31 - sqlplus not found in ORACLE_HOME
 
-------------------------------------------------------------------------------
ORACLE_BASE    : /appl/oracle
ORACLE_HOME    : /appl/oracle/product/exacc-wob-vwg-ha2
TNS_ADMIN      : /appl/oracle/product/23.26.0.0/client/network/admin
ORACLE_VERSION : Unknown
-------------------------------------------------------------------------------
PRODUCT_TYPE   : unknown
-------------------------------------------------------------------------------
 
oravw@lxf202p2076:/appl/oracle/local/oradba/etc/ [dsha2] pth
PATH Directories:
=================
 1. /appl/oracle/product/exacc-wob-vwg-ha2/bin                   [✗ not found]
 2. /appl/oracle/product/exacc-wob-vwg-ha2/bin                   [✗ not found]
 3. /appl/oracle/local/odb_datasafe/bin                          [✓]
 4. /appl/oracle/local/ocicli/bin                                [✓]
 5. /appl/oracle/local/oradba/bin                                [✓]
 6. /home/oravw/.local/bin                                       [✗ not found]
 7. /home/oravw/bin                                              [✗ not found]
 8. /usr/local/bin                                               [✓]
 9. /usr/bin                                                     [✓]
10. /usr/local/sbin                                              [✓]
11. /usr/sbin                                                    [✓]
12. /appl/oracle/product/jdk/bin                                 [✓]
13. /appl/oracle/product/jdk/bin                                 [✓]
14. /appl/oracle/product/jdk/bin                                 [✓]
15. /appl/oracle/product/jdk/bin                                 [✓]
16. /appl/oracle/product/jdk/bin                                 [✓]
17. /appl/oracle/product/jdk/bin                                 [✓]
18. /appl/oracle/product/jdk/bin                                 [✓]
```