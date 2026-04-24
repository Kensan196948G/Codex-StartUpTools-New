BeforeAll {
    $script:RepoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    Import-Module (Join-Path $script:RepoRoot "scripts\lib\ArchitectureCheck.psm1") -Force
}

Describe "Invoke-ArchitectureCheck" {
    It "空ディレクトリでは Passed=true" {
        $dir = Join-Path $TestDrive "empty"
        New-Item -ItemType Directory -Path $dir | Out-Null
        $result = Invoke-ArchitectureCheck -Path $dir
        $result.CheckedFiles | Should -Be 0
        $result.Passed | Should -BeTrue
    }

    It "ハードコード秘密情報を検出する" {
        $dir = Join-Path $TestDrive "secret"
        New-Item -ItemType Directory -Path $dir | Out-Null
        '$password = "SuperSecret1234"' | Set-Content -Path (Join-Path $dir "bad.ps1") -Encoding UTF8
        $result = Invoke-ArchitectureCheck -Path $dir
        $result.Violations.RuleId | Should -Contain "HARDCODED_SECRET"
        $result.Passed | Should -BeFalse
    }

    It "StrictMode 欠如を WARNING として検出する" {
        $dir = Join-Path $TestDrive "nostrict"
        New-Item -ItemType Directory -Path $dir | Out-Null
        'function Foo { }' | Set-Content -Path (Join-Path $dir "mod.psm1") -Encoding UTF8
        $result = Invoke-ArchitectureCheck -Path $dir
        $result.Violations.RuleId | Should -Contain "MISSING_STRICT_MODE"
        $result.Passed | Should -BeTrue
    }
}

Describe "Get-ArchitectureViolation" {
    It "Severity=CRITICAL で WARNING を返さない" {
        $dir = Join-Path $TestDrive "filter"
        New-Item -ItemType Directory -Path $dir | Out-Null
        '$secret = "hardcoded-password-123"' | Set-Content -Path (Join-Path $dir "mixed.psm1") -Encoding UTF8
        $result = @(Get-ArchitectureViolation -Path $dir -Severity "CRITICAL")
        @($result | Where-Object { $_.Severity -eq "WARNING" }).Count | Should -Be 0
    }
}
