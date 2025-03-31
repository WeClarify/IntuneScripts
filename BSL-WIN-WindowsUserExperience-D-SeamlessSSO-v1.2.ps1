# File path
$filePath = "C:\Windows\System32\IntegratedServicesRegionPolicySet.json"

# Ensure the script is run as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script must be run as Administrator." -ForegroundColor Red
    exit 0
}

# Check if the file exists
if (-not (Test-Path $filePath)) {
    Write-Host "The file does not exist at $filePath" -ForegroundColor Yellow
    exit 0
}

# Step 1: Change ownership to the Administrators group
Write-Host "Changing ownership to the Administrators group..." -ForegroundColor Yellow
try {
    takeown /F $filePath /A | Out-Null
    Write-Host "Ownership successfully changed." -ForegroundColor Green
} catch {
    Write-Host "Failed to change ownership: $_" -ForegroundColor Red
}

# Step 2: Grant full control to the Administrators group
Write-Host "Granting full control to the Administrators group..." -ForegroundColor Yellow
try {
    icacls $filePath /grant:r Administrators:F /T /C | Out-Null
    Write-Host "The Administrators group now has full access." -ForegroundColor Green
} catch {
    Write-Host "Failed to update permissions: $_" -ForegroundColor Red
}

# Step 3: Modify the JSON content
Write-Host "Modifying the JSON content to remove 'NL' from disabled regions..." -ForegroundColor Yellow
try {
    $jsonContent = Get-Content -Path $filePath -Raw | ConvertFrom-Json
    foreach ($policy in $jsonContent.policies) {
        if ($policy.guid -eq "{1d290cdb-499c-4d42-938a-9b8dceffe998}") {
            $policy.conditions.region.disabled = $policy.conditions.region.disabled | Where-Object { $_ -ne "NL" }
            Write-Host "'NL' has been removed from the 'disabled' list for GUID: $($policy.guid)." -ForegroundColor Green
        }
    }
    $jsonContent | ConvertTo-Json -Depth 10 | Set-Content -Path $filePath -Force -Encoding UTF8
    Write-Host "JSON modifications successfully applied and saved." -ForegroundColor Green
} catch {
    Write-Host "Error modifying JSON: $_" -ForegroundColor Red
}

Write-Host "Script execution completed successfully." -ForegroundColor Green
exit 0
