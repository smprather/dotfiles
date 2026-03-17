#Requires -Version 5.1
# Opens a new WezTerm window and SSHes to $env:CORP_LINUX_SSH using WezTerm's built-in SSH.

$ssh = $env:CORP_LINUX_SSH
if (-not $ssh) {
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
    [System.Windows.Forms.MessageBox]::Show(
        'CORP_LINUX_SSH environment variable is not set.', 'WezTerm Corp SSH',
        'OK', 'Warning') | Out-Null
    exit 1
}

$weztermCli = (Get-Command wezterm.exe -ErrorAction SilentlyContinue)?.Source
if (-not $weztermCli) {
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
    [System.Windows.Forms.MessageBox]::Show(
        'wezterm.exe not found in PATH.', 'WezTerm Corp SSH',
        'OK', 'Warning') | Out-Null
    exit 1
}

Start-Process -FilePath $weztermCli -ArgumentList @('ssh', $ssh)
