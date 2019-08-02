#Include %A_ScriptDir%\lib\i18n.ahk
#Include %A_ScriptDir%\lib\Gdip.ahk

GetTypedI18n(prefix, typ) {
    return _("paf." . prefix . "." . typ)
}

; Paste clipboard content to specific path
PasteAsFileInPath(path) {
    type_text := "text"
    type_image := "image"
    ; Invalid path
    if (!InStr(FileExist(path), "D"))
        return
    ; Append trailling backslash to path
    path := RegExReplace(path, "([^\\])$", "$1\")
    ; Check clipboard content type
    if (DllCall("IsClipboardFormatAvailable", "Uint",1) or DllCall("IsClipboardFormatAvailable", "Uint",13)) {
        paste_type := type_text
    } else if (DllCall("IsClipboardFormatAvailable", "Uint",2)) {
        paste_type := type_image
    } else {
        return
    }

    pToken := Gdip_Startup()
    ; Init clip object
    if (paste_type == type_text) {
        clip := Clipboard
    } else if (paste_type == type_image) {
        clip := Gdip_CreateBitmapFromClipboard()
    }

    paste_title := _("paf.paste.title", GetTypedI18n("type", paste_type))
    filetype_str := GetTypedI18n("filetype", paste_type)
    Loop {
        FileSelectFile, filepath, S18, % path, % paste_title, % filetype_str
        ; User cancelled
        if (filepath == "")
            break
        ; Validate extension name
        SplitPath, filepath,,, extname
        if (paste_type == type_image) {
            if extname not in BMP,JPG,JPEG,GIF,PNG
                continue
        }
        try {
            if (paste_type == type_text) {
                if (FileExist(filepath))
                    FileDelete, %filepath%
                FileAppend, %clip%, %filepath%
            } else if (paste_type == type_image) {
                WriteImage(clip, filepath)
            }
        } catch {
            MsgBox, 0x10, % _("paf.paste.failed"), % _("paf.paste.failed.msg")
        }
        break
    }
    clip := ""
    Gdip_Shutdown(pToken)
}

; Write bitmap data to file
WriteImage(pBitmap, path)
{
    Gdip_SaveBitmapToFile(pBitmap, path, Quality:=100)
    Gdip_DisposeImage(pBitmap)
}
