@echo off
setlocal EnableDelayedExpansion
chcp 65001 > nul 2>&1

:: ============================================================
:: Codex StartUp Tools - メインランチャー
:: 右クリック「管理者として実行」対応
:: ============================================================

:: 管理者権限チェック・自動昇格
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo [INFO] 管理者権限が必要です。UAC プロンプトを表示します...
    powershell -NoProfile -Command ^
        "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b 0
)

:: プロジェクトルートに移動
cd /d "%~dp0"

:: PowerShell 7+ の確認
where pwsh >nul 2>&1
if %errorLevel% NEQ 0 (
    echo [ERROR] PowerShell 7 ^(pwsh^) が見つかりません。
    echo         https://github.com/PowerShell/PowerShell からインストールしてください。
    pause
    exit /b 1
)

:: 起動スクリプトの確認
if not exist "scripts\main\Start-Codex.ps1" (
    echo [ERROR] scripts\main\Start-Codex.ps1 が見つかりません。
    echo         リポジトリが正しくクローンされているか確認してください。
    pause
    exit /b 1
)

:: ダッシュボード表示 + Codex 起動
echo.
echo  ============================================
echo   Codex StartUp Tools
echo  ============================================
echo.
echo  プロジェクト: %~dp0
echo  起動時刻    : %DATE% %TIME%
echo.

pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass ^
     -File "scripts\main\Start-Codex.ps1"

set EXIT_CODE=%errorLevel%

if %EXIT_CODE% NEQ 0 (
    echo.
    echo [WARN] 起動スクリプトが終了コード %EXIT_CODE% で終了しました。
    echo.
    pause
)

exit /b %EXIT_CODE%
