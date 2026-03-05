; Map Right Alt to Ctrl+\ then z
RAlt::
{
    Send "^\z"
}
; Map Right Win to Ctrl+\ then z
; My Yunzii B87 keyboard has a RWin key beside the spacebar
RWin::
{
    Send "^\z"
}
; Send password from environment variable with Ctrl+Alt+K
; Set the env var: setx AHK_PASSWORD "your_password"
^!k::
{
    password := EnvGet("KEPLER_PW")
    if (password = "") {
        MsgBox "KEPLER_PW environment variable is not set."
        return
    }
    SendText password
}
; Reload this script with Ctrl+Alt+R
^!r::
{
    MsgBox("Reloading AHK",,"OK T1")
    Reload
}
