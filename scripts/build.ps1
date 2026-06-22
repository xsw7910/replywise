param(
    [switch]$Clean,
    [Parameter(Mandatory)][string]$ReplyBackendBaseUrl,
    [ValidateSet("prod")][string]$ReplyEnv = "prod",
    [Parameter(Mandatory)][string]$RevenueCatAndroidApiKey,
    [string]$RevenueCatEntitlementId = "premium"
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

function Assert-ProductionConfiguration {
    $uri = $null
    if (-not [Uri]::TryCreate($ReplyBackendBaseUrl, [UriKind]::Absolute, [ref]$uri) -or
        $uri.Scheme -ne "https") {
        throw "ReplyBackendBaseUrl must be an absolute HTTPS URL."
    }
    if ($uri.Host -match "(^localhost$|^127\.|^10\.0\.2\.2$|\.example$)") {
        throw "ReplyBackendBaseUrl must point to the real production backend."
    }
    if ($RevenueCatAndroidApiKey -notmatch "^goog_[A-Za-z0-9]+$") {
        throw "RevenueCatAndroidApiKey must be the RevenueCat Android public SDK key."
    }
    if ([string]::IsNullOrWhiteSpace($RevenueCatEntitlementId) -or
        $RevenueCatEntitlementId -match "REPLACE|PLACEHOLDER") {
        throw "RevenueCatEntitlementId must be a real entitlement identifier."
    }
}

Write-Host "ReplyWise Android production release build" -ForegroundColor Green
Write-Host "Repository: $RepoRoot"
Assert-ProductionConfiguration

Push-Location $AppRoot
try {
    if ($Clean) {
        Write-Section "Flutter clean"
        Invoke-Flutter @("clean")
    }

    Write-Section "Flutter dependencies"
    Invoke-Flutter @("pub", "get")

    Write-Section "Building signed release app bundle"
    Invoke-Flutter @(
        "build",
        "appbundle",
        "--release",
        "--dart-define=REPLY_BACKEND_BASE_URL=$ReplyBackendBaseUrl",
        "--dart-define=REPLY_ENV=$ReplyEnv",
        "--dart-define=REVENUECAT_ANDROID_API_KEY=$RevenueCatAndroidApiKey",
        "--dart-define=REVENUECAT_ENTITLEMENT_ID=$RevenueCatEntitlementId"
    )
}
finally {
    Pop-Location
}

$AabPath = Join-Path $AppRoot "build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path -LiteralPath $AabPath)) {
    throw "Release build completed without producing the expected AAB: $AabPath"
}
Write-Section "Build complete"
Write-Host "AAB: $AabPath"
