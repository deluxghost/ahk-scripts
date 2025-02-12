﻿#Persistent
#InstallKeybdHook
#SingleInstance force
SetWorkingDir %A_ScriptDir%

_locale_ := "zh_CN"
#Include %A_ScriptDir%\lib\i18n.ahk
#Include %A_ScriptDir%\lib\Uri.ahk
#Include %A_ScriptDir%\lib\VA.ahk

CoordMode, Mouse, Screen
SetTitleMatchMode, 3
DetectHiddenWindows, On

IniRead, SyncDevicesConf, % A_ScriptDir . "\tweak.ini", Tweak, SyncDevices
SyncDevicesList := StrSplit(SyncDevicesConf, ";")

SetTimer, NoExtWarning, 50
SetTimer, SyncVolume, 50
return

RemoveToolTip:
SetTimer, RemoveToolTip, Off
ToolTip
return

MsgToolTip(msg, timeout:=1000)
{
    ToolTip, % msg
    SetTimer, RemoveToolTip, % timeout
}

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
    ; Win-Space
    Send, #{Space}
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
#If !WinActive("ahk_class WorkerW")
    #z::
    WinGet, active_id, ID, A
    WinMinimize, ahk_id %active_id%
    return
#If

; Win-s to Always-on-Top
#If !WinActive("ahk_class WorkerW") and not WinActive("ahk_class Shell_TrayWnd")
    #s::
    Winset, Alwaysontop,, A
    return
#If

; Win-f to google text
#f::
clip_bak := ClipboardAll
Clipboard := ""
Send, ^c
ClipWait, .5
if !ErrorLevel and Clipboard != "" {
    query := UriEncode(Trim(Clipboard))
    Run, https://www.google.com/search?q=%query%
}
Clipboard := clip_bak
clip_bak := ""
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

; Quick source engine launch options with "res//"
; e.g. -windowed -noborder -w 1920 -h 1080
#If WinActive("ahk_class vguiPopupWindow")
:*:res//::
Send, -windowed -noborder -w %A_ScreenWidth% -h %A_ScreenHeight%
return
#If

; Quick "map workshop/" command with "ws//"
#If WinActive("ahk_exe hl2.exe")
:*:ws//::
Send, map workshop/
return
#If

; Before pasting Steam protocal URL to develop console in source engine games, convert it to "connect" command
; e.g. "steam://connect/[ip]:[port]" => "connect [ip]:[port]"
; e.g. "steam://connect/[ip]:[port]/[password]" => "connect [ip]:[port]; password [password]"
#If WinActive("ahk_exe hl2.exe")
    ~^v::
    if (!DllCall("IsClipboardFormatAvailable", "Uint",1) and !DllCall("IsClipboardFormatAvailable", "Uint",13)) {
        return
    }
    if (Clipboard == "") {
        return
    }
    m := RegExMatch(Clipboard, "O)^steam://connect/([^/]+)(?:/(.*))?$", mat)
    if (m <= 0) {
        return
    }
    global tfclipsave := Clipboard
    Clipboard := "connect " . mat.Value(1)
    if (mat.Value(2) != "") {
        Clipboard := Clipboard . "; password "  . mat.Value(2)
    }
    SetTimer, TFReCopy, -50
    return
#If

TFReCopy:
Clipboard := tfclipsave
return

; Sync master volume of default device with specific devices
SyncVolume:
volume := VA_GetMasterVolume()
if (volume != "") {
    for index, device in SyncDevicesList {
        if (device == "") {
            continue
        }
        dev_volume := VA_GetMasterVolume("", device)
        if (dev_volume == volume) {
            continue
        }
        VA_SetMasterVolume(volume, "", device)
    }
}
return