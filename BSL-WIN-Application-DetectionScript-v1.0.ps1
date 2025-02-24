# This script is used to detect the presence or version of a registry key, file, or MSI product.
#
# Purpose:
# This script allows you to detect various types of items on a device, such as:
# - A registry key's existence and value.
# - A file's presence or specific version.
# - The installation of an MSI package based on its product code.
#
# The **$CheckType** parameter determines the type of detection method used:
# - **'RegKey'**: This checks for the existence of a specific registry key and its value. You need to specify the registry path with `$RegKeyPath` and the expected registry value with `$RegKeyName` and `$RegKeyExpectedValue`.
# - **'File'**: This checks if a specific file exists on the system. You need to specify the file path with `$FilePath`.
# - **'FileVersion'**: This checks if a specific file exists and whether its version matches the expected version. You need to specify the file path with `$FilePath` and the expected version with `$FileVersionExpected`.
# - **'MSIProductCode'**: This checks if an MSI package is installed using its product code. You need to specify the product code with `$MSIProductCode`.
#
# Example Usage:
# - **RegKey Example**: Detects if the registry key "HKLM:\SOFTWARE\MySoftware" exists and its value is "Enabled".
# - **File Example**: Detects if the file "C:\Program Files\MySoftware\MyApp.exe" exists.
# - **FileVersion Example**: Detects if "C:\Program Files\MySoftware\MyApp.exe" exists and has the version "1.0.0.0". You can use this command to read the version: 
#   ```powershell
#
#   [System.Diagnostics.FileVersionInfo]::GetVersionInfo("$ProgramPath\$ProgramFile").FileVersion
#
#   ```
# - **MSIProductCode Example**: Detects if a product with a specific MSI product code is installed. You can use this command to read the MSI product code (after install)
#
#   ```powershell
#   $Installer = New-Object -ComObject WindowsInstaller.Installer; $InstallerProducts = $Installer.ProductsEx("", "", 7); $InstalledProducts = ForEach($Product in $InstallerProducts){[PSCustomObject]@{ProductCode = $Product.ProductCode(); LocalPackage = $Product.InstallProperty("LocalPackage"); VersionString = $Product.InstallProperty("VersionString"); ProductPath = $Product.InstallProperty("ProductName")}} $InstalledProducts
#   ```
#
#
# The result of the check is written to the standard output (STDOUT). Intune will read this to determine the detection status:
# - If the detection succeeds, the script will exit with code 0 and output "Detection successful".
# - If the detection fails, the script will exit with code 1 and output "Detection failed".
#
# Author: Mike van den Brandt
# Date: 24-02-2025

# Parameters
$CheckType = "FileVersion" # Choose from 'RegKey', 'File', 'FileVersion', or 'MSIProductCode'
$RegKeyPath = "HKLM:\SOFTWARE\MySoftware" # Only relevant for RegKey
$RegKeyName = "MySetting" # Only relevant for RegKey
$RegKeyExpectedValue = "Enabled" # Only relevant for RegKey
$FilePath = "C:\Program Files\MySoftware\MyApp.exe" # Only relevant for File and FileVersion
$FileVersionExpected = "1.0.0.0" # Only relevant for FileVersion
$MSIProductCode = "{12345678-1234-1234-1234-1234567890AB}" # Only relevant for MSIProductCode

# Detection functions
function Detect-ByRegKey {
    param(
        [string]$RegKeyPath,
        [string]$RegKeyName,
        [string]$RegKeyExpectedValue
    )
    if (Test-Path $RegKeyPath) {
        $RegKeyValue = Get-ItemProperty -Path $RegKeyPath -Name $RegKeyName -ErrorAction SilentlyContinue
        if ($RegKeyValue) {
            if ($RegKeyValue.$RegKeyName -eq $RegKeyExpectedValue) {
                Write-Host "Registry key $RegKeyPath\$RegKeyName has the expected value $RegKeyExpectedValue."
                exit 0 # Success, detection successful
            } else {
                Write-Host "Registry key $RegKeyPath\$RegKeyName exists, but value is $($RegKeyValue.$RegKeyName), expected $RegKeyExpectedValue."
                exit 1 # Failure, detection failed
            }
        } else {
            Write-Host "Registry key $RegKeyPath\$RegKeyName not found."
            exit 1 # Failure, detection failed
        }
    } else {
        Write-Host "Registry path $RegKeyPath not found."
        exit 1 # Failure, detection failed
    }
}

function Detect-ByFile {
    param(
        [string]$FilePath
    )
    if (Test-Path $FilePath) {
        Write-Host "File $FilePath found."
        exit 0 # Success, detection successful
    } else {
        Write-Host "File $FilePath not found."
        exit 1 # Failure, detection failed
    }
}

function Detect-ByFileVersion {
    param(
        [string]$FilePath,
        [string]$ExpectedVersion
    )
    if (Test-Path $FilePath) {
        $fileVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FilePath).FileVersion
        if ($fileVersion -eq $ExpectedVersion) {
            Write-Host "File $FilePath has the expected version $ExpectedVersion."
            exit 0 # Success, detection successful
        } else {
            Write-Host "File $FilePath has version $fileVersion, but expected $ExpectedVersion."
            exit 1 # Failure, detection failed
        }
    } else {
        Write-Host "File $FilePath not found."
        exit 1 # Failure, detection failed
    }
}

function Detect-ByMSIProductCode {
    param(
        [string]$MSIProductCode
    )
    $installed = Get-WmiObject -Class Win32_Product | Where-Object {$_.IdentifyingNumber -eq $MSIProductCode}
    if ($installed) {
        Write-Host "MSI product with code $MSIProductCode found."
        exit 0 # Success, detection successful
    } else {
        Write-Host "MSI product with code $MSIProductCode not found."
        exit 1 # Failure, detection failed
    }
}

# Detection based on selected method
switch ($CheckType) {
    'RegKey' {
        Detect-ByRegKey -RegKeyPath $RegKeyPath -RegKeyName $RegKeyName -RegKeyExpectedValue $RegKeyExpectedValue
    }
    'File' {
        Detect-ByFile -FilePath $FilePath
    }
    'FileVersion' {
        Detect-ByFileVersion -FilePath $FilePath -ExpectedVersion $FileVersionExpected
    }
    'MSIProductCode' {
        Detect-ByMSIProductCode -MSIProductCode $MSIProductCode
    }
    default {
        Write-Host "Unknown detection option: $CheckType"
        exit 1 # Failure, detection failed
    }
}
