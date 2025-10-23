& ([ScriptBlock]::Create((oh-my-posh init pwsh --config "$env:USERPROFILE\.dotfiles\windows\shell\oh-my-posh\uew.omp.json" --print) -join "`n"))
$env:__SuppressProfilesLoadingMessage = $true

# Import the Chocolatey Profile for tab-completion support
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile"
}

Set-PSReadLineOption -BellStyle None
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -Colors @{ InlinePrediction = "Green" }

function ff {
    Push-Location "$env:USERPROFILE\.dotfiles\windows\shell\fastfetch"
    fastfetch -c "default.jsonc"
    Pop-Location
}

function y {
    $tmp = [System.IO.Path]::GetTempFileName()
    yazi $args --cwd-file="$tmp"
    $cwd = Get-Content -Path $tmp -Encoding UTF8
    if (-not [String]::IsNullOrEmpty($cwd) -and $cwd -ne $PWD.Path) {
        Set-Location -LiteralPath ([System.IO.Path]::GetFullPath($cwd))
    }
    Remove-Item -Path $tmp
}

clear
