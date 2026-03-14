#Requires -Version 5.1
<#
.SYNOPSIS
    Installs dotfiles on Windows by copying files into their expected locations.
.DESCRIPTION
    Copies WezTerm, Starship, Neovim, PowerShell profile, AutoHotKey, and
    EditorConfig configs. To update after repo changes, re-run this script.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Helpers ---

function Copy-Config {
    param(
        [string]$Source,
        [string]$Dest
    )

    if (-not (Test-Path $Source)) {
        Write-Warning "  Skipping '$Dest' — source not found: $Source"
        return
    }

    $parentDir = Split-Path $Dest -Parent
    if ($parentDir -and -not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    if (Test-Path $Source -PathType Container) {
        # Use robocopy for directories — handles sparse/missing files gracefully.
        # Exit codes 0-7 are success; 8+ indicate errors.
        robocopy $Source $Dest /E /NFL /NDL /NJH /NJS | Out-Null
        if ($LASTEXITCODE -ge 8) {
            Write-Warning "  robocopy reported errors copying '$Source' (exit code: $LASTEXITCODE)"
            return
        }
    } else {
        Copy-Item -Path $Source -Destination $Dest -Force
    }
    Write-Host "  Copied: $Source -> $Dest"
}

# --- Main ---

$repoDir = $PSScriptRoot
Write-Host "Dotfiles repo: $repoDir"
Write-Host ""

# --- Neovim ---
Write-Host "Neovim..."
Copy-Config "$repoDir\nvim" "$env:LOCALAPPDATA\nvim"

# --- WezTerm ---
Write-Host "WezTerm..."
Copy-Config "$repoDir\wezterm\wezterm.lua" "$env:USERPROFILE\.config\wezterm\wezterm.lua"

# --- Starship ---
Write-Host "Starship..."
Copy-Config "$repoDir\starship\starship.toml" "$env:USERPROFILE\.config\starship\starship.toml"

# --- PowerShell Profile ---
Write-Host "PowerShell profile..."
Copy-Config "$repoDir\powershell\Microsoft.PowerShell_profile.ps1" $PROFILE

# --- EditorConfig ---
Write-Host "EditorConfig..."
Copy-Config "$repoDir\editorconfig\editorconfig" "$env:USERPROFILE\.editorconfig"

# --- AutoHotKey (launch at startup) ---
Write-Host "AutoHotKey..."
$startupDir = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ahkDest = "$startupDir\hotkeys.ahk"
Copy-Config "$repoDir\autohotkey\hotkeys.ahk" $ahkDest

Get-Process -Name 'AutoHotkey*' -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process $ahkDest
Write-Host "  Reloaded AutoHotKey"

# --- PSFzf ---
Write-Host "PSFzf..."
if (Get-Module -ListAvailable -Name PSFzf -ErrorAction SilentlyContinue) {
    Write-Host "  Already installed"
} else {
    Install-Module PSFzf -Scope CurrentUser -Force
    Write-Host "  Installed PSFzf"
}

# --- Done ---
Write-Host ""
Write-Host "Done!"
Write-Host "AutoHotKey will launch automatically on next login."
Write-Host "To start it now, run: & '$repoDir\autohotkey\hotkeys.ahk'"
