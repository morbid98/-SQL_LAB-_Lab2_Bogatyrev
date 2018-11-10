$cred=Get-Credential -Message "SQL Credentials"
$cred2=Get-Credential -Message "Win Credentials"
$srvname="10.0.0.2"
if($connect_err){
                 Write-Warning -message "Check your credentials or connection to the server"}
$ErrorActionPreference = "Stop"  
Invoke-Sqlcmd -Credential $cred -ServerInstance $srvname -Query "
SELECT name, physical_name AS CurrentLocation  
FROM sys.master_files  
WHERE database_id = DB_ID(N'tempdb');  
GO " -ErrorVariable connect_err
Invoke-Command -ComputerName $srvname -Credential $cred2 -ErrorVariable connect_err -ScriptBlock {get-childitem E:/SQLTemp|
                                                                       foreach {
                                                                                if ($_.FullName -like "*temp*"){
                                                                                                                Write-Error -Message "TempDB files already exist,use another location or delete the files"  -ErrorAction Stop
                                                                                                                Exit-PSSession;
                                                                                                               }
                                                                                                                                                        
                                                                                }
                                                                       }
                                                                        
Invoke-Sqlcmd -Credential $cred -ServerInstance $srvname -Query "
USE master;  
GO  
ALTER DATABASE tempdb   
MODIFY FILE (NAME = tempdev, FILENAME = 'E:\SQLTemp\tempdb.mdf',size=10MB,filegrowth=5MB,maxsize='unlimited');  
GO  
ALTER DATABASE tempdb   
MODIFY FILE (NAME = templog, FILENAME = 'E:\SQLTemp\templog.ldf',size=10MB,filegrowth=1MB,maxsize='unlimited');  
GO" -ErrorVariable connect_err
Invoke-Command -ComputerName $srvname -Credential $cred2 -ScriptBlock {Restart-Service -Name *mssql*}
Invoke-Sqlcmd -Credential $cred -ServerInstance $srvname -Query "
SELECT name, physical_name AS CurrentLocation  
FROM sys.master_files  
WHERE database_id = DB_ID(N'tempdb');  
GO " -ErrorVariable connect_err
Invoke-Command -Credential $cred2 -ComputerName $srvname -ScriptBlock {Get-PSDrive E|Select-Object @{name='FreeSpace(GB)';expression={$_.free/1gb}}}
