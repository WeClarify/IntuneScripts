$downloadUrl = "https://github.com/thebookisclosed/ViVe/releases/download/v0.3.3/ViVeTool-v0.3.3.zip"  # URL to download ViVe tool
$tempPath = "C:\Windows\Temp"
$viveToolZip = "$tempPath\ViVeTool.zip"
$viveToolDir = "$tempPath\ViVeTool"
New-Item -Path $viveToolDir -ItemType Directory -Force | Out-Null
 
$viveToolExe = "$viveToolDir\ViVeTool.exe"
$featureIds = @(47557358, 45833058)
 
 
# Ensure ViVeTool exists
if (-not (Test-Path $viveToolExe)) {
    Invoke-WebRequest -Uri $downloadUrl -OutFile "$tempPath\ViVeTool.zip"
    Expand-Archive -Path "$tempPath\ViVeTool.zip" -DestinationPath $viveToolDir -Force
    Write-host "Downloaded and extracted ViVeTool."
} else {
    Write-host "ViVeTool already exists."
}
# disable features
foreach ($featureId in $featureIds) {
    Write-host "Enabling feature with ID $featureId."
& "$viveToolDir\ViveTool.exe" /disable /id:$featureId
}
# Query status of features
foreach ($featureId in $featureIds) {  
$queryresult = & "$viveToolDir\ViveTool.exe" /query /id:$featureId  
Write-host $queryresult  
}