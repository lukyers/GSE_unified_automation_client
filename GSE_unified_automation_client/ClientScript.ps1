Invoke-Expression .\logo.ps1

$timestamp = Get-Date -Format yyyyMMddHHmmss
$Logfile = "log-$timestamp.txt"

function LogWrite($loglevel,$logstring)
{
   $timestamp = Get-Date -Format yyyy:MM:dd:HH:mm:ss:fff
   Add-content $Logfile -value "$timestamp - $logstring"
   if ($loglevel -eq "DEBUG"){ Write-Host "`t`t$logstring`n" -ForegroundColor "gray"}
   elseif ($loglevel -eq "INFO"){ Write-Host "`t`t$logstring`n" -ForegroundColor "green"}
   elseif ($loglevel -eq "ERROR"){ Write-Host "`t`t$logstring`n" -ForegroundColor "red" }
}

function SetEnvironmetVariable($EnvPathName,$EnvPathValue,$Vals)
{
    $ValToSet = ""

    if ($EnvPathValue) 
    {
        foreach ($Val in $Vals)
        {        
            $tmpVal = $Val -replace "\\","\\"
            $tmpVal = $tmpVal -replace "\(","\("
            $tmpVal = $tmpVal -replace "\)","\)"
            if ($EnvPathValue -cmatch $tmpVal) { }
            else { $ValToSet += $Val }
         }

         if ($ValToSet) 
         { 
            setx $EnvPathName "$EnvPathValue;$ValToSet" /M | Out-Null
         }
    }
    else 
    {
        foreach ($Val in $Vals){$ValToSet += $Val}
        setx $EnvPathName "$ValToSet" /M | Out-Null
    }
}

#Running commands to enable remote command execution

LogWrite "DEBUG" "Enabling permissions to execute command on remote server"
Enable-PSRemoting -Force | Out-Null
Set-Item wsman:\localhost\client\trustedhosts * -Force | Out-Null
Restart-Service WinRM | Out-Null

#Fetch the config.ini to update the configuration
$IniFile_NME = ".\config.ini"
$config = @{}

Get-Content $IniFile_NME | foreach {
    $line = $_.split("=")
    $config.($line[0]) = $line[1]
}

$RemoteHost = $config.("RemoteHost")
$RemoteSoftwareRepo = $config.("RemoteSoftwareRepo")
$username = $config.("Username")
$password = $config.("password")
$RemoteSoftwareRepoPath = $RemoteSoftwareRepo + "\"

#$RemoteHost = "10.102.6.183"
#$RemoteSoftwareRepo = "\\$RemoteHost\Softwares"
$RemoteScriptFile = "RemoteScript.ps1"
$CodeBase = "eda/qa_automation.git"
$DestDirectory = "C:\DLL"
#$username = "Administrator"
#$password = "Password123!"

LogWrite "DEBUG" "Adding Network Shared Folder to local machine"
net use $RemoteSoftwareRepo $password /USER:$username /PERSISTENT:NO | Out-Null

$RemoteSoftwareRepoPath = $RemoteSoftwareRepo + "\"

#fetching credential for remote build server
$npassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $username , $npassword

#Execute script on remote build server

Copy-Item -Path "$RemoteSoftwareRepoPath$RemoteScriptFile " -Destination .\ -Recurse -Force | Out-Null
LogWrite "DEBUG" "Invoking Script on Remote Build Server"
$return = Invoke-Command -ComputerName $RemoteHost -Credential $credentials -FilePath $RemoteScriptFile -ArgumentList $CodeBase
Remove-Item $RemoteScriptFile -Force | Out-Null

if ($return -And ($return -ne $false))
{
    #Copy the DLL to local client machine
    LogWrite "DEBUG" "Copying DLL file to : $DestDirectory"
    $repo_name_git = $CodeBase -split "/"
    $repo_name = $repo_name_git[-1] -split "\."
    $RepoFolderName = $repo_name[0]
    $FileToCopy = "$RemoteSoftwareRepoPath"+"$RepoFolderName\PST_Exporter_Automation\PST_Exporter_Automation\bin\Debug\PST_Exporter_Automation.dll"
    New-Item -ItemType Directory -Force -Path $DestDirectory | Out-Null
    Copy-Item -Path $FileToCopy -Destination $DestDirectory -Recurse -Force | Out-Null

    LogWrite "DEBUG" "Adding DLL Directory - $DestDirectory to IRONPYTHONPATH"
    SetEnvironmetVariable "IRONPYTHONPATH" $env:IRONPYTHONPATH $DestDirectory";"
}
else { LogWrite "ERROR" "Error in invoking remote script"}

LogWrite "DEBUG" "Removing Network Shared Folder from local machine`n"
net use $RemoteSoftwareRepo /DELETE | Out-Null

Write-Host "`n*******************************************************************`n"
Write-Host "`nOutput Log File : $pwd\$Logfile`n"
Write-Host "`n*******************************************************************`n"