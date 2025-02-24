# This script ensures that two registry values ("FarKdcTimeout" and "SpnCacheTimeout") 
# are correctly configured under the following registry path:
# "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters".
#
# Purpose:
# When using Windows Hello for Business (WHfB) with Kerberos Cloud Trust, 
# drive mappings may attempt to connect immediately after login. 
# If Global Secure Access (GSA) is not yet active, the Ticket Granting Ticket (TGT) request fails. 
# By reducing the timeout values for "FarKdcTimeout" and "SpnCacheTimeout" to 1 minute, 
# Kerberos can retry TGT requests more quickly, improving the reliability of drive mappings.
#
# Functionality:
# 1. Checks if the registry path exists:
#    - If it does not exist, the path is created.
# 2. Ensures that the "FarKdcTimeout" and "SpnCacheTimeout" values exist:
#    - If a value is missing or incorrect, it is created or updated with the correct setting.
# 3. Logs all actions performed and handles any errors.
#
# Configuration for Microsoft Intune:
# When deploying this script in Intune, ensure the following settings are configured:
# - Run this script using the logged on credentials: No
# - Enforce script signature check: No
# - Run script in 64 bit PowerShell Host: Yes
#
# Author: Mike van den Brandt
# Date: 25-01-2025

# Define the registry path and values
$RegistryPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\Kerberos\Parameters"
$RegistryValues = @{
    "FarKdcTimeout"   = 0
}

try {
    # Check if the registry path exists
    if (-not (Test-Path $RegistryPath)) {
        Write-Host "Registry path does not exist. Creating path: $RegistryPath"
        New-Item -Path $RegistryPath -Force | Out-Null
    }

    # Loop through the registry values and ensure they are set
    foreach ($Name in $RegistryValues.Keys) {
        $ExpectedValue = $RegistryValues[$Name]

        if (Get-ItemProperty -Path $RegistryPath -Name $Name -ErrorAction SilentlyContinue) {
            $CurrentValue = (Get-ItemProperty -Path $RegistryPath -Name $Name).$Name
            if ($CurrentValue -ne $ExpectedValue) {
                Write-Host "Updating $Name: Current value ($CurrentValue) does not match expected value ($ExpectedValue)."
                Set-ItemProperty -Path $RegistryPath -Name $Name -Value $ExpectedValue -Force
            } else {
                Write-Host "$Name is already set to the correct value: $ExpectedValue"
            }
        } else {
            Write-Host "$Name does not exist. Creating and setting value to $ExpectedValue."
            New-ItemProperty -Path $RegistryPath -Name $Name -Value $ExpectedValue -PropertyType DWORD -Force | Out-Null
        }
    }

    Write-Host "All registry values are correctly configured."
    Exit 0
} catch {
    Write-Error "An error occurred: $_"
    Exit 1
}
