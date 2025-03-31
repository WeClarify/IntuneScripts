# This script modifies ownership and permissions for the "IntegratedServicesRegionPolicySet.json" file during the OOBE process 
# in Windows Autopilot. It ensures that the Administrators group has full access to the file and updates its JSON content 
# to remove "NL" from the "disabled" regions under a specific policy GUID.
#
# Purpose: This change hides the Single Sign-On (SSO) prompt, as described in the following blog:
# https://techcommunity.microsoft.com/blog/windows-itpro-blog/upcoming-changes-to-windows-single-sign-on/4008151
# 
# Configuration for Microsoft Intune:
# - Run this script using the logged on credentials: No
# - Enforce script signature check: No
# - Run script in 64 bit PowerShell Host: Yes
# www.mikevandenbrandt.nl
#

# File path
$filePath = "C:\Windows\System32\IntegratedServicesRegionPolicySet.json"

# Ensure the script is run as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    exit 1
}

# Check if the file exists
if (-not (Test-Path $filePath)) {
    Write-Host "The file does not exist at $filePath" -ForegroundColor Red
    exit 1
}

# Step 1: Change ownership to the Administrators group
Write-Host "Changing ownership to the Administrators group..." -ForegroundColor Yellow
takeown /F $filePath /A
if (-not ((Get-Acl $filePath).Owner -like "*Administrators")) {
    Write-Host "Failed to change ownership to Administrators." -ForegroundColor Red
    exit 1
}
Write-Host "Ownership successfully changed." -ForegroundColor Green

# Step 2: Grant full control to the Administrators group
Write-Host "Granting full control to the Administrators group..." -ForegroundColor Yellow
icacls $filePath /grant:r Administrators:F /T /C
$acl = Get-Acl $filePath
if (-not ($acl.Access | Where-Object { $_.IdentityReference -like "*Administrators" -and $_.FileSystemRights -eq "FullControl" })) {
    Write-Host "Failed to update permissions." -ForegroundColor Red
    exit 1
}
Write-Host "The Administrators group now has full access." -ForegroundColor Green

# Step 3: Modify the JSON content
Write-Host "Modifying the JSON content to remove 'NL' from disabled regions..." -ForegroundColor Yellow

try {
    # Read the JSON content
    $jsonContent = Get-Content -Path $filePath -Raw | ConvertFrom-Json

    # Update the content: Remove "NL" from the "disabled" list under the specific GUID
    foreach ($policy in $jsonContent.policies) {
        if ($policy.guid -eq "{1d290cdb-499c-4d42-938a-9b8dceffe998}") {
            $policy.conditions.region.disabled = $policy.conditions.region.disabled | Where-Object { $_ -ne "NL" }
            Write-Host "'NL' has been removed from the 'disabled' list for GUID: $($policy.guid)." -ForegroundColor Green
        }
    }

    # Save the modified JSON back to the file
    $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $filePath -Force -Encoding UTF8
    Write-Host "JSON modifications successfully applied and saved." -ForegroundColor Green
}
catch {
    Write-Host "Error modifying JSON: $_" -ForegroundColor Red
}
exit 0  # Success
