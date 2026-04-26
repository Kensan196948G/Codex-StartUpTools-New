Set-StrictMode -Version Latest

$script:MenuVersion = "1.0"
$script:MenuTitle   = "Codex StartUp Tools"
$script:MenuSubtitle = "Codex ネイティブ / GitHub Actions CI / ClaudeOS v8 統合"

# ---------------------------------------------------------------
# メニュー定義
# ---------------------------------------------------------------

function Get-MenuItems {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $linuxHost  = if ($Config.linuxHost -and $Config.linuxHost -ne '<your-linux-host>') { $Config.linuxHost } else { $null }
    $linuxBase  = if ($Config.linuxBase)   { $Config.linuxBase }  else { '/home/user/Projects' }
    $localDir   = if ($Config.projectsDir) { $Config.projectsDir } else { 'D:\' }
    $hasSsh     = $null -ne $linuxHost

    $items = [System.Collections.Generic.List[pscustomobject]]::new()

    # --- SSH セクション ---
    if ($hasSsh) {
        $items.Add([pscustomobject]@{
            Key     = 'S1'
            Label   = "Codex を SSH で起動"
            Note    = "Linux / フルオート ($linuxHost)"
            Section = "SSH 接続 ($linuxHost -> $linuxBase)"
            Action  = 'launch-ssh-codex'
            Enabled = $true
        })
        $items.Add([pscustomobject]@{
            Key     = 'S2'
            Label   = "Claude Code を SSH で起動"
            Note    = "Linux / フルオート"
            Section = $null
            Action  = 'launch-ssh-claude'
            Enabled = $true
        })
    }

    # --- ローカルセクション ---
    $items.Add([pscustomobject]@{
        Key     = 'L1'
        Label   = "Codex を起動"
        Note    = "ローカル ($localDir) / フルオート"
        Section = "ローカル ($localDir)"
        Action  = 'launch-local-codex'
        Enabled = $true
    })
    $items.Add([pscustomobject]@{
        Key     = 'L2'
        Label   = "Claude Code を起動"
        Note    = "ローカル / 手動セッション"
        Section = $null
        Action  = 'launch-local-claude'
        Enabled = $Config.tools.claude.enabled -eq $true
    })

    # --- 診断・セットアップセクション ---
    $items.Add([pscustomobject]@{
        Key     = '1'
        Label   = "プロジェクトダッシュボード"
        Note    = "Git / テスト / Token / フェーズを表示"
        Section = "診断・セットアップ"
        Action  = 'show-dashboard'
        Enabled = $true
    })
    $items.Add([pscustomobject]@{
        Key     = '2'
        Label   = "MCP ヘルスチェック"
        Note    = "MCP サーバーの状態を確認"
        Section = $null
        Action  = 'mcp-health'
        Enabled = $true
    })
    $items.Add([pscustomobject]@{
        Key     = '3'
        Label   = "Architecture Check"
        Note    = "設計違反・秘密情報の静的解析"
        Section = $null
        Action  = 'arch-check'
        Enabled = $true
    })
    $items.Add([pscustomobject]@{
        Key     = '4'
        Label   = "Worktree Manager"
        Note    = "Git worktree の一覧・作成・削除"
        Section = $null
        Action  = 'worktree'
        Enabled = $true
    })
    $items.Add([pscustomobject]@{
        Key     = '5'
        Label   = "Token Budget 確認"
        Note    = "トークン使用状況と残量ゾーンを表示"
        Section = $null
        Action  = 'token-budget'
        Enabled = $true
    })
    $items.Add([pscustomobject]@{
        Key     = '6'
        Label   = "Bootstrap 実行 (preflight)"
        Note    = "設定・ツール・CI の事前確認"
        Section = $null
        Action  = 'bootstrap'
        Enabled = $true
    })

    # --- 最近のプロジェクトセクション ---
    $items.Add([pscustomobject]@{
        Key     = '7'
        Label   = "最近のプロジェクト一覧"
        Note    = "履歴から再起動"
        Section = "プロジェクト管理"
        Action  = 'recent-projects'
        Enabled = $Config.recentProjects.enabled -eq $true
    })
    $items.Add([pscustomobject]@{
        Key     = '8'
        Label   = "MessageBus ログ確認"
        Note    = "フェーズ遷移・CI メッセージを表示"
        Section = $null
        Action  = 'message-bus'
        Enabled = $true
    })

    # --- 終了 ---
    $items.Add([pscustomobject]@{
        Key     = '0'
        Label   = "終了"
        Note    = ""
        Section = $null
        Action  = 'exit'
        Enabled = $true
    })

    return $items
}

# ---------------------------------------------------------------
# ヘッダー・フッター表示
# ---------------------------------------------------------------

function Write-MenuHeader {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [string]$ProjectRoot = ""
    )

    $width = 62
    $border = "=" * $width

    Write-Host ""
    Write-Host (" $border") -ForegroundColor Cyan
    Write-Host ("   $script:MenuTitle  v$script:MenuVersion") -ForegroundColor White
    Write-Host ("   $script:MenuSubtitle") -ForegroundColor DarkCyan
    Write-Host (" $border") -ForegroundColor Cyan

    # ダッシュボード情報（軽量版）
    if ($ProjectRoot -and (Test-Path $ProjectRoot)) {
        try {
            Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\ProjectDashboard.psm1") -Force -ErrorAction SilentlyContinue
            $info = Get-ProjectDashboardInfo -ProjectRoot $ProjectRoot -ErrorAction SilentlyContinue
            if ($info) {
                $stableIcon = if ($info.Phase.Stable) { "[STABLE]" } else { "[unstable]" }
                $stableColor = if ($info.Phase.Stable) { "Green" } else { "Yellow" }
                $cleanIcon = if ($info.Git.IsClean) { "clean" } else { "dirty" }
                Write-Host ""
                Write-Host ("  Branch : {0,-20} ({1})  Tests : {2}" -f $info.Git.Branch, $cleanIcon, $info.Tests.TestFileCount) -ForegroundColor DarkGray
                Write-Host ("  Phase  : {0,-20} {1}" -f $info.Phase.Current, $stableIcon) -ForegroundColor $stableColor
            }
        }
        catch { }
    }
    Write-Host ""
}

function Write-MenuSection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Title
    )
    Write-Host ("  -- {0} --" -f $Title) -ForegroundColor Yellow
}

function Write-MenuItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Item
    )

    $keyPad = $Item.Key.PadLeft(3)
    $note = if ($Item.Note) { "  [{0}]" -f $Item.Note } else { "" }

    if ($Item.Enabled) {
        Write-Host ("    {0}.  {1}{2}" -f $keyPad, $Item.Label, $note) -ForegroundColor White
    }
    else {
        Write-Host ("    {0}.  {1}  [無効]" -f $keyPad, $Item.Label) -ForegroundColor DarkGray
    }
}

function Show-Menu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [string]$ProjectRoot = ""
    )

    if (-not [Console]::IsOutputRedirected) {
        Clear-Host
    }
    Write-MenuHeader -Config $Config -ProjectRoot $ProjectRoot

    $items = Get-MenuItems -Config $Config
    $currentSection = ""

    foreach ($item in $items) {
        if ($item.Key -eq '0') {
            Write-Host ""
        }

        if ($item.Section -and $item.Section -ne $currentSection) {
            Write-Host ""
            Write-MenuSection -Title $item.Section
            $currentSection = $item.Section
        }

        Write-MenuItem -Item $item
    }

    Write-Host ""
    Write-Host (" {0}" -f ("=" * 62)) -ForegroundColor Cyan
    Write-Host ""

    return $items
}

# ---------------------------------------------------------------
# 入力処理
# ---------------------------------------------------------------

function Read-MenuChoice {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject[]]$Items
    )

    $choice = Read-Host "  選択してください"
    $choice = $choice.Trim().ToUpper()

    $found = $Items | Where-Object { $_.Key.ToUpper() -eq $choice -and $_.Enabled }
    if ($found) {
        return $found
    }

    return $null
}

# ---------------------------------------------------------------
# アクション実行
# ---------------------------------------------------------------

function Invoke-MenuAction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Item,

        [Parameter(Mandatory)]
        [object]$Config,

        [string]$ProjectRoot = "",
        [string]$StatePath = ""
    )

    switch ($Item.Action) {
        'show-dashboard' {
            Invoke-DashboardAction -ProjectRoot $ProjectRoot -StatePath $StatePath
        }
        'mcp-health' {
            Invoke-McpHealthAction -ProjectRoot $ProjectRoot
        }
        'arch-check' {
            Invoke-ArchCheckAction -ProjectRoot $ProjectRoot
        }
        'worktree' {
            Invoke-WorktreeAction -ProjectRoot $ProjectRoot
        }
        'token-budget' {
            Invoke-TokenBudgetAction -StatePath $StatePath -ProjectRoot $ProjectRoot
        }
        'bootstrap' {
            Invoke-BootstrapAction -ProjectRoot $ProjectRoot
        }
        'recent-projects' {
            Invoke-RecentProjectsAction -Config $Config
        }
        'message-bus' {
            Invoke-MessageBusAction -StatePath $StatePath
        }
        'launch-local-codex' {
            Invoke-LaunchAction -Config $Config -Tool 'codex' -Mode 'local' -ProjectRoot $ProjectRoot
        }
        'launch-local-claude' {
            Invoke-LaunchAction -Config $Config -Tool 'claude' -Mode 'local' -ProjectRoot $ProjectRoot
        }
        'launch-ssh-codex' {
            Invoke-LaunchAction -Config $Config -Tool 'codex' -Mode 'ssh' -ProjectRoot $ProjectRoot
        }
        'launch-ssh-claude' {
            Invoke-LaunchAction -Config $Config -Tool 'claude' -Mode 'ssh' -ProjectRoot $ProjectRoot
        }
        'exit' {
            return $false
        }
        default {
            Write-Host "  [INFO] この機能は未実装です: $($Item.Action)" -ForegroundColor Yellow
        }
    }

    return $true
}

function Invoke-DashboardAction {
    param([string]$ProjectRoot, [string]$StatePath)
    Write-Host ""
    try {
        Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\ProjectDashboard.psm1") -Force -ErrorAction SilentlyContinue
        Show-ProjectDashboard -ProjectRoot $ProjectRoot -StatePath $StatePath | Out-Null
    }
    catch {
        Write-Host "  [ERROR] ダッシュボード表示エラー: $_" -ForegroundColor Red
    }
    Wait-MenuInput
}

function Invoke-McpHealthAction {
    param([string]$ProjectRoot)
    Write-Host ""
    try {
        Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\McpHealthCheck.psm1") -Force -ErrorAction SilentlyContinue
        $report = Get-McpHealthReport -ProjectRoot $ProjectRoot
        Write-Host "  MCP ヘルスチェック結果:" -ForegroundColor Cyan
        Write-Host ("  {0}" -f $report.Summary)
        foreach ($entry in $report.Entries) {
            $color = if ($entry.Healthy) { "Green" } else { "Red" }
            $icon = if ($entry.Healthy) { "[OK]  " } else { "[WARN]" }
            Write-Host ("    {0} {1}" -f $icon, $entry.Name) -ForegroundColor $color
        }
    }
    catch {
        Write-Host "  [ERROR] MCP ヘルスチェックエラー: $_" -ForegroundColor Red
    }
    Write-Host ""
    Wait-MenuInput
}

function Invoke-ArchCheckAction {
    param([string]$ProjectRoot)
    Write-Host ""
    try {
        Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\ArchitectureCheck.psm1") -Force -ErrorAction SilentlyContinue
        $result = Show-ArchitectureCheckReport -Path (Join-Path $ProjectRoot "scripts")
        Write-Host ""
    }
    catch {
        Write-Host "  [ERROR] Architecture Check エラー: $_" -ForegroundColor Red
    }
    Wait-MenuInput
}

function Invoke-WorktreeAction {
    param([string]$ProjectRoot)
    Write-Host ""
    try {
        Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\WorktreeManager.psm1") -Force -ErrorAction SilentlyContinue
        $worktrees = @(Get-Worktree -ProjectRoot $ProjectRoot -ErrorAction SilentlyContinue)
        Write-Host "  Git Worktree 一覧:" -ForegroundColor Cyan
        if ($worktrees.Count -eq 0) {
            Write-Host "    (worktree なし)" -ForegroundColor DarkGray
        }
        else {
            $worktrees | ForEach-Object { Write-Host ("    {0}" -f $_) }
        }
    }
    catch {
        Write-Host "  [ERROR] Worktree 情報取得エラー: $_" -ForegroundColor Red
    }
    Write-Host ""
    Wait-MenuInput
}

function Invoke-TokenBudgetAction {
    param([string]$StatePath, [string]$ProjectRoot)
    Write-Host ""
    if (-not $StatePath) { $StatePath = Join-Path $ProjectRoot "state.json" }
    try {
        Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\TokenBudget.psm1") -Force -ErrorAction SilentlyContinue
        $status = Get-TokenBudgetStatus -StatePath $StatePath
        Write-Host "  Token Budget 状況:" -ForegroundColor Cyan
        Write-Host ("    使用済み  : {0}%" -f $status.UsedPercent)
        Write-Host ("    残量      : {0}%" -f (100 - $status.UsedPercent))
        Write-Host ("    ゾーン    : {0}" -f $status.Zone.Label) -ForegroundColor $(
            switch ($status.Zone.Label) {
                "Red"    { "Red" }
                "Orange" { "Yellow" }
                "Yellow" { "Yellow" }
                default  { "Green" }
            }
        )
    }
    catch {
        Write-Host "  [ERROR] Token Budget エラー: $_" -ForegroundColor Red
    }
    Write-Host ""
    Wait-MenuInput
}

function Invoke-BootstrapAction {
    param([string]$ProjectRoot)
    Write-Host ""
    Write-Host "  Bootstrap (preflight) を実行します..." -ForegroundColor Cyan
    Write-Host ""
    $bootstrapScript = Join-Path $ProjectRoot "scripts\main\Start-CodexBootstrap.ps1"
    if (Test-Path $bootstrapScript) {
        & pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $bootstrapScript -NonInteractive
    }
    else {
        Write-Host "  [ERROR] Bootstrap スクリプトが見つかりません: $bootstrapScript" -ForegroundColor Red
    }
    Write-Host ""
    Wait-MenuInput
}

function Invoke-RecentProjectsAction {
    param([object]$Config)
    Write-Host ""
    try {
        Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "lib\Config.psm1") -Force -ErrorAction SilentlyContinue
        $historyPath = $Config.recentProjects.historyFile
        if ($historyPath) {
            $historyPath = [System.Environment]::ExpandEnvironmentVariables($historyPath)
        }
        $projects = @(Get-RecentProject -HistoryPath $historyPath -ErrorAction SilentlyContinue)
        Write-Host "  最近のプロジェクト:" -ForegroundColor Cyan
        if ($projects.Count -eq 0) {
            Write-Host "    (履歴なし)" -ForegroundColor DarkGray
        }
        else {
            $i = 1
            $projects | Select-Object -First 10 | ForEach-Object {
                $result = if ($_.result) { $_.result } else { "unknown" }
                $color = if ($result -eq 'success') { "Green" } elseif ($result -eq 'failure') { "Red" } else { "DarkGray" }
                Write-Host ("    {0,2}. {1,-30} [{2}]" -f $i, $_.project, $result) -ForegroundColor $color
                $i++
            }
        }
    }
    catch {
        Write-Host "  [ERROR] プロジェクト履歴取得エラー: $_" -ForegroundColor Red
    }
    Write-Host ""
    Wait-MenuInput
}

function Invoke-MessageBusAction {
    param([string]$StatePath)
    Write-Host ""
    if (-not (Test-Path $StatePath)) {
        Write-Host "  [INFO] state.json が見つかりません: $StatePath" -ForegroundColor Yellow
        Wait-MenuInput
        return
    }
    try {
        $state = Get-Content $StatePath -Raw -Encoding UTF8 | ConvertFrom-Json
        Write-Host "  MessageBus ログ (phase.transition):" -ForegroundColor Cyan
        $msgs = @($state.'message_bus'.'phase.transition')
        if ($msgs.Count -eq 0) {
            Write-Host "    (メッセージなし)" -ForegroundColor DarkGray
        }
        else {
            $msgs | Select-Object -Last 5 | ForEach-Object {
                Write-Host ("    [{0}] {1} -> {2}  (by {3})" -f `
                    $_.timestamp, $_.payload.from, $_.payload.to, $_.publisher) -ForegroundColor DarkGray
            }
        }
    }
    catch {
        Write-Host "  [ERROR] MessageBus ログエラー: $_" -ForegroundColor Red
    }
    Write-Host ""
    Wait-MenuInput
}

# ---------------------------------------------------------------
# プロジェクト選択
# ---------------------------------------------------------------

function Get-LocalProjectList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BaseDir,

        [int]$MaxCount = 40
    )

    if (-not (Test-Path $BaseDir)) {
        return @()
    }

    return @(
        Get-ChildItem -Path $BaseDir -Directory -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -notmatch '^\.' } |
            Sort-Object Name |
            Select-Object -First $MaxCount |
            ForEach-Object { $_.Name }
    )
}

function Get-SshProjectList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LinuxHost,

        [Parameter(Mandatory)]
        [string]$LinuxBase,

        [int]$TimeoutSeconds = 8,
        [int]$MaxCount = 40,

        # テスト用: BatchMode=yes で強制（パスワードプロンプトを出さない）
        [switch]$BatchMode
    )

    $sshOpts = @("-o", "ConnectTimeout=$TimeoutSeconds")
    if ($BatchMode) {
        $sshOpts += @("-o", "BatchMode=yes")
    }

    # テンプレートデフォルト値チェック
    if ($LinuxBase -eq '/home/user/Projects') {
        Write-Host "  [WARN] config.json の linuxBase がテンプレートのままです。" -ForegroundColor Yellow
        Write-Host "         config/config.json の linuxBase を実際のパスに変更してください。" -ForegroundColor Yellow
        Write-Host ""
        return @()
    }

    try {
        # stderr を表示（接続エラーをユーザーに見せる）
        $rawOutput = & ssh @sshOpts $LinuxHost "ls -1d '$LinuxBase'/*/ 2>/dev/null | xargs -I{} basename {}"
        $exitCode  = $LASTEXITCODE

        if ($exitCode -ne 0 -or -not $rawOutput) {
            if ($exitCode -ne 0) {
                Write-Host ("  [WARN] SSH 接続失敗（終了コード {0}）" -f $exitCode) -ForegroundColor Yellow
                Write-Host "         手動でプロジェクト名を入力してください。" -ForegroundColor DarkGray
            }
            return @()
        }

        return @($rawOutput |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            ForEach-Object { $_.Trim() } |
            Select-Object -First $MaxCount)
    }
    catch {
        Write-Host ("  [WARN] SSH 一覧取得エラー: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        return @()
    }
}

function Get-RecentProjectNames {
    [CmdletBinding()]
    param(
        [string]$HistoryPath,
        [string]$Tool = '',
        [string]$Mode = '',
        [int]$MaxCount = 5
    )

    if (-not $HistoryPath -or -not (Test-Path $HistoryPath)) {
        return @()
    }

    try {
        $historyPath = [System.Environment]::ExpandEnvironmentVariables($HistoryPath)
        $entries = @(Get-RecentProject -HistoryPath $historyPath -ErrorAction SilentlyContinue)

        if ($Tool) {
            $entries = @($entries | Where-Object { $_.tool -eq $Tool })
        }
        if ($Mode) {
            $entries = @($entries | Where-Object { $_.mode -eq $Mode })
        }

        return @(
            $entries |
                Select-Object -ExpandProperty project -Unique |
                Select-Object -First $MaxCount
        )
    }
    catch {
        return @()
    }
}

function Show-ProjectSelector {
    [CmdletBinding()]
    param(
        [string[]]$RecentProjects = @(),
        [string[]]$AllProjects    = @(),
        [string]$BaseLabel        = ""
    )

    $listed   = [System.Collections.Generic.List[string]]::new()
    $indexMap = @{}  # 番号 -> プロジェクト名

    Write-Host ""

    # 最近使ったプロジェクト（先頭に表示）
    if ($RecentProjects.Count -gt 0) {
        Write-Host "  ★ 最近使ったプロジェクト:" -ForegroundColor Yellow
        foreach ($p in $RecentProjects) {
            if ($p -notin $listed) {
                $num = $listed.Count + 1
                $listed.Add($p)
                $indexMap[$num] = $p
                Write-Host ("    {0,2}. {1}" -f $num, $p) -ForegroundColor White
            }
        }
        Write-Host ""
    }

    # 全プロジェクト一覧（重複除外）
    $remaining = @($AllProjects | Where-Object { $_ -notin $listed })
    if ($remaining.Count -gt 0) {
        if ($RecentProjects.Count -gt 0) {
            Write-Host "  ── その他のプロジェクト ──" -ForegroundColor DarkGray
        } else {
            Write-Host "  プロジェクト一覧:" -ForegroundColor Cyan
            if ($BaseLabel) {
                Write-Host ("  ベース: {0}" -f $BaseLabel) -ForegroundColor DarkGray
            }
        }
        foreach ($p in $remaining) {
            $num = $listed.Count + 1
            $listed.Add($p)
            $indexMap[$num] = $p
            Write-Host ("    {0,2}. {1}" -f $num, $p) -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    if ($listed.Count -eq 0) {
        Write-Host "  (プロジェクトが見つかりませんでした)" -ForegroundColor DarkGray
        Write-Host ""
    }

    Write-Host "     0.  ベースパスで起動（プロジェクト指定なし）" -ForegroundColor DarkGray
    Write-Host ""

    # 選択入力
    $choice = (Read-Host "  番号を選択（または直接プロジェクト名を入力）").Trim()

    if ([string]::IsNullOrWhiteSpace($choice) -or $choice -eq '0') {
        return ''
    }

    # 数字ならインデックス変換
    if ($choice -match '^\d+$') {
        $idx = [int]$choice
        if ($indexMap.ContainsKey($idx)) {
            return $indexMap[$idx]
        }
    }

    # そのままプロジェクト名として扱う（直接テキスト入力）
    return $choice
}

function Select-ProjectInteractive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [string]$Mode      = 'local',
        [string]$Tool      = 'codex'
    )

    $historyPath = $Config.recentProjects.historyFile

    if ($Mode -eq 'ssh') {
        $linuxHost = $Config.linuxHost
        $linuxBase = $Config.linuxBase

        Write-Host "  SSH プロジェクト一覧を取得中 ($linuxHost)..." -ForegroundColor DarkGray
        $allProjects    = @(Get-SshProjectList -LinuxHost $linuxHost -LinuxBase $linuxBase)
        $recentProjects = @(Get-RecentProjectNames -HistoryPath $historyPath -Tool $Tool -Mode 'ssh')

        return Show-ProjectSelector `
            -RecentProjects $recentProjects `
            -AllProjects    $allProjects `
            -BaseLabel      "${linuxHost}:$linuxBase"
    }
    else {
        $localBase = if ($Config.projectsDir) { $Config.projectsDir } else { 'D:\' }

        $allProjects    = @(Get-LocalProjectList -BaseDir $localBase)
        $recentProjects = @(Get-RecentProjectNames -HistoryPath $historyPath -Tool $Tool -Mode 'local')

        return Show-ProjectSelector `
            -RecentProjects $recentProjects `
            -AllProjects    $allProjects `
            -BaseLabel      $localBase
    }
}

function Invoke-LaunchAction {
    param(
        [object]$Config,
        [string]$Tool,
        [string]$Mode,
        [string]$ProjectRoot
    )

    Write-Host ""

    # ツール設定確認
    $toolConfig = $Config.tools.PSObject.Properties[$Tool]?.Value
    if (-not $toolConfig -or -not $toolConfig.enabled) {
        Write-Host ("  [WARN] {0} は config.json で無効化されています。" -f $Tool) -ForegroundColor Yellow
        Write-Host "         config/config.json の tools.$Tool.enabled を true に変更してください。" -ForegroundColor DarkGray
        Write-Host ""
        Wait-MenuInput
        return
    }

    $cmd  = $toolConfig.command
    $toolArgs = @($toolConfig.args)

    # コマンド存在確認
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Host ("  [ERROR] コマンドが見つかりません: {0}" -f $cmd) -ForegroundColor Red
        Write-Host ("          インストールコマンド: {0}" -f $toolConfig.installCommand) -ForegroundColor Yellow
        Write-Host ""
        Wait-MenuInput
        return
    }

    if ($Mode -eq 'ssh') {
        # ── SSH 起動 ────────────────────────────────────────
        $linuxHost = $Config.linuxHost
        $linuxBase = $Config.linuxBase

        if (-not $linuxHost -or $linuxHost -eq '<your-linux-host>') {
            Write-Host "  [ERROR] config.json の linuxHost が未設定です。" -ForegroundColor Red
            Wait-MenuInput
            return
        }

        # プロジェクト選択（一覧表示）
        $project    = Select-ProjectInteractive -Config $Config -Mode 'ssh' -Tool $Tool
        $remotePath = if ([string]::IsNullOrWhiteSpace($project)) {
            $linuxBase
        } else {
            "$linuxBase/$project"
        }

        $sshOptions = @()
        if ($Config.PSObject.Properties['ssh'] -and $Config.ssh.PSObject.Properties['options']) {
            $sshOptions = @($Config.ssh.options)
        }
        # Windows PowerShell から子プロセス経由で ssh を呼ぶと stdin がパイプ扱いになり
        # -t だけでは "stdin is not a terminal" で PTY 確保に失敗する。
        # -tt は stdin が TTY でなくても強制的に PTY を割り当てる。
        $sshOptions = @($sshOptions | Where-Object { $_ -ne '-t' })
        if ('-tt' -notin $sshOptions) {
            $sshOptions = @('-tt') + $sshOptions
        }

        # SSH ls 出力が CRLF を含む場合に備え Trim() でパスをクリーンにする
        # SSH デーモンが起動する bash がセッションリーダーかつ PTY の制御端末オーナー。
        # bash -l -i -c などでネストすると子 bash はセッションリーダーになれず
        # React-Ink TUI が /dev/tty を開けない。
        # プロファイルを直接 source して exec することで SSH の bash がそのまま
        # codex に置き換わり、/dev/tty が正しく引き継がれる。
        $cleanPath   = $remotePath.Trim()
        $toolArgsStr = ($toolArgs | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join ' '
        $profileSrc  = 'export TERM=xterm-256color; . ~/.bash_profile 2>/dev/null; . ~/.bashrc 2>/dev/null'
        $remoteCmd   = ($profileSrc + '; cd "' + $cleanPath + '" && exec ' + $cmd + ' ' + $toolArgsStr).TrimEnd()

        Write-Host ("  SSH 接続: {0} -> {1}" -f $linuxHost, $cleanPath) -ForegroundColor Cyan
        Write-Host ("  コマンド: {0}" -f $remoteCmd) -ForegroundColor DarkGray
        Write-Host ""

        # ssh -t $host "bash -l -c '...'" — ログイン環境 + PTY で起動
        & ssh @sshOptions $linuxHost $remoteCmd
        $exitCode = $LASTEXITCODE

    } else {
        # ── ローカル起動 ────────────────────────────────────
        $localBase = if ($Config.projectsDir) { $Config.projectsDir } else { 'D:\' }

        # プロジェクト選択（ディレクトリ一覧表示）
        $project = Select-ProjectInteractive -Config $Config -Mode 'local' -Tool $Tool
        $workDir = if ([string]::IsNullOrWhiteSpace($project)) {
            $localBase
        } else {
            Join-Path $localBase $project
        }

        if (-not (Test-Path $workDir)) {
            Write-Host ("  [ERROR] ディレクトリが見つかりません: {0}" -f $workDir) -ForegroundColor Red
            Write-Host ""
            Wait-MenuInput
            return
        }

        Write-Host ("  {0} を起動します: {1}" -f $cmd, $workDir) -ForegroundColor Green
        Write-Host ""

        $previous = Get-Location
        try {
            Set-Location $workDir

            # ★ カレントプロセスで直接実行（新 pwsh サブプロセスを作らない = TTY が継承される）
            & $cmd @toolArgs
            $exitCode = $LASTEXITCODE
        }
        finally {
            Set-Location $previous
        }
    }

    Write-Host ""
    if ($exitCode -ne 0) {
        Write-Host ("  [WARN] {0} が終了コード {1} で終了しました。" -f $cmd, $exitCode) -ForegroundColor Yellow
    } else {
        Write-Host ("  {0} が正常に終了しました。" -f $cmd) -ForegroundColor Green
    }

    # RecentProjects 更新（エラーは無視）
    try {
        $historyPath = $Config.recentProjects.historyFile
        if ($historyPath -and $Config.recentProjects.enabled) {
            $historyPath = [System.Environment]::ExpandEnvironmentVariables($historyPath)
            $result = if ($exitCode -eq 0) { 'success' } else { 'failure' }
            $projName = if ($project) { $project } else { 'default' }
            Update-RecentProject -ProjectName $projName -Tool $Tool -Mode $Mode `
                -Result $result -ElapsedMs 0 `
                -HistoryPath $historyPath -MaxHistory $Config.recentProjects.maxHistory `
                -ErrorAction SilentlyContinue
        }
    }
    catch { }

    Write-Host ""
    Wait-MenuInput
}

# ---------------------------------------------------------------
# ユーティリティ
# ---------------------------------------------------------------

function Wait-MenuInput {
    Write-Host "  [Enter] でメニューに戻ります..." -ForegroundColor DarkGray
    $null = Read-Host
}

# ---------------------------------------------------------------
# メインループ
# ---------------------------------------------------------------

function Start-InteractiveMenu {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Config,

        [string]$ProjectRoot = "",
        [string]$StatePath = "",
        [int]$MaxLoops = 0
    )

    $loopCount = 0
    $running = $true

    while ($running) {
        $loopCount++
        if ($MaxLoops -gt 0 -and $loopCount -gt $MaxLoops) {
            break
        }

        $items = Show-Menu -Config $Config -ProjectRoot $ProjectRoot
        $choice = Read-MenuChoice -Items $items

        if (-not $choice) {
            Write-Host "  [WARN] 無効な選択です。もう一度入力してください。" -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            continue
        }

        if ($choice.Action -eq 'exit') {
            Write-Host ""
            Write-Host "  終了します。" -ForegroundColor DarkGray
            Write-Host ""
            $running = $false
            break
        }

        $continue = Invoke-MenuAction -Item $choice -Config $Config `
            -ProjectRoot $ProjectRoot -StatePath $StatePath

        if (-not $continue) {
            $running = $false
        }
    }
}

Export-ModuleMember -Function @(
    'Get-MenuItems',
    'Write-MenuHeader',
    'Write-MenuSection',
    'Write-MenuItem',
    'Show-Menu',
    'Read-MenuChoice',
    'Invoke-MenuAction',
    'Start-InteractiveMenu',
    'Wait-MenuInput',
    'Get-LocalProjectList',
    'Get-SshProjectList',
    'Get-RecentProjectNames',
    'Show-ProjectSelector',
    'Select-ProjectInteractive'
)
