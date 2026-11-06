# Variable specifies the disk drive to extend
$drive_letter = "C"

# Script gets the partition sizes, and resizes the volume
$size = (Get-PartitionSupportedSize -DriveLetter $drive_letter)
Resize-Partition -DriveLetter $drive_letter -Size $size.SizeMax


Get-Disk
$disknumber = ''
Set-Disk -Number 2 -IsOffline $False
Initialize-Disk $disknumber
New-Partition -DiskNumber $disknumber -AssignDriveLetter –UseMaximumSize
Format-Volume –DriveLetter E -FileSystem NTFS