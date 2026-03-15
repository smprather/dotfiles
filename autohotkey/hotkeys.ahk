#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode("Slow")
InstallMouseHook()
InstallKeybdHook()

StrJoin(arr, sep) {
    out := ""
    for i, v in arr
        out .= (i > 1 ? sep : "") . v
    return out
}

; Corp mode: detected by presence of CORP_UID env var.
; When in corp mode, load credentials and enable VPN autologin + mouse nudge.
g_corp_mode := (EnvGet("CORP_UID") != "")
g_uid := ""
g_password := ""
if (g_corp_mode) {
    g_uid := EnvGet("CORP_UID")
    g_password := EnvGet("CORP_PASSWORD")
    if (g_password = "")
        MsgBox "CORP_PASSWORD environment variable is not set."
}
g_idle := false
g_autologin := true
g_autologin_saved := true

;while true {
;    ih := InputHook("L1", "{LControl}{RControl}{LAlt}{RAlt}{LShift}{RShift}{LWin}{RWin}{AppsKey}"
;        . "{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}"
;        . "{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}"
;        . "{CapsLock}{NumLock}{PrintScreen}{Pause}")
;    ih.Start()
;    ih.Wait()  ; Wait for one keystroke/end key
;
;    key := (ih.EndKey != "") ? ih.EndKey : ih.Input;
;
;    ; In v2, Asc() -> Ord()
;    MsgBox(Ord(key), "ASCII for " key, "Iconi")
;}



; Put testing code here and uncomment the Return
;#Warn All, Off
;SetTitleMatchMode 3
;if (WinExist("Cisco Secure Client"))
;{
;    MsgBox("asdf")
;}
;SetTitleMatchMode 2
;Return

; Don't flood windows with gui events too fast
SetMouseDelay(10)

; Continuously execute these every XXXX msG
SetTimer(do_loop, 1000)
;SetTimer(check_idle, 1000)
Return  ; End of auto-execute section

check_idle()
{
    global g_idle
    if (A_TimeIdlePhysical > 7200000)
    {
        g_idle := true
    } else {
        g_idle := false
    }
}

do_loop()
{
    global g_corp_mode
    check_idle()
    if (g_corp_mode) {
        mouse_nudge()
        log_into_corp_vpn()
    }
}

log_into_corp_vpn()
{
    global g_idle, g_autologin, g_uid, g_password

    ; Skip if user is idle (away from desk) or auto-login is toggled off (Ctrl+Alt+V)
    if (g_idle || !g_autologin)
        Return

    ; Cooldown: act at most once every 5 seconds (cases 2 and 3 only).
    ; Case 1 (credential prompt) bypasses the cooldown — it must respond immediately.
    static last_action_ms := 0

    try {

    ; --- Case 1: Credential prompt is visible → fill username/password and submit ---
    ; Title starts with "Cisco Secure Client | " (e.g. "Cisco Secure Client | foo.bar.com")
    ; Edit1 = Username, Edit2 = Password, Button1 = OK
    SetTitleMatchMode(1)
    if (WinExist("Cisco Secure Client | ")) {
        WinActivate()
        ControlSetText(g_uid, "Edit1")
        ControlSetText(g_password, "Edit2")
        ControlClick("Button1")
        last_action_ms := A_TickCount
        SetTitleMatchMode(2)
        Return
    }

    ; Cases 2 and 3 are rate-limited to avoid frenzy-looping.
    if (A_TickCount - last_action_ms < 5000) {
        SetTitleMatchMode(2)
        Return
    }

    ; --- Case 2: Check connection state, bring window forward, click Connect ---
    SetTitleMatchMode(3)
    DetectHiddenWindows(true)
    if (WinExist("Cisco Secure Client")) {
        windowText := WinGetText("Cisco Secure Client")
        DetectHiddenWindows(false)
        if (InStr(windowText, "Connected to")) {
            SetTitleMatchMode(2)
            Return  ; Already connected — nothing to do
        }
    } else {
        DetectHiddenWindows(false)
    }

    ; Not connected — bring window forward, wait for it to render, then click Connect.
    ; csc_ui.exe is single-instance: re-running it restores/shows the existing window.
    SetTitleMatchMode(2)
    Run("C:\Program Files (x86)\Cisco\Cisco Secure Client\UI\csc_ui.exe")
    Sleep(1500)
    SetTitleMatchMode(3)
    if (WinExist("Cisco Secure Client")) {
        WinActivate("Cisco Secure Client")
        ControlClick("Button1", "Cisco Secure Client")  ; Connect button
    }
    last_action_ms := A_TickCount
    SetTitleMatchMode(2)

    } catch as e {
        DetectHiddenWindows(false)
        SetTitleMatchMode(2)
        last_action_ms := A_TickCount
    }
}

; Disable auto-locking by wiggling mouse.
; Uses position tracking instead of A_TimeIdlePhysical to detect user movement —
; A_TimeIdlePhysical is unreliable here because MouseMove resets it at the hook level.
mouse_nudge()
{
    static mouse_delta_x := 5
    static expected_x := ""
    static expected_y := ""

    ; Only nudge when idle 8.3+ minutes but not fully away (2+ hours)
    if (g_idle || A_TimeIdlePhysical <= 500000) {
        expected_x := ""  ; Reset tracking when not in nudge territory
        Return
    }

    CoordMode("Mouse", "Screen")
    MouseGetPos(&cur_x, &cur_y)

    ; If mouse moved from where we left it, user is active — stop nudging
    if (expected_x != "" && (cur_x != expected_x || cur_y != expected_y)) {
        expected_x := ""
        Return
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

; If you make any edits to this file, do a ctrl-alt-r to reload the script
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

; --- Corp-only hotkeys (disabled on home PC) ---
#HotIf g_corp_mode

; Toggle VPN auto-login on/off
^!v::
{
    global g_autologin
    g_autologin := !g_autologin
    state := g_autologin ? "ON" : "OFF"
    ToolTip("VPN auto-login: " state)
    SetTimer(() => ToolTip(), -1000)
}

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

; This enables "hot zoom" toggle in tmux
; Make sure you're using Myles' tmux.conf to set the tmux leader to ^\ (Ctrl-backslash)
RAlt::
RWin::
{
    Send("^\z")
}

;#HotIf WinActive("ahk_exe WindowsTerminal.exe")
;+MButton::
;{
;    SendInput("{Click,Right}")
;}
;#HotIf

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

; Enables a last-pane w/ zoom-state toggle in tmux
^;::
{
    ;Send("{Blind}{Ctrl up}")
    Send("{Ctrl up}^\;{Ctrl down}")
    ;Send("{Blind}{Ctrl down}")
}

;; failed attempt to prevent double-paste
;~^v::
;{
;    if (A_PriorHotkey = "~^v" and A_TimeSincePriorHotkey < 400)
;    {
;        ;MsgBox("xxx")
;        ; Too much time between presses, so this isn't a double-press.
;        ;KeyWait("v")
;        return
;    }
;    Send("^v")
;    return
;}

#HotIf WinActive("ahk_exe mspaint.exe") or WinActive("ahk_exe etxc.exe") or WinActive("ahk_exe wezterm-gui.exe")
; Make F1 just like LMB
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

