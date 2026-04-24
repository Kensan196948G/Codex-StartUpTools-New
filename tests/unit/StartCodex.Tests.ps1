BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $script:StartScript = Join-Path $script:RepoRoot "scripts\main\Start-Codex.ps1"

    function New-TestConfigFile {
        param(
            [string]$Path,
            [string]$ProjectsDir,
            [string]$Command = "pwsh"
        )

        $config = [ordered]@{
            version        = "1.0.0"
            projectsDir    = $ProjectsDir
            sshProjectsDir = "auto"
            projectsDirUnc = "\\server\share"
            linuxHost      = "host"
            linuxBase      = "/home/user/Projects"
            tools          = [ordered]@{
                defaultTool = "codex"
                claude      = [ordered]@{
                    enabled        = $false
                    command        = "claude"
                    args           = @()
                    installCommand = "npm install -g @anthropic-ai/claude-code"
                    env            = [ordered]@{}
                    apiKeyEnvVar   = "ANTHROPIC_API_KEY"
                }
                codex       = [ordered]@{
                    enabled        = $true
                    command        = $Command
                    args           = @("-NoProfile", "-Command", "exit 0")
                    installCommand = "npm install -g @openai/codex"
                    env            = [ordered]@{}
                    apiKeyEnvVar   = "OPENAI_API_KEY"
                }
                copilot     = [ordered]@{
                    enabled        = $false
                    command        = "copilot"
                    args           = @()
                    installCommand = "npm install -g @github/copilot"
                    env            = [ordered]@{}
                }
            }
            recentProjects = [ordered]@{
                enabled     = $true
                maxHistory  = 10
                historyFile = (Join-Path $TestDrive "recent-projects.json")
            }
        }

        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $Path -Encoding UTF8
    }
}

Describe "Start-Codex" {
    BeforeEach {
        $script:ProjectRoot = Join-Path $TestDrive "projects"
        $script:ProjectPath = Join-Path $script:ProjectRoot "DemoProject"
        $script:ConfigPath = Join-Path $TestDrive "config.json"
        $script:StatePath = Join-Path $TestDrive "state.json"

        New-Item -ItemType Directory -Path $script:ProjectPath -Force | Out-Null
        New-TestConfigFile -Path $script:ConfigPath -ProjectsDir $script:ProjectRoot
    }

    It "DryRun で起動計画を表示する" {
        $env:AI_STARTUP_CONFIG_PATH = $script:ConfigPath
        $env:AI_STARTUP_STATE_PATH = $script:StatePath

        $output = & pwsh -NoProfile -File $script:StartScript -Project "DemoProject" -NonInteractive -DryRun 2>&1
        $exitCode = $LASTEXITCODE
        $pathPattern = [regex]::Escape($script:ProjectPath)

        $exitCode | Should -Be 0
        ($output -join "`n") | Should -Match "Codex Launch Plan"
        ($output -join "`n") | Should -Match $pathPattern
    }

    It "存在しない project を拒否する" {
        $env:AI_STARTUP_CONFIG_PATH = $script:ConfigPath
        $env:AI_STARTUP_STATE_PATH = $script:StatePath

        $output = & pwsh -NoProfile -File $script:StartScript -Project "MissingProject" -NonInteractive -DryRun 2>&1
        $exitCode = $LASTEXITCODE

        $exitCode | Should -Be 1
        ($output -join "`n") | Should -Match "作業ディレクトリが見つかりません"
    }

    It "実行成功時に recent-projects を更新する" {
        $env:AI_STARTUP_CONFIG_PATH = $script:ConfigPath
        $env:AI_STARTUP_STATE_PATH = $script:StatePath

        & pwsh -NoProfile -File $script:StartScript -Project "DemoProject" -NonInteractive | Out-Null
        $exitCode = $LASTEXITCODE

        $exitCode | Should -Be 0
        $recent = Get-Content -Path (Join-Path $TestDrive "recent-projects.json") -Raw | ConvertFrom-Json
        @($recent.projects).Count | Should -Be 1
        $recent.projects[0].project | Should -Be "DemoProject"
        $recent.projects[0].tool | Should -Be "codex"
        $state = Get-Content -Path $script:StatePath -Raw | ConvertFrom-Json
        $state.execution.phase | Should -Be "Development"
        $state.execution.current_project | Should -Be "DemoProject"
    }

    AfterEach {
        Remove-Item Env:AI_STARTUP_CONFIG_PATH -ErrorAction SilentlyContinue
        Remove-Item Env:AI_STARTUP_STATE_PATH -ErrorAction SilentlyContinue
    }
}
