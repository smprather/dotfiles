#Requires -Version 5.1
# Opens a WezTerm tab/window and SSHes to $env:CORP_LINUX_SSH.
# If WezTerm is already running, spawns a new tab; otherwise starts a new window.

$ssh = $env:CORP_LINUX_SSH
if (-not $ssh) {
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
    [System.Windows.Forms.MessageBox]::Show(
        'CORP_LINUX_SSH environment variable is not set.', 'WezTerm Corp SSH',
        'OK', 'Warning') | Out-Null
    exit 1
}

$weztermGui = (Get-Command wezterm-gui.exe -ErrorAction SilentlyContinue)?.Source
if (-not $weztermGui) {
    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms') | Out-Null
    [System.Windows.Forms.MessageBox]::Show(
        'wezterm-gui.exe not found in PATH.', 'WezTerm Corp SSH',
        'OK', 'Warning') | Out-Null
    exit 1
}

if (Get-Process -Name wezterm-gui -ErrorAction SilentlyContinue) {
    $weztermCli = (Get-Command wezterm.exe -ErrorAction SilentlyContinue)?.Source
    if ($weztermCli) {
        & $weztermCli cli spawn -- ssh $ssh
        exit
    }
}

& $weztermGui start -- ssh $ssh
