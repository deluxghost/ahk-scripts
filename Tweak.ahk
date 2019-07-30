#Persistent
#InstallKeybdHook
#SingleInstance force
SetWorkingDir %A_ScriptDir%

_locale_ := "zh_CN"
#Include %A_ScriptDir%\lib\i18n.ahk
#Include %A_ScriptDir%\lib\Uri.ahk

CoordMode, Mouse, Screen
SetTitleMatchMode, 3
DetectHiddenWindows, On

SetTimer, NoExtWarning, 50
return

#Include %A_ScriptDir%\lib\PaF.ahk


MouseIsOver(WinTitle) {
    MouseGetPos,,, Win
    return WinExist(WinTitle . " ahk_id " . Win)
}

; Gets a localized string from a resource file
TranslateMUI(resDll, resID) {
    VarSetCapacity(buf, 256)
    hDll := DllCall("LoadLibrary", "str",resDll, "Ptr")
    Result := DllCall("LoadString", "Ptr",hDll, "Uint",resID, "str",buf, "int",128)
    return buf
}

; Skip "change a filename extension" dialog
NoExtWarning:
if WinExist(TranslateMUI("shell32.dll", 4148) . " ahk_class #32770") {
    SetControlDelay -1
    ControlClick, Button1, % TranslateMUI("shell32.dll", 4148) . " ahk_class #32770",,,, NA
}
return

; Capslock key change IME mode, long press to caps lock
Capslock::
if GetKeyState("CapsLock", "T") == 1 {
    SetCapsLockState, Off
    return
}
KeyWait, Capslock, T0.25
if ErrorLevel {
    SetCapsLockState, On
    KeyWait, Capslock
} else {
    ; Ctrl-Shift-Home (my IME hotkey)
    Send, ^!{Home}
}
return

; Disable Numlock key
~NumLock::
SetNumlockState, On
return

; Disable Insert key
Insert::
return

; Win-m to move window (not compatible with some windows)
#m::
; Alt-Space
Send, !{Space}
Sleep, 5
Send, m
Sleep, 5
Send, {Left}{Right}
return

; Win-z to minimize window
#If not WinActive("ahk_class WorkerW")
    #z::
    WinGet, active_id, ID, A
    WinMinimize, ahk_id %active_id%
    return
#If

; Win-s to Always-on-Top
#If not WinActive("ahk_class WorkerW") and not WinActive("ahk_class Shell_TrayWnd")
    #s::
    Winset, Alwaysontop,, A
    return
#If

; Win-f to google text
#f::
clip_bak := ClipBoardAll
ClipBoard := ""
Send, ^c
ClipWait, .5
if not ErrorLevel and ClipBoard != "" {
    query := UriEncode(Trim(ClipBoard))
    Run, https://www.google.com/search?q=%query%
}
ClipBoard := clip_bak
return

; Scroll mouse wheel on taskbar to change system volume
#If MouseIsOver("ahk_class Shell_TrayWnd")
    WheelUp::
    Send, {Volume_Up}
    Sleep, 100
    return
    WheelDown::
    Send, {Volume_Down}
    Sleep, 100
    return
#If

; Quick reddit link with "r//"
:*:r//::
Send, https://reddit.com/r//
Send, {Left}
return
