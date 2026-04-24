[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$NonInteractive
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:StartupRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

Import-Module (Join-Path $script:StartupRoot "scripts\lib\LauncherCommon.psm1") -Force -DisableNameChecking
Import-Module (Join-Path $script:StartupRoot "scripts\lib\Config.psm1") -Force
Import-Module (Join-Path $script:StartupRoot "scripts\lib\TokenBudget.psm1") -Force
Import-Module (Join-Path $script:StartupRoot "scripts\lib\McpHealthCheck.psm1") -Force

function Get-BootstrapStatePath {
    if ($env:AI_STARTUP_STATE_PATH) {
        return $env:AI_STARTUP_STATE_PATH
    }

    return Join-Path $script:StartupRoot "state.json"
}

function Get-BootstrapStateExamplePath {
    return Join-Path $script:StartupRoot "state.json.example"
}

function Initialize-BootstrapState {
    param(
        [Parameter(Mandatory)]
        [string]$StatePath,

        [switch]$PreviewOnly
    )

    if (Test-Path $StatePath) {
        return [pscustomobject]@{
            Exists   = $true
            Created  = $false
            Path     = $StatePath
            Message  = "state.json already exists"
        }
    }

    $examplePath = Get-BootstrapStateExamplePath
    if (-not (Test-Path $examplePath)) {
        throw "state.json.example が見つかりません: $examplePath"
    }

    if ($PreviewOnly) {
        return [pscustomobject]@{
            Exists   = $false
            Created  = $false
            Path     = $StatePath
            Message  = "state.json would be created from state.json.example"
        }
    }

    $directory = Split-Path -Parent $StatePath
    if (-not [string]::IsNullOrWhiteSpace($directory) -and -not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    Copy-Item -Path $examplePath -Destination $StatePath -Force

    return [pscustomobject]@{
        Exists   = $false
        Created  = $true
        Path     = $StatePath
        Message  = "state.json created from state.json.example"
    }
}

function Get-BootstrapSummary {
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,

        [Parameter(Mandatory)]
        [string]$StatePath,

        [Parameter(Mandatory)]
        [object]$Config
    )

    $toolConfig = $Config.tools.codex
    $toolCommand = "$($toolConfig.command)"
    $toolAvailable = [bool](Get-Command $toolCommand -ErrorAction SilentlyContinue)
    $mcpStatus = Get-McpQuickStatus -ProjectRoot $script:StartupRoot
    $tokenStatus = Get-TokenBudgetStatus -StatePath $StatePath

    return [pscustomobject]@{
        ConfigPath     = $ConfigPath
        StatePath      = $StatePath
        ToolCommand    = $toolCommand
        ToolAvailable  = $toolAvailable
        TokenZone      = $tokenStatus.Zone.Label
        TokenUsed      = $tokenStatus.UsedPercent
        McpStatus      = $mcpStatus
        NonInteractive = [bool]$NonInteractive
        DryRun         = [bool]$DryRun
    }
}

function Write-BootstrapBanner {
    Write-Host ""
    Write-Host "Codex StartUp Bootstrap" -ForegroundColor Cyan
    Write-Host "Codex-native startup preflight" -ForegroundColor Cyan
    Write-Host ""
}

function Write-BootstrapSummary {
    param([Parameter(Mandatory)][object]$Summary)

    Write-Host "Bootstrap Summary" -ForegroundColor Magenta
    Write-Host ("  Config      : {0}" -f $Summary.ConfigPath)
    Write-Host ("  State       : {0}" -f $Summary.StatePath)
    Write-Host ("  Tool        : {0}" -f $Summary.ToolCommand)
    Write-Host ("  Tool Ready  : {0}" -f $(if ($Summary.ToolAvailable) { "yes" } else { "no" }))
    Write-Host ("  Token Zone  : {0} ({1}%)" -f $Summary.TokenZone, $Summary.TokenUsed)
    Write-Host ("  MCP         : {0}" -f $Summary.McpStatus)
    Write-Host ("  Mode        : {0}" -f $(if ($Summary.NonInteractive) { "non-interactive" } else { "interactive" }))
    if ($Summary.DryRun) {
        Write-Host "  Dry Run     : enabled"
    }
    Write-Host ""
}

try {
    Write-BootstrapBanner

    $configPath = Get-StartupConfigPath -StartupRoot $script:StartupRoot
    $config = Import-LauncherConfig -ConfigPath $configPath
    Assert-StartupConfigSchema -ConfigPath $configPath | Out-Null

    if (-not $config.tools.codex.enabled) {
        throw "config.json で tools.codex.enabled が false です。"
    }

    $statePath = Get-BootstrapStatePath
    $stateResult = Initialize-BootstrapState -StatePath $statePath -PreviewOnly:$DryRun
    Write-Host ("State: {0}" -f $stateResult.Message) -ForegroundColor $(if ($stateResult.Created) { "Green" } elseif ($stateResult.Exists) { "DarkGray" } else { "Yellow" })

    $summary = Get-BootstrapSummary -ConfigPath $configPath -StatePath $statePath -Config $config
    Write-BootstrapSummary -Summary $summary

    if (-not $summary.ToolAvailable) {
        throw "Codex コマンドが見つかりません: $($summary.ToolCommand)"
    }

    exit 0
}
catch {
    Write-Host ("[ERR] {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}
