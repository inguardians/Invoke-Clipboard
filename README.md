# Invoke-Clipboard

Invoke-Cliboard is a powershell tool for aquiring clipboard data on Windows machines as well as creation of command and control through the clipboard. Invoke-Clipboard is written in PowerShell to use the user32.dll data link library (DLL) in order to import the appropriate clipboard functions using C#.  

Invoke-Clipboard has two methods of being called; one for clipboard logging/harvesting (Invoke-ClipboardLogger) and the other for establishing a Command and Control (C2C) channel over the clipboard (Invoke-ClipboardC2C and Invoke-ClipboardC2V).

## Functions

### Main Functions

```powershell
Invoke-ClipboardLogger - monitors the Clipboard
Invoke-ClipboardC2C	-	command and control over Clipboard (client)
Invoke-ClipboardC2V	-	command and control over Clipboard (victim)
```

### Misc Functions

```powershell
push_cb - pushes to the Clipboard
get_cb - gets whats in the Clipboard
```

## Usage

```powershell
Invoke-ClipboardLogger - Invoke-ClipboardLogger
Invoke-ClipboardC2C	-	Invoke-ClipboardC2C -message "gwmi -class Win32_Process"
Invoke-ClipboardC2V	-	Invoke-ClipboardC2V
```

## References

- StringToHGlobalUni - <https://msdn.microsoft.com/en-us/library/system.runtime.interopservices.marshal.stringtohglobaluni(v=vs.110).aspx>
- GetClipboardData - <https://msdn.microsoft.com/en-us/library/windows/desktop/ms649039(v=vs.85).aspx>
- ClipboardFormats - <https://msdn.microsoft.com/en-us/library/windows/desktop/ms649013(v=vs.85).aspx#_win32_Standard_Clipboard_Formats>

## Blog

- https://www.inguardians.com/2019/02/06/all-your-copy-paste-are-belong-to-us/

