# SPDX-License-Identifier: GPL-2.0-or-later
# Packaging script for shadPS4 Xbox UWP

param (
    [string]$BuildDir = "build",
    [string]$OutputDir = "bin/uwp",
    [string]$Config = "Release"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Packaging shadPS4 for Xbox One X (UWP) ===" -ForegroundColor Cyan

# 1. Locate Windows SDK Tools (MakeAppx and SignTool)
$sdkPath = (Get-Item "C:\Program Files (x86)\Windows Kits\10\bin\10.*").FullName | Sort-Object -Descending | Select-Object -First 1
if (-not $sdkPath) {
    throw "Windows 10/11 SDK not found!"
}
$makeAppx = Join-Path $sdkPath "x64\MakeAppx.exe"
$signTool = Join-Path $sdkPath "x64\SignTool.exe"

Write-Host "Found SDK tools at: $sdkPath" -ForegroundColor Green

# 2. Setup Staging Directory
$stagingDir = Join-Path $OutputDir "staging"
if (Test-Path $stagingDir) {
    Remove-Item -Recurse -Force $stagingDir
}
New-Item -ItemType Directory -Force -Path $stagingDir | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $stagingDir "Assets") | Out-Null

# 3. Copy Executable and Dependencies
$exePath = Join-Path $BuildDir "shadps4.exe"
if (-not (Test-Path $exePath)) {
    # Check if under Release folder
    $exePath = Join-Path $BuildDir "$Config\shadps4.exe"
}

if (-not (Test-Path $exePath)) {
    throw "shadps4.exe not found in $BuildDir"
}

Write-Host "Copying binaries from: $exePath" -ForegroundColor Green
Copy-Item $exePath -Destination $stagingDir

# Copy any runtime DLLs if present
Get-ChildItem -Path $BuildDir -Filter "*.dll" -Recurse | ForEach-Object {
    Copy-Item $_.FullName -Destination $stagingDir -Force
}

# 4. Copy Assets and Manifest
Copy-Item "uwp\Package.appxmanifest" -Destination $stagingDir
Copy-Item "uwp\Assets\*" -Destination (Join-Path $stagingDir "Assets") -Recurse

# 5. Pack with MakeAppx
$packageFile = Join-Path $OutputDir "shadps4-xbox-x64.msix"
if (Test-Path $packageFile) {
    Remove-Item -Force $packageFile
}

Write-Host "Packing MSIX package: $packageFile" -ForegroundColor Cyan
& $makeAppx pack /d $stagingDir /p $packageFile /nv
if ($LASTEXITCODE -ne 0) {
    throw "MakeAppx failed with exit code $LASTEXITCODE"
}

# 6. Generate Self-Signed Certificate and Sign
$certSubject = "CN=shadPS4Dev"
$certPassword = ConvertTo-SecureString "shadps4" -AsPlainText -Force
$pfxFile = Join-Path $OutputDir "shadps4-dev.pfx"
$cerFile = Join-Path $OutputDir "shadps4-dev.cer"

Write-Host "Generating self-signed certificate for signing..." -ForegroundColor Cyan
$cert = New-SelfSignedCertificate -Type Custom `
    -Subject $certSubject `
    -KeyUsage DigitalSignature `
    -FriendlyName "shadPS4 Xbox Certificate" `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -KeyExportPolicy Exportable

Export-PfxCertificate -Cert $cert -FilePath $pfxFile -Password $certPassword | Out-Null
Export-Certificate -Cert $cert -FilePath $cerFile | Out-Null

Write-Host "Signing package with SignTool..." -ForegroundColor Cyan
& $signTool sign /fd SHA256 /a /f $pfxFile /p "shadps4" $packageFile
if ($LASTEXITCODE -ne 0) {
    throw "SignTool failed with exit code $LASTEXITCODE"
}

Write-Host "=== SUCCESS: Packaged and signed successfully! ===" -ForegroundColor Green
Write-Host "Package file: $packageFile" -ForegroundColor Green
Write-Host "Certificate file (install this on Xbox): $cerFile" -ForegroundColor Green
