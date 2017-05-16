Step 1:
Quiesce Farm with StsAdm command. 
    stsadm -o quiescefarm -maxduration 1

Step 2:
Verify Farm is Quiesced
    stsadm -o quiescefarmstatus

Step 3:
Verify or execute farm configuration only Backup

Step 4:
Shut down all SharePoint Services on each server
    Powershell script:

Step 5:
Incremental and/or Transaction Log SQL Server Backup

Step 6:
VM Snapshot

Step 7:
Perform patches and whatever

Step 8:
Reboot all servers

Step 9:
Unquiesce Farm  
    stsadm -o unquiescefarm