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

function Get-PluginBaseName {
    param([string]$FileName)

    if ($FileName -match '^(?<base>.+)\.ahk$') {
        return $Matches.base
    }
    if ($FileName -match '^(?<base>.+)\.ahk\..+$') {
        return $Matches.base
    }
    return $null
}

function Sync-AhkPlugins {
    param(
        [string]$RepoPluginsDir,
        [string]$DestPluginsDir
    )

    if (-not (Test-Path $RepoPluginsDir -PathType Container)) {
        return
    }

    if (-not (Test-Path $DestPluginsDir -PathType Container)) {
        New-Item -ItemType Directory -Path $DestPluginsDir -Force | Out-Null
    }

    $destByBase = @{}
    Get-ChildItem -Path $DestPluginsDir -File -ErrorAction SilentlyContinue | ForEach-Object {
        $base = Get-PluginBaseName $_.Name
        if (-not $base) {
            return
        }
        if (-not $destByBase.ContainsKey($base)) {
            $destByBase[$base] = @()
        }
        $destByBase[$base] += $_
    }

    Get-ChildItem -Path $RepoPluginsDir -File -ErrorAction SilentlyContinue | ForEach-Object {
        $src = $_
        $base = Get-PluginBaseName $src.Name
        if (-not $base) {
            return
        }

        $destMatches = @()
        if ($destByBase.ContainsKey($base)) {
            $destMatches = @($destByBase[$base])
        }

        if ($destMatches.Count -eq 0) {
            Copy-Config $src.FullName (Join-Path $DestPluginsDir $src.Name)
            $destByBase[$base] = @($src)
            return
        }

        $exactMatch = $destMatches | Where-Object { $_.Name -ceq $src.Name } | Select-Object -First 1
        if ($exactMatch) {
            return
        }

        $hasEnabledDest = @($destMatches | Where-Object { $_.Name -cmatch '\.ahk$' }).Count -gt 0
        $destNames = ($destMatches | ForEach-Object { $_.Name }) -join ', '

        if ($base -eq '99-personal-hotkeys' -and $hasEnabledDest) {
            return
        }

        if ($hasEnabledDest -and $src.Name -cnotmatch '\.ahk$') {
            Write-Host "  Skipping plugin '$($src.Name)' because enabled local variant exists: $destNames"
            return
        }

        Write-Host "  Skipping plugin '$($src.Name)' because local variant exists: $destNames"
    }
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
# $PROFILE only reflects the PS version running the installer. To cover all
# installed versions, we build candidate paths from every Documents root we
# can find (local and OneDrive-redirected), for both PS 5.1 (WindowsPowerShell)
# and PS 7+ (PowerShell) subdirs. We always install to $PROFILE, and install
# to the others only if their parent directory already exists (PS is there).
Write-Host "PowerShell profile..."
$psProfileSource = "$repoDir\powershell\Microsoft.PowerShell_profile.ps1"
$docRoots = @(
    [Environment]::GetFolderPath('MyDocuments'),  # real Documents (may be OneDrive)
    "$HOME\Documents"                              # local fallback
) | Sort-Object -Unique

$psProfileCandidates = @($PROFILE)
foreach ($root in $docRoots) {
    $psProfileCandidates += "$root\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
    $psProfileCandidates += "$root\PowerShell\Microsoft.PowerShell_profile.ps1"
}

$psProfileCandidates | Sort-Object -Unique | ForEach-Object {
    $profileDir = Split-Path $_ -Parent
    if ($_ -eq $PROFILE -or (Test-Path $profileDir)) {
        Copy-Config $psProfileSource $_
    }
}

# --- EditorConfig ---
Write-Host "EditorConfig..."
Copy-Config "$repoDir\editorconfig\editorconfig" "$env:USERPROFILE\.editorconfig"

# --- AutoHotKey (launch at startup via .lnk shortcut) ---
# AHK is not "installed" (avoids SentinelOne flagging the installer). Instead,
# we extract the AHK zip to $HOME and create a startup shortcut that calls
# AutoHotkey64.exe directly with the installed hotkeys.ahk as the argument.
Write-Host "AutoHotKey..."
$startupDir  = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
$ahkHomeDir  = "$HOME\autohotkey"
$ahkScript   = "$ahkHomeDir\hotkeys.ahk"
$ahkPluginsDir = "$ahkHomeDir\plugins"

Copy-Config "$repoDir\autohotkey\hotkeys.ahk" $ahkScript
Copy-Config "$repoDir\autohotkey\plugins\README.md" "$ahkPluginsDir\README.md"
Sync-AhkPlugins "$repoDir\autohotkey\plugins" $ahkPluginsDir

# Find existing extracted AutoHotkey directory in $HOME
$ahkDirs = @(Get-ChildItem -Path $HOME -Filter "AutoHotkey_*" -Directory -ErrorAction SilentlyContinue)
$ahkDir  = $null

if ($ahkDirs.Count -gt 1) {
    Write-Warning "  Multiple AutoHotkey directories found in $HOME."
    Write-Warning "  Remove all but one and re-run to set up AutoHotKey."
} elseif ($ahkDirs.Count -eq 1) {
    $ahkDir = $ahkDirs[0].FullName
    Write-Host "  Found existing AutoHotkey: $ahkDir"
} else {
    # Download latest stable release from GitHub
    Write-Host "  No AutoHotkey found — downloading latest stable release..."
    try {
        # $release  = Invoke-RestMethod "https://api.github.com/repos/AutoHotkey/AutoHotkey/releases/latest" -UseBasicParsing
        $zipAsset = $release.assets | Where-Object { $_.name -like "AutoHotkey_*.zip" } | Select-Object -First 1
        if (-not $zipAsset) { throw "No zip asset found in latest release." }

        $zipName = $zipAsset.name
        $dirName = [System.IO.Path]::GetFileNameWithoutExtension($zipName)
        $zipPath = Join-Path $HOME $zipName
        $ahkDir  = Join-Path $HOME $dirName

        Write-Host "  Downloading $zipName..."
        Invoke-WebRequest -Uri $zipAsset.browser_download_url -OutFile $zipPath -UseBasicParsing
        New-Item -ItemType Directory -Path $ahkDir -Force | Out-Null
        Expand-Archive -Path $zipPath -DestinationPath $ahkDir -Force
        Remove-Item $zipPath
        Remove-Item (Join-Path $ahkDir "AutoHotkey32.exe") -Force -ErrorAction SilentlyContinue
        Write-Host "  Extracted to $ahkDir"
    } catch {
        Write-Warning "  Failed to download AutoHotkey: $_"
    }
}

if ($ahkDir) {
    $ahkExe = Join-Path $ahkDir "AutoHotkey64.exe"
    if (-not (Test-Path $ahkExe)) {
        Write-Warning "  AutoHotkey64.exe not found in $ahkDir — skipping."
    } else {
        # Remove old .ahk copy from startup folder if present (would trigger "open with" dialog)
        $oldAhk = "$startupDir\hotkeys.ahk"
        if (Test-Path $oldAhk) { Remove-Item $oldAhk -Force }

        # Create .lnk startup shortcut: AutoHotkey64.exe "path\to\hotkeys.ahk"
        $shortcutPath = "$startupDir\hotkeys.lnk"
        $shell = New-Object -ComObject WScript.Shell
        $lnk = $shell.CreateShortcut($shortcutPath)
        $lnk.TargetPath       = $ahkExe
        $lnk.Arguments        = "`"$ahkScript`""
        $lnk.WorkingDirectory = Split-Path $ahkScript -Parent
        $lnk.Save()
        Write-Host "  Created startup shortcut: $shortcutPath -> $ahkExe"

        # Restart AHK now
        Get-Process -Name 'AutoHotkey*' -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Process -FilePath $ahkExe -ArgumentList "`"$ahkScript`""
        Write-Host "  AutoHotKey started"
        Write-Host "  AutoHotKey will launch automatically on next login via the startup shortcut."
    }
}

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
