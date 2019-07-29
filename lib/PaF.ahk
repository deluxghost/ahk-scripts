#Include %A_ScriptDir%\lib\Gdip.ahk

; Explorer
#If WinActive("ahk_class CabinetWClass") or WinActive("ahk_class ExploreWClass")
    ~^v::
    save_hWnd := WinExist("A")
    ControlGetFocus, save_focus, ahk_id %save_hWnd%
    if save_focus not in Edit1,Edit2,DirectUIHWND1
        for window in ComObjCreate("Shell.Application").Windows {
            if window.HWND == save_hWnd {
                PasteClipboard(window.Document.Folder.Self.Path)
            }
        }
    return
#If
; Desktop
#If WinActive("ahk_class WorkerW")
    ~^v::
    save_hWnd := WinExist("A")
    ControlGetFocus, save_focus, ahk_id %save_hWnd%
    if save_focus not in Edit1,Edit2,DirectUIHWND1
        PasteClipboard(A_Desktop)
    return
#If

; Invoke Paste-as-File in directory
PasteClipboard(path)
{
    ; Invalid path
    if !InStr(FileExist(path), "D")
        return
    ; Append trailling backslash
    path := RegExReplace(path, "([^\\])$", "$1\")
    if DllCall("IsClipboardFormatAvailable", "Uint",1) or DllCall("IsClipboardFormatAvailable", "Uint",13) {
        ; Text
        paste_type := _("paf.type.text")
    } else if DllCall("IsClipboardFormatAvailable", "Uint",2) {
        ; Image
        paste_type := _("paf.type.image")
    } else {
        return
    }

    pToken := Gdip_Startup()
    ; Clip object
    clip := (paste_type == _("paf.type.text") ? clipboard : Gdip_CreateBitmapFromClipboard())

    default_name := ""
    Loop {
        InputBox, filename, % _("paf.paste.title", paste_type), % _("paf.enter.filename"),, 360, 135,,,,, % default_name
        ; User cancelled
        if ErrorLevel
            break
        ; Filename validation
        filename := Trim(filename, OmitChars := " `t")
        if !IsFileName(filename) {
            MsgBox, 0x10, % _("paf.invalid.name"), % _("paf.invalid.name.msg")
            default_name := filename
            ; Retry
            continue
        }
        ; Set extension name automatically
        if !InStr(filename, ".")
            filename := filename . (paste_type == _("paf.type.text") ? ".txt" : ".png")
        if (paste_type == _("paf.type.image")) {
            SplitPath, filename,,, extname
            if extname not in BMP,DIB,RLE,JPG,JPEG,JPE,JFIF,GIF,TIF,TIFF,PNG
                filename := filename . ".png"
        }
        fullname := path . filename
        default_name := filename

        if FileExist(fullname) and !(InStr(FileExist(fullname), "R") or InStr(FileExist(fullname), "D")) {
            ; File exists, prompt replace
            MsgBox, 0x134, % _("paf.file.exists"), % _("paf.file.exists.msg1", filename)
            IfMsgBox, No
                continue
        } else if FileExist(fullname) {
            ; File exists, prompt rename
            MsgBox, 0x30, % _("paf.file.exists"), % _("paf.file.exists.msg2", filename)
            continue
        }
        PasteToFile(clip, fullname, paste_type)
        break
    }
    Gdip_Shutdown(pToken)
}

; Save bitmap data as file
SaveImage(pBitmap, filename)
{
    Gdip_SaveBitmapToFile(pBitmap, filename, Quality:=100)
    Gdip_DisposeImage(pBitmap)
}

; Paste content as a file
PasteToFile(content, path, filetype)
{
    try {
        if (filetype == _("paf.type.text")) {
            if FileExist(path)
                FileDelete, %path%
            FileAppend, %content%, %path%
        } else if (filetype == _("paf.type.image")) {
            SaveImage(content, path)
        }
    } catch {
        MsgBox, 0x10, % _("paf.paste.failed"), % _("paf.paste.failed.msg")
    }
}

; Validate filename is valid
IsFileName(filename)
{
    filename := Trim(filename, OmitChars := " `t")
    if !filename
        return false
    if filename in CON,PRN,AUX,NUL,COM1,COM2,COM3,COM4,COM5,COM6,COM7,COM8,COM9,LPT1,LPT2,LPT3,LPT4,LPT5,LPT6,LPT7,LPT8,LPT9
        return false
    if filename contains <,>,:,`",/,\,|,?,*
        return false
    return true
}