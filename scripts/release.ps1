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

function Write-Section {
    param([Parameter(Mandatory)][string]$Title)
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

Write-Host "ReplyWise release checklist helper" -ForegroundColor Green
Write-Host "Repository: $RepoRoot"

Write-Section "Running local checks"
& (Join-Path $PSScriptRoot "test.ps1")

Write-Section "Building Android app bundle"
$BuildParameters = @{
    ReplyBackendBaseUrl = $ReplyBackendBaseUrl
    ReplyEnv = $ReplyEnv
    RevenueCatAndroidApiKey = $RevenueCatAndroidApiKey
    RevenueCatEntitlementId = $RevenueCatEntitlementId
}
if ($Clean) {
    $BuildParameters.Clean = $true
}
& (Join-Path $PSScriptRoot "build.ps1") @BuildParameters

$AabPath = Join-Path $RepoRoot "app\build\app\outputs\bundle\release\app-release.aab"
Write-Section "Release artifact"
Write-Host $AabPath

Write-Section "Manual Google Play and RevenueCat checklist"
Write-Host "[ ] Verify production /health over HTTPS"
Write-Host "[ ] Verify package ID, version code, upload signing, and Play App Signing"
Write-Host "[ ] Verify RevenueCat Android app and Google service credentials"
Write-Host "[ ] Verify entitlement premium and offering default"
Write-Host "[ ] Verify reply_premium_monthly, monthly base plan, and 3-day trial"
Write-Host "[ ] Verify credits_10, credits_50, and credits_100 are active consumables"
Write-Host "[ ] Verify store listing, screenshots, privacy policy, and Data Safety"
Write-Host "[ ] Add internal testers and license-test accounts"
Write-Host "[ ] Complete the end-to-end purchase matrix in docs/GOOGLE_PLAY_INTERNAL_TESTING.md"

Write-Host "`nNo Google Play upload, commit, or git push was performed."
