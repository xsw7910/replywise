param(
    [switch]$Clean,
    [string]$ReplyBackendBaseUrl = "https://replace-with-production-backend.example",
    [string]$ReplyEnv = "production",
    [string]$RevenueCatAndroidApiKey = "REPLACE_WITH_REVENUECAT_ANDROID_API_KEY",
    [string]$RevenueCatEntitlementId = "REPLACE_WITH_REVENUECAT_ENTITLEMENT_ID"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $PSScriptRoot
$AppRoot = Join-Path $RepoRoot "app"

function Write-Section {
    param([Parameter(Mandatory)][string]$Title)
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

function Invoke-Flutter {
    param([Parameter(Mandatory)][string[]]$Arguments)
    & flutter @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "flutter failed with exit code $LASTEXITCODE."
    }
}

Write-Host "ReplyWise Android release build" -ForegroundColor Green
Write-Host "Repository: $RepoRoot"

Push-Location $AppRoot
try {
    if ($Clean) {
        Write-Section "Flutter clean"
        Invoke-Flutter @("clean")
    }

    Write-Section "Flutter dependencies"
    Invoke-Flutter @("pub", "get")

    Write-Section "Building release app bundle"
    $BuildArguments = @(
        "build",
        "appbundle",
        "--release",
        "--dart-define=REPLY_BACKEND_BASE_URL=$ReplyBackendBaseUrl",
        "--dart-define=REPLY_ENV=$ReplyEnv",
        "--dart-define=REVENUECAT_ANDROID_API_KEY=$RevenueCatAndroidApiKey",
        "--dart-define=REVENUECAT_ENTITLEMENT_ID=$RevenueCatEntitlementId"
    )
    Invoke-Flutter $BuildArguments
}
finally {
    Pop-Location
}

$AabPath = Join-Path $AppRoot "build\app\outputs\bundle\release\app-release.aab"
Write-Section "Build complete"
Write-Host "AAB: $AabPath"

