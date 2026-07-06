param(
    [switch]$Clean,
    [Parameter(Mandatory)][string]$ReplyBackendBaseUrl,
    [ValidateSet("prod")][string]$ReplyEnv = "prod",
    [Parameter(Mandatory)][string]$RevenueCatAndroidApiKey,
    [string]$RevenueCatEntitlementId = "premium",
    [Parameter(Mandatory)][string]$AdMobAppId,
    [Parameter(Mandatory)][string]$AdMobRewardedAdUnitId
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
    # AdMob app ids use '~'; ad unit ids use '/'. Catching a swap or malformed id
    # here avoids shipping a release that crashes on first ad or serves no ads.
    if ($AdMobAppId -notmatch "^ca-app-pub-\d+~\d+$") {
        throw "AdMobAppId must look like ca-app-pub-XXXXXXXXXXXXXXXX~NNNNNNNNNN."
    }
    if ($AdMobRewardedAdUnitId -notmatch "^ca-app-pub-\d+/\d+$") {
        throw "AdMobRewardedAdUnitId must look like ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN."
    }
    # Publisher 3940256099942544 is Google's sample account — never ship its test
    # ads to production.
    if ($AdMobAppId -like "ca-app-pub-3940256099942544*" -or
        $AdMobRewardedAdUnitId -like "ca-app-pub-3940256099942544*") {
        throw "AdMob ids must be your production units, not Google's sample/test ids."
    }
}

Write-Host "ReplyWise Android production release build" -ForegroundColor Green
Write-Host "Repository: $RepoRoot"
Assert-ProductionConfiguration

Push-Location $AppRoot
# The AdMob app id reaches AndroidManifest.xml through the ${admobAppId} Gradle
# manifest placeholder (build.gradle.kts reads REPLY_ADMOB_APP_ID), which a
# dart-define cannot populate. Export it for the Gradle build so the release
# manifest carries the real app id instead of the test default; it is also
# passed as a dart-define below per the release contract. The previous value is
# restored afterwards so the script leaves no ambient state behind.
$PreviousAdMobAppIdEnv = $env:REPLY_ADMOB_APP_ID
try {
    $env:REPLY_ADMOB_APP_ID = $AdMobAppId

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
        "--dart-define=REVENUECAT_ENTITLEMENT_ID=$RevenueCatEntitlementId",
        "--dart-define=REPLY_ADMOB_APP_ID=$AdMobAppId",
        "--dart-define=REPLY_ADMOB_REWARDED_AD_UNIT_ID=$AdMobRewardedAdUnitId"
    )
}
finally {
    if ($null -eq $PreviousAdMobAppIdEnv) {
        Remove-Item Env:REPLY_ADMOB_APP_ID -ErrorAction SilentlyContinue
    }
    else {
        $env:REPLY_ADMOB_APP_ID = $PreviousAdMobAppIdEnv
    }
    Pop-Location
}

$AabPath = Join-Path $AppRoot "build\app\outputs\bundle\release\app-release.aab"
if (-not (Test-Path -LiteralPath $AabPath)) {
    throw "Release build completed without producing the expected AAB: $AabPath"
}
Write-Section "Build complete"
Write-Host "AAB: $AabPath"
