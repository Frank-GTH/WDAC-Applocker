<#
Name: PostESP-Script.ps1
Version: 1.2
Description:
1. Disable scheduled task runnng immedately after ESP
2. Add event 3090 to CI eventlog
3. Rename device
4. Set Applocker rules and enforcements
5. Reboot
#>

### Parameters and transcript

$tempdir = "C:\temp"
$taskdir = "C:\windows\system32\Tasks"
$proc = "SecurityHealthSystray"

New-Item $tempdir -ItemType Directory -Force -ea 0
New-Item $taskdir -ItemType File -Name ESP-TaskComplete -Force -ea 0
Start-Transcript -Path "C:\temp\ESPreboot.log" -Verbose
Write-Host "Waiting for process to start..."
start-sleep -Seconds 60 # Play with this timer to reboot immediately after end of ESP

### Functions

function MergeAppLockerPolicy([string]$policyXml) {

	Write-Host "Merging and setting AppLocker policy $policyXml"
	$policyFile = $policyXml
	[System.Int32]$tryNum = 0
	[System.Int32]$failed = 0
	do {
		$failed = 0
		try { Set-AppLockerPolicy -XmlPolicy $policyFile -Merge -ErrorAction SilentlyContinue }
		catch {
			$failed = 1
			$tryNum= $tryNum + 1
			write-host("Failed " + $tryNum.ToString())
			$exception = $_.Exception
			write-host($exception.Message.ToString())
			Start-Sleep -s 5
		}
	}
	while(($tryNum -lt 3) -and ($failed -eq 1))

	if($failed -eq 1) {
	   throw("MergeAppLockerPolicy failed 3 times")
	}

	Remove-Item $policyFile
}

# Wait for end of ESP to start rest of script
while ($true) {
    $getprocess = Get-Process $proc -ErrorAction SilentlyContinue
    if ($getprocess -ne $null) {
		$timing = get-date
        Write-Host "Desktop process $proc has started at $timing."
        break
    }
    Start-Sleep -s 3
}
# Disable scheduled task runnng this script immedately after ESP
Disable-Scheduledtask -taskname PostESP-Script -ErrorAction SilentlyContinue -Verbose
start-sleep -Seconds 1


# Enable event 3090 in CI log to show succesful ManagedInstaller checks
New-Itemproperty -path "HKLM:\SYSTEM\CurrentControlSet\Control\CI" -name "TestFlags" -Type Dword -value 0x300 -Force


## Rename computer for WDAC policies to apply to dynamic group
If ($env:computername -like "MW-*") {
	$devname = $env:computername -replace "MW-","MW1-"
	Rename-Computer -NewName $devname
	Write-Host "Computer was renamed to $devname"
}


## Import Applocker rules

# Applocker policy file EXE merge
$ApplPolicy = "c:\temp\APPL-WDAC-EXE-audit-v1.xml"
try	{ MergeAppLockerPolicy($ApplPolicy) }
catch {
	$e = $_.Exception
	Write-Error('Failed to merge AppLocker policy EXE. ' + $e.Message.ToString())
}
	
# Applocker policy file MSI merge
start-sleep -s 2
$ApplPolicy = "c:\temp\APPL-WDAC-MSI-audit-v1.xml"
try	{ MergeAppLockerPolicy($ApplPolicy) }
catch {
	$e = $_.Exception
	Write-Error('Failed to merge AppLocker policy MSI. ' + $e.Message.ToString())
}
		
# Applocker policy file SCRIPT merge
start-sleep -s 2
$ApplPolicy = "c:\temp\APPL-WDAC-SCRIPT-audit-v1.xml"
try	{ MergeAppLockerPolicy($ApplPolicy) }
catch {
	$e = $_.Exception
	Write-Error('Failed to merge AppLocker policy SCRIPT. ' + $e.Message.ToString())
}

# Applocker policy file APPX merge
start-sleep -s 2
$ApplPolicy = "c:\temp\APPL-WDAC-APPX-audit-v1.xml"
try	{ MergeAppLockerPolicy($ApplPolicy) }
catch {
	$e = $_.Exception
	Write-Error('Failed to merge AppLocker policy APPX. ' + $e.Message.ToString())
}


## Set Applocker enforcement
start-sleep -s 10

# Set Exe to Enabled and import file
$pathToFile = "c:\temp\curr1.xml"
$stringToReplace = 'Exe" EnforcementMode="AuditOnly'
$replaceWith = 'Exe" EnforcementMode="Enabled'
Get-AppLockerPolicy -Effective -Xml | % { $_ -replace $stringToReplace, $replaceWith } | Out-file $pathToFile
try	{
	Set-AppLockerPolicy -XmlPolicy $pathToFile
	Write-Host "Set Applocker EXE policy to Enabled."
}
catch {
	$e = $_.Exception
	Write-Error('Failed to set enforced AppLocker policy. ' + $e.Message.ToString())
}
Remove-Item $pathToFile

# Set Msi to Enabled and import file
start-sleep -s 2
$pathToFile = "c:\temp\curr2.xml"
$stringToReplace = 'Msi" EnforcementMode="AuditOnly'
$replaceWith = 'Msi" EnforcementMode="Enabled'
Get-AppLockerPolicy -Effective -Xml | % { $_ -replace $stringToReplace, $replaceWith } | Out-file $pathToFile
try	{
	Set-AppLockerPolicy -XmlPolicy $pathToFile
	Write-Host "Set Applocker Msi policy to Enabled."
}
catch {
	$e = $_.Exception
	Write-Error('Failed to set enforced AppLocker policy. ' + $e.Message.ToString())
}
Remove-Item $pathToFile		

# Set Script to Enabled and import file
start-sleep -s 2
$pathToFile = "c:\temp\curr3.xml"
$stringToReplace = 'Script" EnforcementMode="AuditOnly'
$replaceWith = 'Script" EnforcementMode="Enabled'
Get-AppLockerPolicy -Effective -Xml | % { $_ -replace $stringToReplace, $replaceWith } | Out-file $pathToFile
try	{
	Set-AppLockerPolicy -XmlPolicy $pathToFile
	Write-Host "Set Applocker Script policy to Enabled."
}
catch {
	$e = $_.Exception
	Write-Error('Failed to set enforced AppLocker policy. ' + $e.Message.ToString())
}
Remove-Item $pathToFile	

# Restart computer
Write-Host "ESP has ended. Restarting Workstation." -Verbose
start-sleep -Seconds 1
Restart-Computer -Force -Verbose
