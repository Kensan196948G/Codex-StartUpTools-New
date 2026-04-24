Set-StrictMode -Version Latest

function Get-StartupRoot {
    param(
        [Parameter(Mandatory)]
        [string]$PSScriptRootPath
    )

    return (Split-Path -Parent (Split-Path -Parent $PSScriptRootPath))
}

function Get-StartupConfigPath {
    param(
        [Parameter(Mandatory)]
        [string]$StartupRoot
    )

    if ($env:AI_STARTUP_CONFIG_PATH) {
        return $env:AI_STARTUP_CONFIG_PATH
    }

    return (Join-Path $StartupRoot "config\config.json")
}

function Import-LauncherConfig {
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "設定ファイルが見つかりません: $ConfigPath"
    }

    return (Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Find-AvailableDriveLetter {
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [string[]]$PreferredLetters = @("P", "Q", "R", "S", "T", "U", "V", "W", "Y"),
        [string[]]$ExcludeLetters = @()
    )

    $usedLetters = @((Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue).Name)

    foreach ($letter in $PreferredLetters) {
        if ($letter -notin $usedLetters -and $letter -notin $ExcludeLetters) {
            return $letter
        }
    }

    for ($code = [int][char]"Z"; $code -ge [int][char]"D"; $code--) {
        $letter = [char]$code
        if ("$letter" -notin $usedLetters -and "$letter" -notin $ExcludeLetters) {
            return "$letter"
        }
    }

    return $null
}

function Resolve-SshProjectsDir {
    [CmdletBinding()]
    [OutputType([System.String])]
    param(
        [Parameter(Mandatory)]
        [object]$Config
    )

    $sshDir = $Config.sshProjectsDir

    if ([string]::IsNullOrWhiteSpace($sshDir) -or $sshDir -eq "auto") {
        $uncPath = $Config.projectsDirUnc
        if (-not [string]::IsNullOrWhiteSpace($uncPath)) {
            $existingDrive = Get-SmbMapping -ErrorAction SilentlyContinue |
                Where-Object { $_.RemotePath -eq $uncPath -and $_.Status -eq "OK" } |
                Select-Object -First 1

            if ($existingDrive) {
                $letter = ($existingDrive.LocalPath -replace ":", "")
                Write-Host "[INFO]  既存マッピング検出: ${letter}:\ -> $uncPath" -ForegroundColor Cyan
                return "${letter}:\"
            }
        }

        $letter = Find-AvailableDriveLetter
        if (-not $letter) {
            throw "空きドライブレターが見つかりません。config.json の sshProjectsDir に明示的なドライブレターを指定してください。"
        }

        if (-not [string]::IsNullOrWhiteSpace($uncPath)) {
            try {
                $null = New-PSDrive -Name $letter -PSProvider FileSystem -Root $uncPath -Persist -Scope Global -ErrorAction Stop
                Write-Host "[INFO]  ドライブ自動マッピング: ${letter}:\ -> $uncPath" -ForegroundColor Green
            }
            catch {
                Write-Warning "ドライブ自動マッピングに失敗しました (${letter}: -> $uncPath): $_"
                Write-Host "[INFO]  SSH 直接接続にフォールバックします。" -ForegroundColor Yellow
                return "auto:unmapped"
            }
        }
        else {
            Write-Host "[INFO]  projectsDirUnc 未設定のため、SSH 直接接続を使用します。" -ForegroundColor Yellow
            return "auto:unmapped"
        }

        return "${letter}:\"
    }

    return $sshDir
}

function Get-LauncherModeName {
    param([switch]$Local)

    if ($Local) {
        return "local"
    }

    return "ssh"
}

function Get-LauncherShell {
    if (Get-Command pwsh -ErrorAction SilentlyContinue) {
        return "pwsh.exe"
    }

    return "powershell.exe"
}

Export-ModuleMember -Function @(
    "Get-StartupRoot",
    "Get-StartupConfigPath",
    "Import-LauncherConfig",
    "Find-AvailableDriveLetter",
    "Resolve-SshProjectsDir",
    "Get-LauncherModeName",
    "Get-LauncherShell"
)
