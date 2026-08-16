[CmdletBinding()]
param(
    [string]$Alias = "comprezza-upload",
    [string]$KeyDirectory = ""
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$androidDirectory = Join-Path $projectRoot "android"

if ([string]::IsNullOrWhiteSpace($KeyDirectory)) {
    $projectParent = Split-Path -Parent $projectRoot
    $KeyDirectory = Join-Path $projectParent "ComprezzaKeys"
}

$keystorePath = Join-Path $KeyDirectory "comprezza-upload-keystore.jks"
$keyPropertiesPath = Join-Path $androidDirectory "key.properties"
$keytoolCommand = Get-Command keytool.exe -ErrorAction SilentlyContinue

if ($null -eq $keytoolCommand) {
    $keytoolCommand = Get-Command keytool -ErrorAction SilentlyContinue
}

if ($null -eq $keytoolCommand) {
    throw "keytool was not found. Install/configure JDK 17 and ensure its bin directory is on PATH."
}

if (Test-Path $keyPropertiesPath) {
    throw "${keyPropertiesPath} already exists. Refusing to overwrite signing configuration."
}

if (Test-Path $keystorePath) {
    throw "${keystorePath} already exists. Refusing to overwrite an existing upload keystore."
}

New-Item -ItemType Directory -Force -Path $KeyDirectory | Out-Null

function Read-SigningPassword([string]$Prompt) {
    $secureValue = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureValue)
    try {
        $plainValue = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }

    if ($plainValue.Length -lt 12 -or $plainValue -notmatch "^[A-Za-z0-9]+$") {
        throw "Passwords must contain at least 12 letters or numbers only so key.properties remains unambiguous."
    }

    return $plainValue
}

$storePassword = Read-SigningPassword "Create a keystore password (12+ letters/numbers)"
$keyPassword = Read-SigningPassword "Create a key password (12+ letters/numbers)"

try {
    & $keytoolCommand.Source `
        -genkeypair `
        -v `
        -keystore $keystorePath `
        -storetype JKS `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -alias $Alias `
        -storepass $storePassword `
        -keypass $keyPassword `
        -dname "CN=Comprezza Upload, OU=Dzynova Technologies, O=Dzynova Technologies, L=Unknown, ST=Unknown, C=US"

    if ($LASTEXITCODE -ne 0) {
        throw "keytool failed with exit code $LASTEXITCODE."
    }

    $properties = @(
        "storePassword=$storePassword"
        "keyPassword=$keyPassword"
        "keyAlias=$Alias"
        "storeFile=$($keystorePath.Replace('\', '/'))"
    )
    Set-Content -Path $keyPropertiesPath -Value $properties -Encoding ascii -NoNewline
}
catch {
    if (Test-Path $keystorePath) {
        Remove-Item -Force $keystorePath
    }
    if (Test-Path $keyPropertiesPath) {
        Remove-Item -Force $keyPropertiesPath
    }
    throw
}
finally {
    $storePassword = $null
    $keyPassword = $null
}

Write-Host ""
Write-Host "Release signing is configured." -ForegroundColor Green
Write-Host "Keystore: $keystorePath"
Write-Host "Properties: $keyPropertiesPath"
Write-Host ""
Write-Host "Now run from the project root:"
Write-Host "  flutter clean"
Write-Host "  flutter pub get"
Write-Host "  flutter build apk --release"
Write-Host ""
Write-Host "Back up the keystore and passwords securely. Never commit either one."
