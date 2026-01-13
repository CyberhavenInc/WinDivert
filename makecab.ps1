# Prepare a cab file with the driver for signing by Microsoft
# This is required for new installations of Windows 10 > 1607 with Secure Boot
# https://blogs.msdn.microsoft.com/windows_hardware_certification/2016/07/26/driver-signing-changes-in-windows-10-version-1607/
# The output cab file needs to be uploaded to the Hardware Developer portal: https://sysdev.microsoft.com/hardware
# Use the cyberhaven.eu login to access it

[CmdletBinding()]
param
(
    [Parameter(Mandatory=$true)] [string] $RepositoryPath,
    [Parameter(Mandatory=$true)] [string] $TargetPath,
    [Parameter(Mandatory=$true)] [string] $Build,
    [Parameter(Mandatory=$false)] [string] $Configuration
)

. ".\Signing\SigningUtils.ps1"

$ddf = @"
;* cyberhaven.ddf example
;
.OPTION EXPLICIT     ; Generate errors
.Set CabinetFileCountThreshold=0
.Set FolderFileCountThreshold=0
.Set FolderSizeThreshold=0
.Set MaxCabinetSize=0
.Set MaxDiskFileCount=0
.Set MaxDiskSize=0
.Set CompressionType=MSZIP
.Set Cabinet=on
.Set Compress=on
;Specify file name for new cab file
.Set CabinetNameTemplate=CyberhavenWindivertDriver-$Build.cab
.Set DestinationDir=Cyberhaven
;Specify files to be included in cab file
Windivert64.sys
Windivert64.inf
Windivert64.pdb
"@

if ($PSBoundParameters.ContainsKey('Configuration')) {
    $TargetName = $Configuration
} else {
    $TargetName = "Release"
}

$DriverPath = "$RepositoryPath\install\MSVC\$Build\"

if ((Test-Path -LiteralPath "$DriverPath\Windivert64.sys" -PathType Leaf) -eq $False) {
    throw "Driver sys file does not exist at $DriverPath"
}

if ((Test-Path -LiteralPath "$DriverPath\Windivert64.inf" -PathType Leaf) -eq $False) {
    throw "Driver inf file does not exist at $DriverPath"
}

if ((Test-Path -LiteralPath "$DriverPath\Windivert64.pdb" -PathType Leaf) -eq $False) {
    throw "Driver pdb file does not exist at $DriverPath"
}

if ((Test-Path -LiteralPath $TargetPath -PathType Container) -eq $False) {
    Write-Output "Target directory does not exist, will create it"
    New-Item -Path $TargetPath -ItemType Directory
}

$ddf | Out-File -Encoding ascii -FilePath "$TargetPath\cyberhaven.ddf"
Copy-Item "$DriverPath\Windivert64.sys" "$TargetPath"
Copy-Item "$DriverPath\Windivert64.inf" "$TargetPath"
Copy-Item "$DriverPath\Windivert64.pdb" "$TargetPath"

cd $TargetPath
cmd /c makecab /f "cyberhaven.ddf"
SignUnsigned -filename "disk1\CyberhavenWindivertDriver-$Build.cab"

# Go back up to not lock the current directory for the parent script.
cd ..

Write-Output "Done. Upload disk1\CyberhavenDriver-$Build.cab to https://developer.microsoft.com/en-us/dashboard/hardware/"