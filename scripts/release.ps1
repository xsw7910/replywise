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

Write-Section "Manual release checklist"
Write-Host "[ ] Verify dart-define production backend URL"
Write-Host "[ ] Verify RevenueCat keys"
Write-Host "[ ] Verify Google Play listing"
Write-Host "[ ] Verify privacy policy and data safety"
Write-Host "[ ] Verify internal testing track"

Write-Host "`nNo Google Play upload, commit, or git push was performed."

