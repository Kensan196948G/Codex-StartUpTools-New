[CmdletBinding()]
param(
    [string]$Project = "",
    [switch]$Local,
    [switch]$NonInteractive,
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:StartupRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Import-Module (Join-Path $script:StartupRoot "scripts\lib\LauncherCommon.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $script:StartupRoot "scripts\lib\Config.psm1") -Force

function Get-CodexStatePath {
    if ($env:AI_STARTUP_STATE_PATH) {
        return $env:AI_STARTUP_STATE_PATH
    }

    return Join-Path $script:StartupRoot "state.json"
}

function Resolve-CodexWorkingDirectory {
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [string]$ProjectName
    )

    if ([string]::IsNullOrWhiteSpace($ProjectName)) {
        return (Get-Location).Path
    }

    return Join-Path $Config.projectsDir $ProjectName
}

function Get-CodexProjectLabel {
    param(
        [string]$ProjectName,
        [string]$WorkingDirectory
    )

    if (-not [string]::IsNullOrWhiteSpace($ProjectName)) {
        return $ProjectName
    }

    return (Split-Path -Leaf $WorkingDirectory)
}

function Write-LaunchPlan {
    param(
        [string]$Command,
        [string[]]$Arguments,
        [string]$WorkingDirectory
    )

    $argumentText = @($Arguments) -join " "
    Write-Host "Codex Launch Plan" -ForegroundColor Magenta
    Write-Host ("  Working Dir : {0}" -f $WorkingDirectory)
    Write-Host ("  Command     : {0} {1}" -f $Command, $argumentText)
    Write-Host ("  Mode        : {0}" -f $(if ($Local) { "local" } else { "local" }))
    if ($DryRun) {
        Write-Host "  Dry Run     : enabled"
    }
    Write-Host ""
}

function Update-CodexLaunchState {
    param(
        [Parameter(Mandatory)]
        [string]$StatePath,

        [Parameter(Mandatory)]
        [string]$Phase,

        [string]$ProjectName,

        [switch]$PreviewOnly
    )

    if (-not (Test-Path $StatePath)) {
        return
    }

    $state = Get-Content -Path $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not ($state.PSObject.Properties.Name -contains "execution") -or $null -eq $state.execution) {
        $state | Add-Member -NotePropertyName "execution" -NotePropertyValue ([pscustomobject]@{}) -Force
    }

    $timestamp = (Get-Date).ToString("o")
    $state.execution | Add-Member -NotePropertyName "phase" -NotePropertyValue $Phase -Force
    $state.execution | Add-Member -NotePropertyName "last_launch_at" -NotePropertyValue $timestamp -Force
    if (-not [string]::IsNullOrWhiteSpace($ProjectName)) {
        $state.execution | Add-Member -NotePropertyName "current_project" -NotePropertyValue $ProjectName -Force
    }

    if ($PreviewOnly) {
        return
    }

    $json = $state | ConvertTo-Json -Depth 20
    Set-Content -Path $StatePath -Value $json -Encoding UTF8 -NoNewline
}

try {
    $bootstrapScript = Join-Path $PSScriptRoot "Start-CodexBootstrap.ps1"
    & $bootstrapScript -DryRun:$DryRun -NonInteractive:$NonInteractive
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }

    $configPath = Get-StartupConfigPath -StartupRoot $script:StartupRoot
    $config = Import-LauncherConfig -ConfigPath $configPath
    $toolConfig = $config.tools.codex
    if (-not $toolConfig.enabled) {
        throw "config.json で tools.codex.enabled が false です。"
    }

    $workingDirectory = Resolve-CodexWorkingDirectory -Config $config -ProjectName $Project
    if (-not (Test-Path $workingDirectory)) {
        throw "作業ディレクトリが見つかりません: $workingDirectory"
    }

    $command = "$($toolConfig.command)"
    if (-not (Get-Command $command -ErrorAction SilentlyContinue)) {
        throw "Codex コマンドが見つかりません: $command"
    }

    $arguments = @($toolConfig.args | ForEach-Object { "$_" })
    Write-LaunchPlan -Command $command -Arguments $arguments -WorkingDirectory $workingDirectory

    if ($DryRun) {
        exit 0
    }

    $previous = Get-Location
    $projectLabel = Get-CodexProjectLabel -ProjectName $Project -WorkingDirectory $workingDirectory
    $startAt = Get-Date
    $statePath = Get-CodexStatePath

    try {
        Update-CodexLaunchState -StatePath $statePath -Phase "Development" -ProjectName $projectLabel
        Set-Location $workingDirectory
        & $command @arguments
        $exitCode = $LASTEXITCODE
    }
    finally {
        Set-Location $previous
    }

    $elapsedMs = [int]((Get-Date) - $startAt).TotalMilliseconds
    if (Test-RecentProjectsEnabled -Config $config) {
        Update-RecentProject -ProjectName $projectLabel -Tool "codex" -Mode "local" -Result $(if ($exitCode -eq 0) { "success" } else { "failure" }) -ElapsedMs $elapsedMs -HistoryPath $config.recentProjects.historyFile -MaxHistory $config.recentProjects.maxHistory
    }

    exit $exitCode
}
catch {
    Write-Host ("[ERR] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
