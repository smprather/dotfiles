# =============================================================================
# Navigation
# =============================================================================

$global:__prevLocation = $null

function Set-LocationEx {
    param([string]$Path = $env:USERPROFILE)
    if ($Path -eq '-') {
        if ($global:__prevLocation) {
            $prev = $global:__prevLocation
            $global:__prevLocation = (Get-Location).Path
            Set-Location $prev
        } else {
            Write-Warning "cd: no previous directory"
            return
        }
    } else {
        $global:__prevLocation = (Get-Location).Path
        Set-Location $Path
    }
    ls_func
}
Set-Alias -Name cd -Value Set-LocationEx -Option AllScope

function b    { Set-LocationEx .. }
function bb   { Set-LocationEx ..\.. }
function bbb  { Set-LocationEx ..\..\.. }
function bbbb { Set-LocationEx ..\..\..\.. }

function cdd {
    $dir = Get-ChildItem -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($dir) { Set-LocationEx $dir.FullName }
    else      { Write-Warning "No subdirectories found" }
}

function mkd {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-LocationEx $Path
}

# =============================================================================
# File operations
# =============================================================================

function touch {
    param([string]$Path)
    if (Test-Path $Path) { (Get-Item $Path).LastWriteTime = Get-Date }
    else                 { New-Item $Path -ItemType File | Out-Null }
}

function head {
    param([int]$n = 10, [string]$Path)
    if ($Path) { Get-Content $Path -TotalCount $n }
    else       { $input | Select-Object -First $n }
}

function tail {
    param([int]$n = 10, [string]$Path)
    if ($Path) { Get-Content $Path -Tail $n }
    else       { $input | Select-Object -Last $n }
}

# =============================================================================
# Search
# =============================================================================

function g    { rg --smart-case --search-zip --hidden --no-ignore @args }
function grep { rg --smart-case --search-zip --hidden --no-ignore @args }

function ls_func {
    $argList = @('--sort', 'modified', '--time', 'modified', '--long') + $args
    $proc = Start-Process 'eza' -ArgumentList $argList -NoNewWindow -PassThru
    if (-not $proc.WaitForExit(5000)) {
        $proc.Kill()
        Write-Warning "eza: timed out"
    }
}
function fd_func { fd --unrestricted --full-path @args }

# =============================================================================
# Utilities
# =============================================================================

function rps  { Start-Process PowerShell; exit }
function open { Invoke-Item @args }
function which { (Get-Command $args[0]).Path }

function Get-DefinitionPath {
    param([string]$Name)
    $command = Get-Command $Name -ErrorAction SilentlyContinue
    if (-not $command) { Write-Host "Command or function '$Name' not found."; return }
    switch ($command.CommandType) {
        'Function'    {
            if ($command.ScriptBlock.File) { Write-Host "Definition path: $($command.ScriptBlock.File)" }
            else                           { Write-Host "Function is defined in the current session." }
            Write-Host $command.Definition
        }
        'Application' { Write-Host "Definition path: $($command.Path)" }
        'Cmdlet'      { Write-Host "Cmdlet: $($command.Name)" }
        'Alias'       { Write-Host "Alias: $($command.Definition)"; Get-DefinitionPath $command.Definition }
        default       { Write-Host "Command type '$($command.CommandType)' is not supported." }
    }
}

# =============================================================================
# Aliases
# =============================================================================

Set-Alias -Name ls   -Value ls_func            -Option AllScope
Set-Alias -Name vi   -Value nvim               -Option AllScope
Set-Alias -Name f    -Value fd_func            -Option AllScope
Set-Alias -Name w    -Value Get-DefinitionPath -Option AllScope
Set-Alias -Name p    -Value Get-Location       -Option AllScope
Set-Alias -Name cat  -Value bat                -Option AllScope

# =============================================================================
# Interactive shell integrations
# =============================================================================

$profileIsInteractive = $Host.Name -in @('ConsoleHost', 'Visual Studio Code Host')
$profileIsSandbox = $env:USERNAME -eq 'CodexSandboxOffline'
$profileHasTerminalOutput = -not [Console]::IsOutputRedirected
$profileSupportsVT = $false
try {
    $profileSupportsVT = [bool]$Host.UI.SupportsVirtualTerminal
} catch {
    $profileSupportsVT = $false
}
$profileCanUsePromptTools = $profileIsInteractive -and -not $profileIsSandbox -and $profileHasTerminalOutput
$profileCanUsePSReadLine = $profileCanUsePromptTools -and $profileSupportsVT

if ($profileCanUsePSReadLine) {
    try {
        Set-PSReadLineOption -EditMode Emacs
        Set-PSReadLineOption -HistorySearchCursorMovesToEnd
        Set-PSReadLineOption -BellStyle None
        Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
        Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
        Set-PSReadLineKeyHandler -Key Tab       -Function MenuComplete
    } catch {
        Write-Verbose "PowerShell profile: skipped PSReadLine keybind setup due to terminal limitations."
        $profileCanUsePSReadLine = $false
    }

    # Inline prediction (requires PSReadLine 2.2+ / PS 7.2+)
    if ($profileCanUsePSReadLine) {
        try {
            Set-PSReadLineOption -PredictionSource HistoryAndPlugin
            Set-PSReadLineOption -PredictionViewStyle ListView
        } catch {
            Set-PSReadLineOption -PredictionSource History
        }
    }
}

if ($profileCanUsePromptTools) {
    # zoxide (smarter cd — use 'z' and 'zi' for interactive)
    if (Get-Command zoxide -ErrorAction SilentlyContinue) {
        try {
            Invoke-Expression (& { (zoxide init powershell | Out-String) })
        } catch {
            Write-Verbose "PowerShell profile: skipped zoxide initialization."
        }
    }

    # PSFzf — Ctrl+T file picker, Ctrl+R fuzzy history; falls back to built-in Ctrl+R if unavailable
    if ($profileCanUsePSReadLine) {
        if (Get-Module -ListAvailable -Name PSFzf -ErrorAction SilentlyContinue) {
            try {
                Import-Module PSFzf
                Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
            } catch {
                Write-Verbose "PowerShell profile: skipped PSFzf setup."
            }
        } else {
            try {
                Set-PSReadLineKeyHandler -Chord 'Ctrl+r' -Function ReverseSearchHistory
            } catch {
                Write-Verbose "PowerShell profile: skipped reverse search keybinding."
            }
        }
    }

    # Starship prompt
    if (Get-Command starship -ErrorAction SilentlyContinue) {
        try {
            Invoke-Expression (&starship init powershell)
        } catch {
            Write-Verbose "PowerShell profile: skipped Starship prompt."
        }
    }
}

