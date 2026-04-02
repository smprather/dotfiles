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

function Get-RepoAhkPluginIds {
    param([string]$RepoPluginsDir)

    if (-not (Test-Path $RepoPluginsDir -PathType Container)) {
        return @()
    }

    $ids = @()
    Get-ChildItem -Path $RepoPluginsDir -File -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -ceq '_autoload_plugins.generated.ahk') {
            return
        }

        $base = Get-PluginBaseName $_.Name
        if (-not $base) {
            return
        }

        if ($_.Name -cnotmatch '\.ahk(\.disabled)?$') {
            return
        }

        if ($ids -cnotcontains $base) {
            $ids += $base
        }
    }

    return @($ids | Sort-Object)
}

function New-DotkeysConfig {
    param(
        [string]$ConfigPath,
        [string[]]$RepoPluginIds
    )

    $defaultEnabled = @()

    $commentedPlugins = @($RepoPluginIds | Where-Object { $defaultEnabled -notcontains $_ })

    $lines = @(
        'version = 1',
        '',
        '# This file is user-local and not shared from the repo.',
        '# Plugin enablement is managed here; manual renames in plugins\\ are overwritten by install.ps1.',
        '# Put personal one-off scripts in %USERPROFILE%\\autohotkey\\custom_plugins.',
        '',
        '[autohotkey]',
        'enabled = true',
        '',
        '[autohotkey.plugins]',
        'enabled = ['
    )

    foreach ($pluginId in $defaultEnabled) {
        $lines += "  `"$pluginId`","
    }

    foreach ($pluginId in $commentedPlugins) {
        $lines += "  # `"$pluginId`","
    }

    $lines += ']'

    $parent = Split-Path $ConfigPath -Parent
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    Set-Content -Path $ConfigPath -Value $lines -Encoding UTF8
    Write-Host "  Created default dotkeys config: $ConfigPath"
}

function Ensure-CustomAhkPlugins {
    param([string]$CustomPluginsDir)

    if (-not (Test-Path $CustomPluginsDir -PathType Container)) {
        New-Item -ItemType Directory -Path $CustomPluginsDir -Force | Out-Null
        Write-Host "  Created custom plugin directory: $CustomPluginsDir"
    }

    $personalPlugin = Join-Path $CustomPluginsDir '99-personal-hotkeys.ahk'
    if (-not (Test-Path $personalPlugin -PathType Leaf)) {
        $content = @(
            '; Personal AutoHotkey plugin file.'
        )
        Set-Content -Path $personalPlugin -Value $content -Encoding UTF8
        Write-Host "  Created starter personal plugin: $personalPlugin"
    }
}

function Get-DotkeysAhkConfig {
    param(
        [string]$ConfigPath,
        [string[]]$RepoPluginIds
    )

    $result = [PSCustomObject]@{
        AutoHotkeyEnabled = $true
        EnabledPluginIds  = @()
    }

    if (-not (Test-Path $ConfigPath -PathType Leaf)) {
        return $result
    }

    $currentSection = ''
    $inEnabledArray = $false
    $enabledPluginIds = @()

    Get-Content -Path $ConfigPath -ErrorAction Stop | ForEach-Object {
        $line = $_
        $trimmed = $line.Trim()

        if (-not $inEnabledArray -and $trimmed -match '^\[(?<section>[^\]]+)\]$') {
            $currentSection = $Matches.section
            return
        }

        if ($trimmed -eq '' -or $trimmed.StartsWith('#')) {
            return
        }

        if ($inEnabledArray) {
            if (-not $trimmed.StartsWith('#')) {
                $quoted = [regex]::Matches($line, '"([^"]+)"')
                foreach ($q in $quoted) {
                    $pluginId = $q.Groups[1].Value
                    if ($enabledPluginIds -notcontains $pluginId) {
                        $enabledPluginIds += $pluginId
                    }
                }
            }

            if ($line -match '\]') {
                $inEnabledArray = $false
            }
            return
        }

        if ($currentSection -ceq 'autohotkey' -and $trimmed -match '^enabled\s*=\s*(?<value>true|false)\b') {
            $result.AutoHotkeyEnabled = ($Matches.value -ceq 'true')
            return
        }

        if ($currentSection -ceq 'autohotkey.plugins' -and $trimmed -match '^enabled\s*=\s*\[(?<rest>.*)$') {
            $rest = $Matches.rest
            $quoted = [regex]::Matches($rest, '"([^"]+)"')
            foreach ($q in $quoted) {
                $pluginId = $q.Groups[1].Value
                if ($enabledPluginIds -notcontains $pluginId) {
                    $enabledPluginIds += $pluginId
                }
            }

            if ($rest -notmatch '\]') {
                $inEnabledArray = $true
            }
            return
        }
    }

    $unknown = @($enabledPluginIds | Where-Object { $RepoPluginIds -notcontains $_ })
    foreach ($pluginId in $unknown) {
        Write-Warning "  dotkeys_config.toml enables unknown plugin '$pluginId' (not found in repo); ignoring."
    }

    $result.EnabledPluginIds = @($enabledPluginIds | Where-Object { $RepoPluginIds -contains $_ })
    return $result
}

function Sync-AhkPlugins {
    param(
        [string]$RepoPluginsDir,
        [string]$DestPluginsDir,
        [string[]]$EnabledPluginIds,
        [string]$ConfigPath
    )

    if (-not (Test-Path $RepoPluginsDir -PathType Container)) {
        return
    }

    if (-not (Test-Path $DestPluginsDir -PathType Container)) {
        New-Item -ItemType Directory -Path $DestPluginsDir -Force | Out-Null
    }

    $enabledSet = @{}
    foreach ($pluginId in $EnabledPluginIds) {
        $enabledSet[$pluginId] = $true
    }

    $repoByBase = @{}
    Get-ChildItem -Path $RepoPluginsDir -File -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -ceq '_autoload_plugins.generated.ahk') {
            return
        }

        $base = Get-PluginBaseName $_.Name
        if (-not $base) {
            return
        }

        if ($_.Name -cnotmatch '\.ahk(\.disabled)?$') {
            return
        }

        if (-not $repoByBase.ContainsKey($base)) {
            $repoByBase[$base] = $_
            return
        }

        if ($repoByBase[$base].Name -cnotmatch '\.disabled$' -and $_.Name -cmatch '\.disabled$') {
            $repoByBase[$base] = $_
        }
    }

    $expectedPaths = @()

    foreach ($base in @($repoByBase.Keys | Sort-Object)) {
        $src = $repoByBase[$base]
        $destEnabled = Join-Path $DestPluginsDir ($base + '.ahk')
        $destDisabled = Join-Path $DestPluginsDir ($base + '.ahk.disabled')
        $shouldEnable = $enabledSet.ContainsKey($base)

        $hadEnabled = Test-Path $destEnabled
        $hadDisabled = Test-Path $destDisabled

        if ($hadEnabled -and -not $shouldEnable) {
            Write-Warning "  Plugin '$base' is currently enabled by filename but config sets it disabled; installer will disable it. Update $ConfigPath to keep it enabled."
        }

        if ($hadDisabled -and $shouldEnable) {
            Write-Host "  Plugin '$base' is currently disabled by filename but config enables it; installer will enable it."
        }

        $destPath = if ($shouldEnable) { $destEnabled } else { $destDisabled }
        $otherPath = if ($shouldEnable) { $destDisabled } else { $destEnabled }
        $expectedPaths += $destPath

        Copy-Config $src.FullName $destPath

        if ((Test-Path $otherPath) -and ($otherPath -cne $destPath)) {
            Remove-Item -Path $otherPath -Force
            Write-Host "  Removed alternate plugin variant: $otherPath"
        }
    }

    $expectedSet = @{}
    foreach ($p in $expectedPaths) {
        $expectedSet[$p.ToLowerInvariant()] = $true
    }

    Get-ChildItem -Path $DestPluginsDir -File -ErrorAction SilentlyContinue | ForEach-Object {
        if ($_.Name -ceq 'README.md') {
            return
        }

        if ($_.Name -ceq '_autoload_plugins.generated.ahk') {
            Remove-Item -Path $_.FullName -Force
            Write-Host "  Removed generated plugin include file: $($_.FullName)"
            return
        }

        if ($_.Name -cnotmatch '\.ahk(\..+)?$') {
            return
        }

        if (-not $expectedSet.ContainsKey($_.FullName.ToLowerInvariant())) {
            Remove-Item -Path $_.FullName -Force
            Write-Host "  Removed non-repo plugin file from managed dir: $($_.FullName)"
        }
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
$ahkCustomPluginsDir = "$ahkHomeDir\custom_plugins"
$dotkeysConfigPath = Join-Path $HOME 'dotkeys_config.toml'
$repoAhkPluginsDir = "$repoDir\autohotkey\plugins"

$repoPluginIds = Get-RepoAhkPluginIds $repoAhkPluginsDir
if (-not (Test-Path $dotkeysConfigPath -PathType Leaf)) {
    New-DotkeysConfig -ConfigPath $dotkeysConfigPath -RepoPluginIds $repoPluginIds
}

$dotkeysAhkConfig = Get-DotkeysAhkConfig -ConfigPath $dotkeysConfigPath -RepoPluginIds $repoPluginIds
Write-Host "  Using config: $dotkeysConfigPath"

Copy-Config "$repoDir\autohotkey\hotkeys.ahk" $ahkScript
Copy-Config "$repoAhkPluginsDir\README.md" "$ahkPluginsDir\README.md"
Ensure-CustomAhkPlugins -CustomPluginsDir $ahkCustomPluginsDir

Write-Host "  Note: plugins\ is installer-managed and mirrors repo plugins."
Write-Host "  Note: manual plugin renames in plugins\ are overwritten; use dotkeys_config.toml or custom_plugins\."

if ($dotkeysAhkConfig.AutoHotkeyEnabled) {
    Sync-AhkPlugins -RepoPluginsDir $repoAhkPluginsDir -DestPluginsDir $ahkPluginsDir -EnabledPluginIds $dotkeysAhkConfig.EnabledPluginIds -ConfigPath $dotkeysConfigPath
    if ($dotkeysAhkConfig.EnabledPluginIds.Count -gt 0) {
        Write-Host "  Enabled AHK plugins: $($dotkeysAhkConfig.EnabledPluginIds -join ', ')"
    } else {
        Write-Host "  Enabled AHK plugins: (none)"
    }
} else {
    Write-Host "  AutoHotKey plugin sync disabled by dotkeys_config.toml"
}

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
