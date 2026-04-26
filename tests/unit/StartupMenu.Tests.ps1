BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $script:RepoRoot "scripts\lib\LauncherCommon.psm1") -Force -DisableNameChecking
    Import-Module (Join-Path $script:RepoRoot "scripts\lib\Config.psm1")         -Force
    Import-Module (Join-Path $script:RepoRoot "scripts\lib\StartupMenu.psm1")    -Force

    function New-TestConfig {
        param(
            [string]$LinuxHost = '',
            [bool]$ClaudeEnabled = $false,
            [bool]$CodexEnabled = $true,
            [bool]$RecentEnabled = $true
        )
        return [pscustomobject]@{
            projectsDir    = "D:\"
            linuxHost      = $LinuxHost
            linuxBase      = "/home/user/Projects"
            tools          = [pscustomobject]@{
                defaultTool = "codex"
                claude      = [pscustomobject]@{ enabled = $ClaudeEnabled; command = "claude" }
                codex       = [pscustomobject]@{ enabled = $CodexEnabled;  command = "codex"  }
                copilot     = [pscustomobject]@{ enabled = $false;          command = "copilot" }
            }
            recentProjects = [pscustomobject]@{
                enabled     = $RecentEnabled
                historyFile = "%USERPROFILE%\.codex-startup\recent-projects.json"
            }
        }
    }
}

Describe "Get-MenuItems" {
    It "linuxHost 未設定時は SSH セクションが含まれない" {
        $config = New-TestConfig -LinuxHost ''
        $items = Get-MenuItems -Config $config
        $sshItems = @($items | Where-Object { $_.Key -like 'S*' })
        $sshItems.Count | Should -Be 0
    }

    It "linuxHost 設定時は SSH セクションが含まれる" {
        $config = New-TestConfig -LinuxHost '192.168.0.185'
        $items = Get-MenuItems -Config $config
        $sshItems = @($items | Where-Object { $_.Key -like 'S*' })
        $sshItems.Count | Should -BeGreaterThan 0
    }

    It "プレースホルダー linuxHost は SSH セクションを生成しない" {
        $config = New-TestConfig -LinuxHost '<your-linux-host>'
        $items = Get-MenuItems -Config $config
        $sshItems = @($items | Where-Object { $_.Key -like 'S*' })
        $sshItems.Count | Should -Be 0
    }

    It "ローカル Codex 起動項目が常に含まれる" {
        $config = New-TestConfig
        $items = Get-MenuItems -Config $config
        $l1 = $items | Where-Object { $_.Key -eq 'L1' }
        $l1 | Should -Not -BeNullOrEmpty
        $l1.Enabled | Should -BeTrue
    }

    It "Claude 無効時は L2 が Enabled=false" {
        $config = New-TestConfig -ClaudeEnabled $false
        $items = Get-MenuItems -Config $config
        $l2 = $items | Where-Object { $_.Key -eq 'L2' }
        $l2.Enabled | Should -BeFalse
    }

    It "終了項目 (Key=0) が常に含まれる" {
        $config = New-TestConfig
        $items = Get-MenuItems -Config $config
        $exit = $items | Where-Object { $_.Key -eq '0' }
        $exit | Should -Not -BeNullOrEmpty
        $exit.Action | Should -Be 'exit'
    }

    It "全項目に Key・Label・Action プロパティが含まれる" {
        $config = New-TestConfig
        $items = Get-MenuItems -Config $config
        foreach ($item in $items) {
            $item.Key    | Should -Not -BeNullOrEmpty
            $item.Label  | Should -Not -BeNullOrEmpty
            $item.Action | Should -Not -BeNullOrEmpty
        }
    }

    It "診断セクション項目（1〜8）が全て含まれる" {
        $config = New-TestConfig
        $items = Get-MenuItems -Config $config
        @('1','2','3','4','5','6','7','8') | ForEach-Object {
            $key = $_
            ($items | Where-Object { $_.Key -eq $key }) | Should -Not -BeNullOrEmpty -Because "Key=$key が見つからない"
        }
    }

    It "recentProjects.enabled=false の場合 Key=7 が Enabled=false" {
        $config = New-TestConfig -RecentEnabled $false
        $items = Get-MenuItems -Config $config
        $item7 = $items | Where-Object { $_.Key -eq '7' }
        $item7.Enabled | Should -BeFalse
    }
}

Describe "Show-Menu (非インタラクティブ検証)" {
    It "Show-Menu はエラーなく実行できる" {
        $config = New-TestConfig
        { Show-Menu -Config $config -ProjectRoot $script:RepoRoot } | Should -Not -Throw
    }

    It "Show-Menu はメニューアイテムのリストを返す" {
        $config = New-TestConfig
        $result = Show-Menu -Config $config -ProjectRoot $script:RepoRoot
        $result | Should -Not -BeNullOrEmpty
        @($result).Count | Should -BeGreaterThan 0
    }
}

Describe "Read-MenuChoice" {
    It "有効なキーを渡すと対応するアイテムを返す" {
        $config = New-TestConfig
        $items  = Get-MenuItems -Config $config
        $found  = $items | Where-Object { $_.Key -eq 'L1' }
        $found | Should -Not -BeNullOrEmpty
        $found.Action | Should -Be 'launch-local-codex'
    }

    It "無効なキーの場合は該当アイテムが見つからない" {
        $config = New-TestConfig
        $items  = Get-MenuItems -Config $config
        $found  = $items | Where-Object { $_.Key -eq 'ZZZ' -and $_.Enabled }
        $found | Should -BeNullOrEmpty
    }
}

Describe "Invoke-MenuAction (exit)" {
    It "exit アクションは false を返す" {
        $config   = New-TestConfig
        $exitItem = [pscustomobject]@{ Key = '0'; Label = '終了'; Action = 'exit'; Enabled = $true; Note = ''; Section = $null }
        $result   = Invoke-MenuAction -Item $exitItem -Config $config -ProjectRoot $script:RepoRoot
        $result | Should -BeFalse
    }

    It "有効なアクション（show-dashboard）は true を返す" {
        $config      = New-TestConfig
        $dashItem    = [pscustomobject]@{ Key = '1'; Label = 'DB'; Action = 'show-dashboard'; Enabled = $true; Note = ''; Section = $null }
        $result      = Invoke-MenuAction -Item $dashItem -Config $config `
                          -ProjectRoot $script:RepoRoot `
                          -StatePath   (Join-Path $script:RepoRoot "state.json")
        $result | Should -BeTrue
    }
}

Describe "Get-LocalProjectList" {
    It "有効なディレクトリでサブフォルダ一覧を返す" {
        $dir = $TestDrive
        New-Item -ItemType Directory -Path (Join-Path $dir "ProjectA") | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $dir "ProjectB") | Out-Null
        New-Item -ItemType File      -Path (Join-Path $dir "readme.txt") | Out-Null

        $result = @(Get-LocalProjectList -BaseDir $dir)
        $result | Should -Contain "ProjectA"
        $result | Should -Contain "ProjectB"
        $result | Should -Not -Contain "readme.txt"
    }

    It "存在しないディレクトリでは空配列を返す" {
        $result = @(Get-LocalProjectList -BaseDir "C:\nonexistent\xyz\abc")
        $result.Count | Should -Be 0
    }

    It "隠しディレクトリ（.dotdir）を除外する" {
        $dir = Join-Path $TestDrive "hidden_test"
        New-Item -ItemType Directory -Path $dir | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $dir ".hidden") | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $dir "Visible") | Out-Null

        $result = @(Get-LocalProjectList -BaseDir $dir)
        $result | Should -Not -Contain ".hidden"
        $result | Should -Contain "Visible"
    }

    It "MaxCount でリストを制限できる" {
        $dir = Join-Path $TestDrive "maxcount_test"
        New-Item -ItemType Directory -Path $dir | Out-Null
        1..10 | ForEach-Object {
            New-Item -ItemType Directory -Path (Join-Path $dir "Proj$_") | Out-Null
        }

        $result = @(Get-LocalProjectList -BaseDir $dir -MaxCount 5)
        $result.Count | Should -Be 5
    }

    It "返り値はソート済みである" {
        $dir = Join-Path $TestDrive "sort_test"
        New-Item -ItemType Directory -Path $dir | Out-Null
        @("Zebra", "Alpha", "Mango") | ForEach-Object {
            New-Item -ItemType Directory -Path (Join-Path $dir $_) | Out-Null
        }

        $result = @(Get-LocalProjectList -BaseDir $dir)
        $result[0] | Should -Be "Alpha"
        $result[1] | Should -Be "Mango"
        $result[2] | Should -Be "Zebra"
    }
}

Describe "Get-RecentProjectNames" {
    It "ヒストリファイルが存在しない場合は空配列を返す" {
        $result = @(Get-RecentProjectNames -HistoryPath "C:\nonexistent\history.json")
        $result.Count | Should -Be 0
    }

    It "ヒストリファイルが空文字列の場合は空配列を返す" {
        $result = @(Get-RecentProjectNames -HistoryPath "")
        $result.Count | Should -Be 0
    }
}

Describe "Get-SshProjectList" {
    It "接続できないホストでは空配列を返す（BatchMode + タイムアウト）" {
        $result = @(Get-SshProjectList -LinuxHost "240.0.0.1" -LinuxBase "/home/test" -TimeoutSeconds 2 -BatchMode)
        $result.Count | Should -Be 0
    }

    It "linuxBase がテンプレートデフォルト値の場合は空配列を返す" {
        $result = @(Get-SshProjectList -LinuxHost "anyhost" -LinuxBase "/home/user/Projects" -BatchMode)
        $result.Count | Should -Be 0
    }
}
