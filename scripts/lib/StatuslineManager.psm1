Set-StrictMode -Version Latest

function Get-GlobalStatusLineConfig {
    param([string]$SettingsPath = "")

    if ([string]::IsNullOrWhiteSpace($SettingsPath)) {
        $SettingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"
    }

    if (-not (Test-Path $SettingsPath)) {
        return [pscustomobject]@{
            found      = $false
            path       = $SettingsPath
            statusLine = $null
            raw        = $null
        }
    }

    try {
        $content = Get-Content $SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $statusLine = if ($content.PSObject.Properties.Name -contains "statusLine") { $content.statusLine } else { $null }
        return [pscustomobject]@{
            found      = $true
            path       = $SettingsPath
            statusLine = $statusLine
            raw        = $content
        }
    }
    catch {
        throw "設定ファイルの解析に失敗しました: $SettingsPath ($($_.Exception.Message))"
    }
}

function Invoke-RemoteSettingsSync {
    param(
        [Parameter(Mandatory)]
        [string]$LinuxHost,

        [Parameter(Mandatory)]
        [object]$StatusLine,

        [switch]$Backup
    )

    $jsonPayload = $StatusLine | ConvertTo-Json -Depth 10 -Compress
    $base64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($jsonPayload))
    $backupLine = if ($Backup) {
        'if [ -f "$TARGET" ]; then cp "$TARGET" "$TARGET.bak-$(date +%Y%m%d-%H%M%S)"; fi'
    }
    else {
        ""
    }

    $script = @"
set -e
TARGET="`$HOME/.claude/settings.json"
mkdir -p "`$(dirname "`$TARGET")"
$backupLine
if [ ! -f "`$TARGET" ]; then
  echo "{}" > "`$TARGET"
fi
python3 - "`$TARGET" "$base64" <<'PYEOF'
import json, sys, base64
path = sys.argv[1]
status_line = json.loads(base64.b64decode(sys.argv[2]).decode('utf-8'))
try:
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception:
    data = {}
data['statusLine'] = status_line
with open(path, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
print('[OK] statusLine applied:', path)
PYEOF
"@

    $sshExe = if ($env:AI_STARTUP_SSH_EXE) { $env:AI_STARTUP_SSH_EXE } else { "ssh" }
    $processStartInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $processStartInfo.FileName = $sshExe
    $processStartInfo.Arguments = "-T -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new -o ControlMaster=no $LinuxHost `"bash -s`""
    $processStartInfo.UseShellExecute = $false
    $processStartInfo.RedirectStandardInput = $true

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $processStartInfo
    [void]$process.Start()
    $process.StandardInput.NewLine = "`n"
    $process.StandardInput.Write(($script -replace "`r`n", "`n"))
    $process.StandardInput.WriteLine()
    $process.StandardInput.Close()
    $process.WaitForExit()
    return $process.ExitCode
}

Export-ModuleMember -Function Get-GlobalStatusLineConfig, Invoke-RemoteSettingsSync
