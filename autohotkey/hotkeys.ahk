#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode("Slow")
InstallMouseHook()
InstallKeybdHook()

; Set global variables
g_uid := EnvGet("CORP_UID")
if (g_uid = "")
    MsgBox "CORP_UID environment variable is not set."
g_password := EnvGet("CORP_PASSWORD")
if (g_password = "")
    MsgBox "CORP_PASSWORD environment variable is not set."
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
    check_idle()
    mouse_nudge()
    log_into_cadence_vpn()
}

log_into_cadence_vpn()
{
    global g_idle, g_autologin

    ; Skip if user is idle (away from desk) or auto-login is toggled off (Ctrl+Alt+V)
    if (g_idle || !g_autologin) {
        Return
    }

    ; Cooldown: act at most once every 15 seconds to prevent frenzy-looping when
    ; Cisco's window gets stuck in a bad state.
    static last_action_ms := 0
    if (A_TickCount - last_action_ms < 15000) {
        Return
    }

    ; Wrap everything in try-catch so an unexpected error doesn't cause cascading
    ; timer firings. SetTitleMatchMode is always restored to 2 on any exit path.
    try {

    ; SetTitleMatchMode controls how WinExist() matches window titles:
    ;   1 = title must START WITH the given string
    ;   2 = title must CONTAIN the given string (default)
    ;   3 = title must EXACTLY EQUAL the given string
    ; We switch modes per-check and always restore to 2 before returning.
    ; Use Window Spy (right-click AHK tray icon) to find exact window titles.

    ; --- Case 1: Error/alert dialog ---
    ; Cisco pops a bare "Cisco Secure Client" dialog (exact title) for errors/alerts.
    ; ControlGetHwnd("OK") throws if no OK button is present, which avoids false-matching
    ; other Cisco windows with the same title. ControlClick matches by button text.
    ; WinActivate() with no args activates the window matched by the last WinExist().
    SetTitleMatchMode(3)
    if (WinExist("Cisco Secure Client")) {
        try {
            ControlGetHwnd("OK", "Cisco Secure Client")
            WinActivate()
            ControlClick("OK")
            last_action_ms := A_TickCount
            SetTitleMatchMode(2)
            Return
        } catch {
        }
    }

    ; --- Case 2: Password prompt ---
    ; When VPN session expires, Cisco shows a login window whose title starts with
    ; "Cisco Secure Client | " (note the pipe and trailing space — use Window Spy
    ; to confirm the exact title on your system).
    ; Edit2 is the second text input field (Password); Edit1 would be Username.
    ; Use Window Spy > Control List to verify the control name if this breaks.
    ; {BS 15} clears any stale password text before typing the new one.
    SetTitleMatchMode(1)
    if (WinExist("Cisco Secure Client | ")) {
        WinActivate()
        ControlClick("Edit1")       ; Focus the Username field
        Sleep(500)
        Send("{BS 15}")             ; Clear up to 15 chars of existing text
        SendText(g_uid)
        Sleep(500)
        ControlClick("Edit2")       ; Focus the Password field
        Send("{BS 15}")             ; Clear up to 15 chars of existing text
        SendText(g_password)
        Send("{Enter}")
        last_action_ms := A_TickCount
        SetTitleMatchMode(2)
        Return
    }

    ; --- Case 3: Main VPN window visible but not yet showing login prompt ---
    ; Cisco sometimes flashes the main window briefly before the login prompt appears.
    ; This is the debounce: wait 1 second and re-check. If the login prompt (Case 2)
    ; still hasn't appeared, click Connect to trigger it. If Connect isn't found
    ; (ControlGetHwnd throws), the window is in an unknown state — close it and let
    ; the next loop iteration start fresh.
    ; All of this complexity exists because Cisco's GUI is unpredictable about which
    ; window appears and when.
    SetTitleMatchMode(3)
    if (WinExist("Cisco Secure Client")) {
        Sleep(1000)                 ; Wait for UI to settle
        SetTitleMatchMode(1)
        if (! WinExist("Cisco Secure Client | ")) {
            ; Login prompt still hasn't appeared — try clicking Connect
            SetTitleMatchMode(3)
            if (WinExist("Cisco Secure Client")) {
                WinActivate("Cisco Secure Client")
                try {
                    ControlGetHwnd("Connect")   ; Throws if Connect button doesn't exist
                    ControlClick("Connect")
                } catch {
                    try {
                        WinClose()              ; Unknown state — close and retry next loop
                    } catch {
                    }
                }
                last_action_ms := A_TickCount
                SetTitleMatchMode(2)
                Return
            }
        }
        SetTitleMatchMode(2)
    }

    ; --- Case 4: "Secure gateway terminated" dialog ---
    ; Shown when the VPN server drops the connection (e.g. after 15-hour timeout).
    ; Dismiss the OK dialog; the next loop iteration will trigger a reconnect.
    SetTitleMatchMode(3)
    if (WinExist("The secure gateway has terminated the VPN connection")) {
        WinActivate()
        ControlClick("OK")
        last_action_ms := A_TickCount
        SetTitleMatchMode(2)
        Return
    }

    ; No relevant Cisco window found — nothing to do this iteration.
    SetTitleMatchMode(2)

    } catch as e {
        SetTitleMatchMode(2)        ; Always restore title match mode on error
        last_action_ms := A_TickCount  ; Apply cooldown so errors don't cascade
    }
}

; Disable auto-locking by wiggling mouse
mouse_nudge()
{
    static mouse_delta_x := 5
    ; Greater than 8.3 minutes and less than 2 hours
    if (! g_idle && A_TimeIdlePhysical > 500000)
    {
        ;MsgBox(A_TimeIdlePhysical)
        ; Ensure absolute screen coordinates
        CoordMode("Mouse", "Screen")
        MouseGetPos(&cur_x, &cur_y)
        MouseMove(cur_x + mouse_delta_x, cur_y, 10)
        mouse_delta_x *= -1
    }
}

; ^ = Ctrl
; + = Shift
; ! = Alt

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

