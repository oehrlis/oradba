## Real-World Installation Context

Current installation setup:
- **5 Data Safe on-premises connectors** (all running)
- **1 Oracle Instant Client**
- **No full client or Oracle database**
- **oratab should be empty**

### Current Registered Homes

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

### Current Output (Incorrect)

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

### Expected Output (Correct)

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

## General Requirements for oraup.sh Update

1. **Use oratab as primary reference but work without it** - Must function using only `oradba_homes.conf` when oratab is empty
2. **Show all available homes** - Display homes from both oratab and oradba_homes.conf
3. **Dynamic status sections** - Only show sections when relevant:
   - **Oracle Homes** (always shown when homes exist)
   - **Database Instances** (only when RDBMS homes or oratab entries exist)
   - **Listener Status** (only when listener.ora or tnslsnr process for RDBMS homes exists)
   - **Data Safe Status** (only when datasafe homes exist, showing connection manager processes with ports)
   - **OUD Status** (only when OUD homes exist)
   - **WLS Status** (only when WebLogic homes exist)
4. **Fix Data Safe status implementation** - Show connection manager details with port information
5. **Fix home status display** - Show single valid status (unknown/missing/available), not concatenated states like "unknownavailable"
6. **Include Instant Client** - Display instant client homes in the Oracle Homes section