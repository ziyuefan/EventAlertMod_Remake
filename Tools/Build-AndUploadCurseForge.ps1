<# EAM_FILE_COMMENTARY
EventAlertMod Retail Rewrite
檔案: Tools\Build-AndUploadCurseForge.ps1

理念:
- 將 CurseForge 發佈流程收斂成單一入口：先打包，再上傳。
- 預設 DryRun，讓發佈前可檢查 zip、版本名稱與 upload metadata。

責任:
- 呼叫 Build-CurseForgePackage.ps1 產生最新 zip。
- 找出剛產生的 EventAlertMod_MN_*.zip。
- 呼叫 Upload-CurseForgePackage.ps1 執行 DryRun 或正式上傳。

邊界:
- 不保存 CurseForge token。
- 不替代 CurseForge 審核。
- 不代表 WoW Retail 實機驗證完成。
#>

param(
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
    [switch]$IncludeDocs,
    [switch]$SkipLuaCheck,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$workspace = Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")
Set-Location -LiteralPath $workspace

$buildScript = Join-Path $workspace "Tools\Build-CurseForgePackage.ps1"
$uploadScript = Join-Path $workspace "Tools\Upload-CurseForgePackage.ps1"
$distPath = Join-Path $workspace "Dist"

if (-not (Test-Path -LiteralPath $buildScript)) {
    throw "Missing build script: $buildScript"
}
if (-not (Test-Path -LiteralPath $uploadScript)) {
    throw "Missing upload script: $uploadScript"
}

$before = @{}
if (Test-Path -LiteralPath $distPath) {
    Get-ChildItem -LiteralPath $distPath -File -Filter "EventAlertMod_MN_*.zip" | ForEach-Object {
        $before[$_.FullName] = $true
    }
}

$buildArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-File", $buildScript
)
if ($IncludeDocs) {
    $buildArgs += "-IncludeDocs"
}
if ($SkipLuaCheck) {
    $buildArgs += "-SkipLuaCheck"
}

Write-Host "Step 1/2: Building CurseForge package..."
& powershell @buildArgs
if ($LASTEXITCODE -ne 0) {
    throw "Build failed."
}

$afterPackages = Get-ChildItem -LiteralPath $distPath -File -Filter "EventAlertMod_MN_*.zip" |
    Sort-Object LastWriteTime -Descending

$package = $afterPackages | Where-Object { -not $before.ContainsKey($_.FullName) } | Select-Object -First 1
if (-not $package) {
    $package = $afterPackages | Select-Object -First 1
}
if (-not $package) {
    throw "No package found after build."
}

Write-Host "Built package: $($package.FullName)"

$uploadArgs = @(
    "-ExecutionPolicy", "Bypass",
    "-File", $uploadScript,
    "-PackagePath", $package.FullName,
    "-ReleaseType", $ReleaseType,
    "-ChangelogType", $ChangelogType
)

if ($GameVersionIds -and $GameVersionIds.Count -gt 0) {
    $uploadArgs += "-GameVersionIds"
    $uploadArgs += $GameVersionIds
}
if ($ChangelogPath) {
    $uploadArgs += "-ChangelogPath"
    $uploadArgs += $ChangelogPath
}
if ($Changelog) {
    $uploadArgs += "-Changelog"
    $uploadArgs += $Changelog
}
if ($DisplayName) {
    $uploadArgs += "-DisplayName"
    $uploadArgs += $DisplayName
}
if ($Token) {
    $uploadArgs += "-Token"
    $uploadArgs += $Token
}
if ($ImmediateRelease) {
    $uploadArgs += "-ImmediateRelease"
}
if ($DryRun) {
    $uploadArgs += "-DryRun"
}

Write-Host "Step 2/2: Preparing CurseForge upload..."
& powershell @uploadArgs
if ($LASTEXITCODE -ne 0) {
    throw "Upload step failed."
}
