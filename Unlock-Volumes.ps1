#Script to prompt user for a password used by the protector of the same name on bitlocker volumes, and unlock them
#This is for unlocking drives on a server that may not have TPM functionality, and many drives.

#Bitlocker info and volume state info in this var
$BitlockerVolume = get-bitlockervolume

#troubleshooting vars
$PhysicalDrives = Get-PSDrive -PSProvider FileSystem
$PhysicalDrivesCount = $PhysicalDrives.count

Write-Output $PhysicalDrives
Write-Output $PhysicalDrivesCount

$pwd = Read-Host "Please Enter the Key" -AsSecureString

foreach($Volume in $BitlockerVolume)
{
	if($Volume.LockStatus -eq "Locked")
	{
		try
		{
			#In some circumstances, a drive may not have a mountpoint in windows.
			#This cmdlet requires a -MountPoint parameter to function, so this may not work if that is the case
			#It may be possible to pass the NTFS path to unlock-bitlocker
			Unlock-Bitlocker -MountPoint $Volume.MountPoint -Password $pwd #-WhatIf
		}
		catch
		{
			Write-Output "Unlock-Bitlocker Failed, Continuing..."
			Write-Output $_
		}
	}
	elseif($Volume.LockStatus -ne "Locked")
	{
		echo $Volume
	}
	else
	{
		echo "$Volume.LockStatus not detected."
		echo $Volume | Format-List
	}
}
$BitlockerVolume = get-bitlockervolume
$BitlockerVolume | select-object -property *
$PlaceHolder = Read-Host "Press any key to continue..."