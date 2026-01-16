## Additional Real-World Installation Context

### Current Setup
- 5 Data Safe on-premises connectors (all running)
- 1 Oracle Instant Client
- No full client or Oracle database
- oratab should be empty/not applicable

### Registered Oracle Homes Output
```
oradba_homes.sh list

Registered Oracle Homes
================================================================================
NAME            TYPE         STATUS       DESCRIPTION
--------------------------------------------------------------------------------
dsconha1        datasafe     available    [alias: dsha1] DataSafe
dsconha2        datasafe     available    [alias: dsha2] DataSafe
dsconha3        datasafe     available    [alias: dsha3] DataSafe
dsconha4        datasafe     available    [alias: dsha4] DataSafe
dsconha5        datasafe     available    [alias: dsha5] DataSafe
iclient26       iclient      available    Oracle
```

### Current oraup.sh Output (Incorrect)
```
Oracle Environment Status
TYPE (Cluster|DG) : SID/PROCESS  STATUS      HOME
---------------------------------------------------------------------------------

Oracle Homes
---------------------------------------------------------------------------------
Data Safe         : dsconha1     unknownavailable /appl/oracle/product/exacc-wob-vwg-ha1
Data Safe         : dsconha2     unknownavailable /appl/oracle/product/exacc-wob-vwg-ha2
Data Safe         : dsconha3     unknownavailable /appl/oracle/product/exacc-wob-vwg-ha3
Data Safe         : dsconha4     unknownavailable /appl/oracle/product/exacc-wob-vwg-ha4
Data Safe         : dsconha5     unknownavailable /appl/oracle/product/exacc-wob-vwg-ha5

Database Instances
---------------------------------------------------------------------------------
DB-instance (N)   : dummy        down        /appl/oracle/product/dummy

Listener Status
---------------------------------------------------------------------------------
Listener          : LISTENER     up          (running)
```

### Expected oraup.sh Output
```
Oracle Environment Status
TYPE (Cluster|DG) : SID/PROCESS  STATUS      HOME/BASE
---------------------------------------------------------------------------------

Oracle Homes
---------------------------------------------------------------------------------
Data Safe          : dsconha1     available   /appl/oracle/product/exacc-wob-vwg-ha1
Data Safe          : dsconha2     available   /appl/oracle/product/exacc-wob-vwg-ha2
Data Safe          : dsconha3     available   /appl/oracle/product/exacc-wob-vwg-ha3
Data Safe          : dsconha4     available   /appl/oracle/product/exacc-wob-vwg-ha4
Data Safe          : dsconha5     available   /appl/oracle/product/exacc-wob-vwg-ha5
Instant Client     : iclient26    available   /appl/oracle/product/23.26.0.0/iclient

Data Safe Status
---------------------------------------------------------------------------------
Connection Manager : dsconha1     up (1561)   /appl/oracle/product/exacc-wob-vwg-ha1/oracle_cman_home
Connection Manager : dsconha2     up (1562)   /appl/oracle/product/exacc-wob-vwg-ha2/oracle_cman_home
Connection Manager : dsconha3     up (1563)   /appl/oracle/product/exacc-wob-vwg-ha3/oracle_cman_home
Connection Manager : dsconha4     up (1564)   /appl/oracle/product/exacc-wob-vwg-ha4/oracle_cman_home
Connection Manager : dsconha5     up (1565)   /appl/oracle/product/exacc-wob-vwg-ha5/oracle_cman_home
```

### General Requirements for oraup.sh Improvements

1. **Use oratab as primary reference but work without it**: The script must function when oratab is empty or doesn't exist, using only `oradba_homes.conf`
2. **Show all available homes**: Include all product types (RDBMS, Data Safe, Instant Client, OUD, WLS, etc.)
3. **Dynamic sections based on availability**: Only show relevant sections:
   - Database Instances (when databases exist)
   - Listener Status (when RDBMS listeners are present)
   - Data Safe Status (when Data Safe homes exist)
   - OUD Status (when OUD instances exist)
   - WLS Status (when WebLogic instances exist)
4. **Fix and implement Data Safe Status section**:
   - Show connection manager process status
   - Display port number
   - Show actual oracle_cman_home path (not just install base)