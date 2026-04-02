#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode("Slow")
InstallMouseHook()
InstallKeybdHook()

; Installer-managed feature flags. install.ps1 patches these values from
; %USERPROFILE%\dotkeys_config.toml after copying this file into place.
cfg_feature_corp_logins := false
cfg_feature_mouse_wiggle := false
cfg_feature_cisco_secure_client_vpn := false
cfg_feature_password_manager := false
cfg_feature_tmux_hotkeys := false
cfg_feature_f1f2f3_as_mouse_buttons := false

StrJoin(arr, sep) {
    out := ""
    for i, v in arr
        out .= (i > 1 ? sep : "") . v
    return out
}

g_corp_mode := (EnvGet("CORP_UID") != "")
g_uid := ""
g_password := ""
if (g_corp_mode) {
    g_uid := EnvGet("CORP_UID")
    g_password := EnvGet("CORP_PASSWORD")
    if ((cfg_feature_corp_logins || cfg_feature_cisco_secure_client_vpn) && g_password = "")
        MsgBox "CORP_PASSWORD environment variable is not set."
}

g_idle := false
g_autologin := true
g_autologin_saved := true
g_mouse_wiggle_allowed := (EnvGet("AHK_ENABLE_MOUSE_WIGGLE") != "false")

; Don't flood windows with gui events too fast.
SetMouseDelay(10)
SetTimer(do_loop, 1000)
Return  ; End of auto-execute section

check_idle()
{
    global g_idle
    g_idle := (A_TimeIdlePhysical > 7200000)
}

do_loop()
{
    global cfg_feature_cisco_secure_client_vpn, cfg_feature_mouse_wiggle, g_mouse_wiggle_allowed

    check_idle()

    if (cfg_feature_mouse_wiggle && g_mouse_wiggle_allowed)
        mouse_nudge()

    if (cfg_feature_cisco_secure_client_vpn)
        log_into_corp_vpn()
}

;g_vpn_log := A_ScriptDir . "\vpn_debug.log"
;VpnLog(msg) {
;    global g_vpn_log
;    FileAppend(A_Now " " . msg . "`n", g_vpn_log)
;}

log_into_corp_vpn()
{
    global g_autologin, g_corp_mode, g_idle, g_password, g_uid

    if (!g_corp_mode || g_idle || !g_autologin)
        return

    if (g_password = "")
        return

    static last_action_ms := 0

    try {
        SetTitleMatchMode(3)
        if (WinExist("Cisco Secure Client", "The secure gateway has terminated the VPN")) {
            WinActivate()
            ControlClick("Button1")
            SetTitleMatchMode(2)
            return
        }

        SetTitleMatchMode(1)
        if (WinExist("Cisco Secure Client | ")) {
            WinActivate()
            ControlSetText(g_uid, "Edit1")
            ControlSetText(g_password, "Edit2")
            ControlClick("Button1")
            last_action_ms := A_TickCount
            SetTitleMatchMode(2)
            return
        }

        if (A_TickCount - last_action_ms < 5000) {
            SetTitleMatchMode(2)
            return
        }

        SetTitleMatchMode(3)
        DetectHiddenWindows(true)
        if (WinExist("Cisco Secure Client", "AnyConnect VPN:")) {
            windowText := WinGetText("Cisco Secure Client", "AnyConnect VPN:")
            DetectHiddenWindows(false)
            if (InStr(windowText, "Connected to")) {
                SetTitleMatchMode(2)
                return
            }
        } else {
            DetectHiddenWindows(false)
        }

        SetTitleMatchMode(2)
        Run("C:\Program Files (x86)\Cisco\Cisco Secure Client\UI\csc_ui.exe")
        Sleep(1500)
        SetTitleMatchMode(3)
        if (WinExist("Cisco Secure Client", "AnyConnect VPN:")) {
            WinActivate("Cisco Secure Client", "AnyConnect VPN:")
            ControlClick("Button1", "Cisco Secure Client", "AnyConnect VPN:")
        }
        last_action_ms := A_TickCount
        SetTitleMatchMode(2)
    } catch as e {
        DetectHiddenWindows(false)
        SetTitleMatchMode(2)
        last_action_ms := A_TickCount
        ;VpnLog("ERROR: " e.Message " (line " e.Line ")")
    }
}

mouse_nudge()
{
    global g_idle

    static mouse_delta_x := 5
    static expected_x := ""
    static expected_y := ""

    if (g_idle || A_TimeIdlePhysical <= 500000) {
        expected_x := ""
        return
    }

    CoordMode("Mouse", "Screen")
    MouseGetPos(&cur_x, &cur_y)

    if (expected_x != "" && (cur_x != expected_x || cur_y != expected_y)) {
        expected_x := ""
        return
    }

    new_x := cur_x + mouse_delta_x
    MouseMove(new_x, cur_y, 10)
    expected_x := new_x
    expected_y := cur_y
    mouse_delta_x *= -1
}

; ^ = Ctrl
; + = Shift
; ! = Alt

; Diagnostic hotkey: Ctrl+Alt+D
; Shows all visible Cisco windows with their exact titles, visible text, and controls.
; Run this while a Cisco dialog is on screen to capture what AHK sees.
; This is just for debug.
; ^!d::
; {
;     SetTitleMatchMode(2)
;     out := "=== Cisco Windows ===`n"
;     DetectHiddenWindows(true)
;     for hwnd in WinGetList("Cisco") {
;         title := WinGetTitle(hwnd)
;         text  := WinGetText(hwnd)
;         out .= "`nTitle: [" title "]`n"
;         try {
;             pid := WinGetPID(hwnd)
;             exePath := ProcessGetPath(pid)
;             out .= "PID: " pid "  EXE: " exePath "`n"
;         } catch {
;             out .= "PID/EXE: (error)`n"
;         }
;         out .= "Text:`n" text "`n"
;         try {
;             controls := WinGetControls(hwnd)
;             out .= "Controls: " . (controls.Length > 0 ? StrJoin(controls, ", ") : "(none)") . "`n"
;         } catch {
;             out .= "Controls: (error)`n"
;         }
;         out .= "---`n"
;     }
;     DetectHiddenWindows(false)
;     if (out = "=== Cisco Windows ===`n")
;         out .= "(no Cisco windows found)`n"
;     diagGui := Gui(, "AHK Cisco Diagnostic")
;     diagGui.Add("Edit", "ReadOnly w600 h400 VScroll", out)
;     diagGui.Add("Button", "Default w80", "OK").OnEvent("Click", (*) => diagGui.Destroy())
;     diagGui.Show()
; }

; If you make any edits to this file, do a ctrl-alt-r to reload the script.
^!r::
{
    Reload
}

; Toggle all hotkeys on/off — exempt from suspension so it always works.
; Saves/restores g_autologin so VPN auto-login resumes its prior state on unpause.
#SuspendExempt
^!a::
{
    global g_autologin, g_autologin_saved

    Suspend(-1)
    if (A_IsSuspended) {
        g_autologin_saved := g_autologin
        g_autologin := false
        ToolTip("Hotkeys: PAUSED")
    } else {
        g_autologin := g_autologin_saved
        ToolTip("Hotkeys: ACTIVE")
    }
    SetTimer(() => ToolTip(), -1000)
}
#SuspendExempt False

#HotIf cfg_feature_cisco_secure_client_vpn && g_corp_mode
^!v::
{
    global g_autologin

    g_autologin := !g_autologin
    state := g_autologin ? "ON" : "OFF"
    ToolTip("VPN auto-login: " state)
    SetTimer(() => ToolTip(), -1000)
}
#HotIf

#HotIf cfg_feature_corp_logins && g_corp_mode
^!i::
{
    SendText(g_password)
    Send("{Tab}")
}

^!o::
{
    SendText(g_uid)
    Send("{Tab}")
    SendText(g_password)
    Send("{Enter}")
}

^!p::
{
    SendText(g_password)
    Send("{Enter}")
}
#HotIf

#HotIf cfg_feature_tmux_hotkeys
$*RAlt::
$*RWin::
{
    Send("^\z")
    if (InStr(A_ThisHotkey, "RWin"))
        KeyWait("RWin")
}

^;::
{
    Send("{Ctrl up}^\;{Ctrl down}")
}
#HotIf

#HotIf cfg_feature_password_manager
^!b::
{
    password := EnvGet("PWMANAGER_PASSWORD")
    if (password = "") {
        MsgBox "PWMANAGER_PASSWORD environment variable is not set."
        return
    }
    SendText(password)
    Send("{Enter}")
}
#HotIf

#HotIf cfg_feature_f1f2f3_as_mouse_buttons && (WinActive("ahk_exe mspaint.exe") || WinActive("ahk_exe etxc.exe") || WinActive("ahk_exe wezterm-gui.exe"))
F1::
{
    Send("{LButton Down}")
    KeyWait("F1")
    Send("{LButton Up}")
}

F2::
{
    Send("{RButton Down}")
    KeyWait("F2")
    Send("{RButton Up}")
}

F3::
{
    Send("{LButton 2}")
    Sleep(500)
    Send("{RButton}")
}
#HotIf
