BeforeAll {
    Import-Module "$PSScriptRoot\..\..\scripts\lib\LauncherCommon.psm1" -Force -DisableNameChecking
}

Describe "Find-AvailableDriveLetter" {
    It "使用中のドライブレターを返さない" {
        $usedLetters = @((Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue).Name)
        $result = Find-AvailableDriveLetter
        if ($result) {
            $result | Should -Not -BeIn $usedLetters
        }
    }

    It "PreferredLetters の優先順で返す" {
        $usedLetters = @((Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue).Name)
        $preferred = @("P", "Q", "R")
        $result = Find-AvailableDriveLetter -PreferredLetters $preferred
        if ($result) {
            $expectedFirst = $preferred | Where-Object { $_ -notin $usedLetters } | Select-Object -First 1
            $result | Should -Be $expectedFirst
        }
    }

    It "ExcludeLetters で除外できる" {
        $result = Find-AvailableDriveLetter -PreferredLetters @("P", "Q") -ExcludeLetters @("P")
        if ($result) {
            $result | Should -Not -Be "P"
        }
    }
}

Describe "Resolve-SshProjectsDir" {
    It "auto 以外の値はそのまま返す" {
        $config = [pscustomobject]@{
            sshProjectsDir = "P:\"
            projectsDirUnc = "\\server\share"
        }
        Resolve-SshProjectsDir -Config $config | Should -Be "P:\"
    }

    It "空文字列は auto として扱う" {
        $config = [pscustomobject]@{
            sshProjectsDir = ""
            projectsDirUnc = $null
        }
        Resolve-SshProjectsDir -Config $config | Should -Be "auto:unmapped"
    }

    It "auto で projectsDirUnc 未設定なら auto:unmapped を返す" {
        $config = [pscustomobject]@{
            sshProjectsDir = "auto"
            projectsDirUnc = $null
        }
        Resolve-SshProjectsDir -Config $config | Should -Be "auto:unmapped"
    }
}
