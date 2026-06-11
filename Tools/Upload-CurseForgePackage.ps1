<# EAM_FILE_COMMENTARY
EventAlertMod Retail Rewrite
檔案: Tools\Upload-CurseForgePackage.ps1

理念:
- 提供 CurseForge Upload API 的可重複上傳流程。
- Token 只能從環境變數或參數取得，不寫入 repo。

責任:
- 找出要上傳的 zip。
- 從 TOC 讀取 Project ID 與版本資訊。
- 組出 CurseForge upload-file metadata。
- 以 multipart/form-data 上傳 zip。

邊界:
- 預設 DryRun，不會上傳。
- 不替代 CurseForge 審核。
- 不代表 WoW Retail 實機驗證完成。

參考:
- https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-upload-api
#>

param(
    [string]$PackagePath,
    [string]$ProjectId,
    [int[]]$GameVersionIds,
    [ValidateSet("alpha", "beta", "release")]
    [string]$ReleaseType = "alpha",
    [string]$ChangelogPath,
    [string]$Changelog,
    [ValidateSet("text", "html", "markdown")]
    [string]$ChangelogType = "markdown",
    [string]$DisplayName,
    [switch]$ImmediateRelease,
    [string]$Token = $env:CURSEFORGE_TOKEN,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$workspace = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
Set-Location -LiteralPath $workspace

$tocPath = Join-Path $workspace "EventAlertMod.toc"
$distPath = Join-Path $workspace "Dist"

function Get-TocValue {
    param([string]$Key)
    $pattern = "^##\s+$([regex]::Escape($Key)):\s*(.+)$"
    foreach ($line in Get-Content -LiteralPath $tocPath) {
        if ($line -match $pattern) {
            return $Matches[1].Trim()
        }
    }
    return $null
}

function Get-LatestPackage {
    if (-not (Test-Path -LiteralPath $distPath)) {
        throw "Dist folder not found. Run Tools/Build-CurseForgePackage.ps1 first."
    }

    $package = Get-ChildItem -LiteralPath $distPath -File -Filter "EventAlertMod_MN_*.zip" |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

    if (-not $package) {
        throw "No EventAlertMod_MN_*.zip package found in Dist."
    }

    return $package.FullName
}

if (-not $ProjectId) {
    $ProjectId = Get-TocValue "X-Curse-Project-ID"
}

if (-not $ProjectId) {
    throw "ProjectId is required. Pass -ProjectId or set ## X-Curse-Project-ID in EventAlertMod.toc."
}

if (-not $PackagePath) {
    $PackagePath = Get-LatestPackage
}

if (-not (Test-Path -LiteralPath $PackagePath)) {
    throw "Package not found: $PackagePath"
}

if (-not $DisplayName) {
    $DisplayName = Get-TocValue "Version"
}

if (-not $DisplayName) {
    $DisplayName = [System.IO.Path]::GetFileNameWithoutExtension($PackagePath)
}

if ($ChangelogPath) {
    if (-not (Test-Path -LiteralPath $ChangelogPath)) {
        throw "ChangelogPath not found: $ChangelogPath"
    }
    $Changelog = Get-Content -LiteralPath $ChangelogPath -Raw
}

if (-not $Changelog) {
    $Changelog = @"
EventAlertMod Retail rewrite package.

- Retail-only architecture.
- No Classic/MOP branches in active package.
- No external hard dependencies.
- Lua syntax checked before packaging.

Note: Upload approval does not mean live WoW Retail validation has been completed.
"@
}

if (-not $GameVersionIds -or $GameVersionIds.Count -eq 0) {
    throw "GameVersionIds is required. CurseForge upload metadata requires numeric game version IDs."
}

$metadata = [ordered]@{
    changelog = $Changelog
    changelogType = $ChangelogType
    displayName = $DisplayName
    gameVersions = $GameVersionIds
    releaseType = $ReleaseType
    isMarkedForManualRelease = (-not $ImmediateRelease)
}

$metadataJson = $metadata | ConvertTo-Json -Depth 8

Write-Host "CurseForge upload preview"
Write-Host "Project ID: $ProjectId"
Write-Host "Package: $PackagePath"
Write-Host "Display Name: $DisplayName"
Write-Host "Release Type: $ReleaseType"
Write-Host "Manual Release: $(-not $ImmediateRelease)"
Write-Host "Game Version IDs: $($GameVersionIds -join ', ')"
Write-Host "Metadata:"
Write-Host $metadataJson

if ($DryRun) {
    Write-Host "DryRun enabled. No upload performed."
    exit 0
}

if (-not $Token) {
    throw "CURSEFORGE_TOKEN is missing. Set `$env:CURSEFORGE_TOKEN or pass -Token."
}

$uri = "https://www.curseforge.com/api/projects/$ProjectId/upload-file"

$form = @{
    metadata = $metadataJson
    file = Get-Item -LiteralPath $PackagePath
}

$headers = @{
    "X-Api-Token" = $Token
}

$response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Form $form

Write-Host "Upload response:"
$response | ConvertTo-Json -Depth 8
