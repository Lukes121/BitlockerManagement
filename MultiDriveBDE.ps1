$BitlockerVolumes = Get-BitlockerVolume
$PhysicalDrives = Get-PSDrive -PSProvider FileSystem
$PhysicalDrivesCount = $PhysicalDrives.count

#info out for testing purposes
Write-Output $PhysicalDrivesCount
Write-Output $PhysicalDrives

foreach ($Volume in $BitlockerVolumes)
{
	Write-Output $Volume.MountPoint, $Volume.VolumeType
	$ProtectorCount = $Volume.KeyProtector.count
	$HasRecoveryPassword = $false
	$RecoveryPasswordIndex = 0
	$RecoverypasswordCount = 0
	
	#making sure there's only one recoverypassword, and that it's only on the OS volume
	
	if ($protectorCount -ne 0)
	{
		
		$proArr = @()
		for (($i = 0); $i -lt $ProtectorCount; $i++)
		{
			$proArr += $Volume.KeyProtector[$i]
		}
		for (($i = 0); $i -lt $proArr.count; $i++)
		{
			if ($proArr[$i].KeyProtectorType -eq "RecoveryPassword")
			{
				$RecoveryPasswordCount++
				if($RecoverypasswordCount -gt 1)
				{
					manage-bde -protectors -delete $Volume.MountPoint -id $Volume.KeyProtector[$i].KeyProtectorID
				}
				else
				{
					$HasRecoveryPassword = $true
					$RecoveryPasswordIndex = $i
				}
			}
			if ($proArr[$i] -eq "TPMAndPin")
			{
				manage-bde -protectors -delete $Volume.MountPoint -id $Volume.KeyProtector[$i].KeyProtectorID
			}
		}
	}
	if ($Volume.VolumeType -eq "OperatingSystem")
	{
		manage-bde -protectors -add $Volume.MountPoint -tpm
	}
	#clearing any protectors to ensure drives cannot lock that we cannot control or don't want to
	if ($Volume.VolumeType -ne "OperatingSystem")
	{
		manage-bde -protectors -delete $Volume.MountPoint
		manage-bde -autounlock $Volume.MountPoint -enable
	}
	
	if ($HasRecoveryPassword)
	{
		manage-bde -protectors $Volume.MountPoint -aadbackup -id $Volume.KeyProtector[$RecoveryPasswordIndex].KeyProtectorID
		Write-Output "AADBackup Reached HadRecoveryPassword"
	}
	elseif (!($HasRecoveryPassword) -and $Volume.VolumeType -eq "OperatingSystem")
	{
		manage-bde -protectors -add $Volume.MountPoint -recoverypassword
		Write-Output "AADBackup Reached !(HasRecoveryPassword) & VolumeType OS"
		#this may need to be changed to a for loop and iterate over the keyprotectors byt count instead of by enum
		foreach ($protector in $Volume.Keyprotector)
		{
			if ($protector.KeyProtectorType -eq "RecoveryPassword")
			{
				manage-bde -protectors $Volume.MountPoint -aadbackup -id $protector.KeyProtectorID
			}
		}
	}
	
	Write-Output $Volume
	manage-bde -on $Volume.MountPoint -s -used
}
