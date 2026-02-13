Add-Type -AssemblyName System.Drawing

$csharpCode = @"
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;
using System.Text;


namespace CoreAudioApi {
    public enum ERole {
        eConsole = 0,
        eMultimedia = 1,
        eCommunications = 2,
        ERole_enum_count = 3
    }


    public enum EDataFlow {
        eRender,
        eCapture,
        eAll,
        EDataFlow_enum_count
    }


    [Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDeviceEnumerator {
        int EnumAudioEndpoints(EDataFlow dataFlow, int stateMask, out IMMDeviceCollection devices);
        int GetDefaultAudioEndpoint(EDataFlow dataFlow, ERole role, out IMMDevice device);
        int GetDevice(string deviceId, out IMMDevice device);
        int RegisterEndpointNotificationCallback(IntPtr client);
        int UnregisterEndpointNotificationCallback(IntPtr client);
    }


    [Guid("0BD7A1BE-7A1A-44DB-8397-CC5392387B5E"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDeviceCollection {
        int GetCount(out int count);
        int Item(int index, out IMMDevice device);
    }


    [Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IMMDevice {
        int Activate(ref Guid iid, int clsCtx, IntPtr activationParams, [MarshalAs(UnmanagedType.IUnknown)] out object interfacePointer);
        int OpenPropertyStore(int stgmAccess, out IPropertyStore properties);
        int GetId([MarshalAs(UnmanagedType.LPWStr)] out string deviceId);
        int GetState(out int state);
    }


    [Guid("886d8eeb-8cf2-4446-8d02-cdba1dbdcf99"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    internal interface IPropertyStore {
        int GetCount(out int count);
        int GetAt(int i, out PROPERTYKEY pkey);
        int GetValue(ref PROPERTYKEY key, out PROPVARIANT pv);
        int SetValue(ref PROPERTYKEY key, ref PROPVARIANT propvar);
        int Commit();
    }


    [Guid("F8679F50-850A-41CF-9C72-430F290290C8"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IPolicyConfig {
        int GetMixFormat(string pszDeviceName, out IntPtr ppFormat);
        int GetDeviceFormat(string pszDeviceName, bool bDefault, out IntPtr ppFormat);
        int ResetDeviceFormat(string pszDeviceName);
        int SetDeviceFormat(string pszDeviceName, IntPtr pEndpointFormat, IntPtr MixFormat);
        int GetProcessingPeriod(string pszDeviceName, bool bDefault, out long pmftDefaultPeriod, out long pmftMinimumPeriod);
        int SetProcessingPeriod(string pszDeviceName, ref long pmftPeriod);
        int GetShareMode(string pszDeviceName, out IntPtr pMode);
        int SetShareMode(string pszDeviceName, IntPtr mode);
        int GetPropertyValue(string pszDeviceName, ref PROPERTYKEY pkey, out PROPVARIANT pv);
        int SetPropertyValue(string pszDeviceName, ref PROPERTYKEY pkey, ref PROPVARIANT pv);
        int SetDefaultEndpoint(string pszDeviceName, ERole role);
        int SetEndpointVisibility(string pszDeviceName, bool bVisible);
    }
    
    [Guid("CA286FC3-91FD-42C3-8E9B-CAAFA66242E3"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IPolicyConfigVista {
        int GetMixFormat(string pszDeviceName, out IntPtr ppFormat);
        int GetDeviceFormat(string pszDeviceName, bool bDefault, out IntPtr ppFormat);
        int SetDeviceFormat(string pszDeviceName, IntPtr pEndpointFormat, IntPtr MixFormat);
        int GetProcessingPeriod(string pszDeviceName, bool bDefault, out long pmftDefaultPeriod, out long pmftMinimumPeriod);
        int SetProcessingPeriod(string pszDeviceName, ref long pmftPeriod);
        int GetShareMode(string pszDeviceName, out IntPtr pMode);
        int SetShareMode(string pszDeviceName, IntPtr mode);
        int GetPropertyValue(string pszDeviceName, ref PROPERTYKEY pkey, out PROPVARIANT pv);
        int SetPropertyValue(string pszDeviceName, ref PROPERTYKEY pkey, ref PROPVARIANT pv);
        int SetDefaultEndpoint(string pszDeviceName, ERole role);
        int SetEndpointVisibility(string pszDeviceName, bool bVisible);
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct PROPERTYKEY {
        public Guid fmtid;
        public int pid;
    }


    [StructLayout(LayoutKind.Explicit)]
    public struct PROPVARIANT {
        [FieldOffset(0)] public short vt;
        [FieldOffset(8)] public IntPtr pwszVal;
    }

    public class CoreAudioController {
        private static IMMDeviceEnumerator deviceEnumerator;


        static CoreAudioController() {
            deviceEnumerator = (IMMDeviceEnumerator)new MMDeviceEnumerator();
        }


        public static string GetDefaultAudioEndpoint(EDataFlow dataFlow, ERole role) {
            IMMDevice device;
            deviceEnumerator.GetDefaultAudioEndpoint(dataFlow, role, out device);
            IPropertyStore propertyStore;
            device.OpenPropertyStore(0, out propertyStore);
            PROPERTYKEY propertyKey = new PROPERTYKEY { fmtid = new Guid("a45c254e-df1c-4efd-8020-67d146a850e0"), pid = 14 }; // PKEY_Device_FriendlyName
            PROPVARIANT propertyValue;
            propertyStore.GetValue(ref propertyKey, out propertyValue);
            return Marshal.PtrToStringUni(propertyValue.pwszVal);
        }


        public static List<string> GetAudioDevices(EDataFlow dataFlow) {
            var devices = new List<string>();
            IMMDeviceCollection deviceCollection;
            deviceEnumerator.EnumAudioEndpoints(dataFlow, 1, out deviceCollection);
            int count;
            deviceCollection.GetCount(out count);
            for (int i = 0; i < count; i++) {
                IMMDevice device;
                deviceCollection.Item(i, out device);
                IPropertyStore propertyStore;
                device.OpenPropertyStore(0, out propertyStore);
                PROPERTYKEY propertyKey = new PROPERTYKEY { fmtid = new Guid("a45c254e-df1c-4efd-8020-67d146a850e0"), pid = 14 }; // PKEY_Device_FriendlyName
                PROPVARIANT propertyValue;
                propertyStore.GetValue(ref propertyKey, out propertyValue);
                devices.Add(Marshal.PtrToStringUni(propertyValue.pwszVal));
            }
            return devices;
        }


        public static void SetDefaultDevice(string deviceName, ERole role) {
            string deviceId = GetDeviceId(deviceName);
            if (string.IsNullOrEmpty(deviceId)) {
                throw new Exception("Device not found: " + deviceName);
            }
            
            // Try different PolicyConfig implementations
            Exception lastException = null;
            
            // Try PolicyConfigClient with IPolicyConfig interface
            try {
                var policyConfig = (IPolicyConfig)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("870AF99C-171D-4F9E-AF0D-E63DF40C2BC9")));
                policyConfig.SetDefaultEndpoint(deviceId, role);
                return;
            } catch (Exception ex) { lastException = ex; }
            
            // Try older CLSID
            try {
                var policyConfig = (IPolicyConfig)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("F8679F50-850A-41CF-9C72-430F290290C8")));
                policyConfig.SetDefaultEndpoint(deviceId, role);
                return;
            } catch (Exception ex) { lastException = ex; }
            
            // Try Vista interface with same CLSIDs
            try {
                var policyConfig = (IPolicyConfigVista)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("870AF99C-171D-4F9E-AF0D-E63DF40C2BC9")));
                policyConfig.SetDefaultEndpoint(deviceId, role);
                return;
            } catch (Exception ex) { lastException = ex; }
            
            try {
                var policyConfig = (IPolicyConfigVista)Activator.CreateInstance(Type.GetTypeFromCLSID(new Guid("F8679F50-850A-41CF-9C72-430F290290C8")));
                policyConfig.SetDefaultEndpoint(deviceId, role);
                return;
            } catch (Exception ex) { lastException = ex; }
            
            throw new Exception("Could not set default device. No compatible COM class found. Last error: " + (lastException != null ? lastException.Message : "Unknown"));
        }


        private static string NormalizeDeviceName(string name) {
            if (string.IsNullOrEmpty(name)) return string.Empty;
            string cleaned = name
                .Replace("Ãƒâ€šÃ‚Â®", "®")
                .Replace("Ã‚Â®", "®")
                .Replace("Â®", "®")
                .Replace("Ã‚Â", "")
                .Replace("Â", "")
                .Normalize(NormalizationForm.FormKC);

            var sb = new StringBuilder(cleaned.Length);
            bool lastWasSpace = false;
            foreach (char c in cleaned) {
                if (char.IsWhiteSpace(c)) {
                    if (!lastWasSpace) {
                        sb.Append(' ');
                        lastWasSpace = true;
                    }
                } else {
                    sb.Append(c);
                    lastWasSpace = false;
                }
            }
            return sb.ToString().Trim();
        }

        private static bool IsSelectionToken(string token) {
            if (string.IsNullOrEmpty(token)) return false;
            bool allDigits = true;
            for (int i = 0; i < token.Length; i++) {
                if (!char.IsDigit(token[i])) {
                    allDigits = false;
                    break;
                }
            }
            if (allDigits) return true;
            return token.Length == 1 && char.IsLetter(token[0]);
        }

        private static string StripSelectionPrefix(string normalizedName) {
            if (string.IsNullOrEmpty(normalizedName)) return string.Empty;

            // Leading token forms: "4- Name", "A: Name"
            int i = 0;
            while (i < normalizedName.Length && char.IsWhiteSpace(normalizedName[i])) i++;
            int j = i;
            while (j < normalizedName.Length && char.IsLetterOrDigit(normalizedName[j])) j++;
            if (j > i) {
                string token = normalizedName.Substring(i, j - i);
                if (IsSelectionToken(token)) {
                    int k = j;
                    while (k < normalizedName.Length && char.IsWhiteSpace(normalizedName[k])) k++;
                    if (k < normalizedName.Length && (normalizedName[k] == '-' || normalizedName[k] == ':')) {
                        k++;
                        while (k < normalizedName.Length && char.IsWhiteSpace(normalizedName[k])) k++;
                        if (k < normalizedName.Length) normalizedName = normalizedName.Substring(k);
                    }
                }
            }

            // Parenthesized or inline token forms: "(4- ...)" or "Desktop Microphone 4- ..."
            var sb = new StringBuilder(normalizedName.Length);
            int p = 0;
            while (p < normalizedName.Length) {
                bool boundary = p == 0 || char.IsWhiteSpace(normalizedName[p - 1]) || normalizedName[p - 1] == '(' || normalizedName[p - 1] == '[' || normalizedName[p - 1] == '{';
                if (boundary && char.IsLetterOrDigit(normalizedName[p])) {
                    int q = p;
                    while (q < normalizedName.Length && char.IsLetterOrDigit(normalizedName[q])) q++;
                    string token = normalizedName.Substring(p, q - p);
                    int r = q;
                    while (r < normalizedName.Length && char.IsWhiteSpace(normalizedName[r])) r++;
                    if (IsSelectionToken(token) && r < normalizedName.Length && normalizedName[r] == '-') {
                        r++;
                        while (r < normalizedName.Length && char.IsWhiteSpace(normalizedName[r])) r++;
                        if (r < normalizedName.Length) {
                            p = r;
                            continue;
                        }
                    }
                }
                sb.Append(normalizedName[p]);
                p++;
            }

            return sb.ToString().Trim();
        }

        private static string CanonicalizeForMatch(string name) {
            string normalized = StripSelectionPrefix(NormalizeDeviceName(name));
            var sb = new StringBuilder(normalized.Length);
            foreach (char c in normalized) {
                if (char.IsLetterOrDigit(c)) sb.Append(char.ToLowerInvariant(c));
            }
            return sb.ToString();
        }

        private static string GetDeviceId(string deviceName) {
            string normalizedTarget = NormalizeDeviceName(deviceName);
            string canonicalTarget = CanonicalizeForMatch(deviceName);
            IMMDeviceCollection deviceCollection;
            deviceEnumerator.EnumAudioEndpoints(EDataFlow.eAll, 1, out deviceCollection);
            int count;
            deviceCollection.GetCount(out count);
            for (int i = 0; i < count; i++) {
                IMMDevice device;
                deviceCollection.Item(i, out device);
                IPropertyStore propertyStore;
                device.OpenPropertyStore(0, out propertyStore);
                PROPERTYKEY propertyKey = new PROPERTYKEY { fmtid = new Guid("a45c254e-df1c-4efd-8020-67d146a850e0"), pid = 14 }; // PKEY_Device_FriendlyName
                PROPVARIANT propertyValue;
                propertyStore.GetValue(ref propertyKey, out propertyValue);
                string friendlyName = Marshal.PtrToStringUni(propertyValue.pwszVal);
                string normalizedFriendly = NormalizeDeviceName(friendlyName);
                string canonicalFriendly = CanonicalizeForMatch(friendlyName);
                if (
                    friendlyName == deviceName ||
                    normalizedFriendly.Equals(normalizedTarget, StringComparison.OrdinalIgnoreCase) ||
                    (canonicalTarget.Length > 0 && canonicalFriendly.Equals(canonicalTarget, StringComparison.OrdinalIgnoreCase))
                ) {
                    string deviceId;
                    device.GetId(out deviceId);
                    return deviceId;
                }
            }
            return null;
        }


        [ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
        private class MMDeviceEnumerator { }
    }
}
"@

# Only compile C# code if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'CoreAudioApi.CoreAudioController').Type) {
    try {
        Add-Type -TypeDefinition $csharpCode -ErrorAction Stop
    } catch {
        Write-Error "Failed to compile audio API code: $($_.Exception.Message)"
        Write-Host "`nIf you see compilation errors, please ensure you're running PowerShell 5.1 or later." -ForegroundColor Yellow
        Write-Host "Check your PowerShell version with: `$PSVersionTable.PSVersion" -ForegroundColor Gray
        exit 1
    }
}
Add-Type -AssemblyName System.Windows.Forms

# === AUDIO TOGGLE INSTANCE MARKER ===
# Unique identifier to distinguish this script from others
$Global:AUDIO_TOGGLE_INSTANCE_ID = "AudioToggle-pechavarriaa-CrossPlatformAudioToggle-v1.0"
$Global:AUDIO_TOGGLE_INSTALL_PATH = $PSScriptRoot

# === SINGLE INSTANCE CHECK ===
# Ensure only one instance of Audio Toggle is running
# Use installation path in mutex name to allow different installations to run simultaneously
$installPathHash = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([System.Text.Encoding]::UTF8.GetBytes($PSScriptRoot))).Replace("-","").Substring(0,16)
$mutexName = "Global\AudioToggle_$installPathHash"
$mutex = New-Object System.Threading.Mutex($false, $mutexName)

try {
    # Try to acquire the mutex (wait 0 seconds = immediate check)
    if (-not $mutex.WaitOne(0, $false)) {
        # Another instance is already running - exit silently
        Write-Host "Audio Toggle is already running." -ForegroundColor Yellow
        exit 0
    }
} catch {
    # If mutex creation fails, continue anyway (better to run than fail)
    Write-Warning "Could not create single-instance mutex: $($_.Exception.Message)"
}

# Register cleanup to release mutex when script exits
$null = Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    if ($mutex) {
        $mutex.ReleaseMutex()
        $mutex.Dispose()
    }
}

# === LOAD CONFIGURATION FROM FILE ===
$configPath = Join-Path $env:LOCALAPPDATA "AudioToggle\config.json"

if (Test-Path $configPath) {
    try {
        $configJson = [System.IO.File]::ReadAllText($configPath, [System.Text.Encoding]::UTF8)
        $config = $configJson | ConvertFrom-Json
        $speakerDevice = $config.profile1.output
        $secondMicDevice = $config.profile1.input
        $headsetOutput = $config.profile2.output
        $headsetInput = $config.profile2.input
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Failed to load configuration from $configPath`n`nError: $($_.Exception.Message)`n`nPlease run install.ps1 -Reconfigure",
            "Configuration Error",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        exit 1
    }
}
else {
    [System.Windows.Forms.MessageBox]::Show(
        "Configuration file not found: $configPath`n`nPlease run install.ps1 to configure your audio devices.",
        "Configuration Missing",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    exit 1
}

function Get-ShortDeviceName {
    param([string]$DeviceName)
    # Extract brand/model from parentheses, fall back to full name if no parentheses
    if ($DeviceName -match '\(([^)]+)\)') {
        $name = $matches[1]
    } else {
        $name = $DeviceName
    }

    # Remove any remaining parentheses and their content (including partial ones)
    $name = $name -replace '\([^)]*\)', ''  # Remove complete parentheses pairs
    $name = $name -replace '\([^)]*$', ''    # Remove opening paren with no close
    $name = $name -replace '\(', ''          # Remove any remaining opening parens
    $name = $name -replace '\)', ''          # Remove any remaining closing parens
    $name = $name -replace '\s+', ' '        # Clean up multiple spaces
    $name = $name.Trim()

    # Truncate if too long
    if ($name.Length -gt 30) {
        $name = $name.Substring(0, 27) + "..."
    }
    return $name
}

function Toggle-AudioSetup {
    try {
        $currentPlayback = [CoreAudioApi.CoreAudioController]::GetDefaultAudioEndpoint([CoreAudioApi.EDataFlow]::eRender, [CoreAudioApi.ERole]::eConsole)
        $currentMic = [CoreAudioApi.CoreAudioController]::GetDefaultAudioEndpoint([CoreAudioApi.EDataFlow]::eCapture, [CoreAudioApi.ERole]::eCommunications)
    }
    catch {
        return "Error: Could not detect current audio device"
    }


    if ($currentPlayback -eq $headsetOutput) {
        # Switch to Profile 1 (Desktop)
        try {
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($secondMicDevice, [CoreAudioApi.ERole]::eConsole)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($secondMicDevice, [CoreAudioApi.ERole]::eMultimedia)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($secondMicDevice, [CoreAudioApi.ERole]::eCommunications)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($speakerDevice, [CoreAudioApi.ERole]::eConsole)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($speakerDevice, [CoreAudioApi.ERole]::eMultimedia)

            $outShort = Get-ShortDeviceName $speakerDevice
            $inShort = Get-ShortDeviceName $secondMicDevice
            return "Profile 1 (Desktop)`n🔊 $outShort`n🎤 $inShort"
        }
        catch {
            return "Error: $($_.Exception.Message)"
        }
    }
    else {
        # Switch to Profile 2 (Headset)
        try {
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($headsetInput, [CoreAudioApi.ERole]::eConsole)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($headsetInput, [CoreAudioApi.ERole]::eMultimedia)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($headsetInput, [CoreAudioApi.ERole]::eCommunications)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($headsetOutput, [CoreAudioApi.ERole]::eConsole)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($headsetOutput, [CoreAudioApi.ERole]::eMultimedia)

            $outShort = Get-ShortDeviceName $headsetOutput
            $inShort = Get-ShortDeviceName $headsetInput
            return "Profile 2 (Headset)`n🔊 $outShort`n🎤 $inShort"
        }
        catch {
            return "Error: $($_.Exception.Message)"
        }
    }
}

function Get-AudioDevices {
    # Ensure the type is loaded (will reuse if already loaded)
    if (-not ([System.Management.Automation.PSTypeName]'CoreAudioApi.CoreAudioController').Type) {
        Write-Warning "Run Toggle-AudioSetup first to load the audio API, or dot-source this script."
        return
    }
    
    Write-Host "`n=== OUTPUT DEVICES (Speakers/Headphones) ===" -ForegroundColor Cyan
    $outputDevices = [CoreAudioApi.CoreAudioController]::GetAudioDevices([CoreAudioApi.EDataFlow]::eRender)
    foreach ($device in $outputDevices) {
        Write-Host "  $device"
    }
    
    Write-Host "`n=== INPUT DEVICES (Microphones) ===" -ForegroundColor Cyan
    $inputDevices = [CoreAudioApi.CoreAudioController]::GetAudioDevices([CoreAudioApi.EDataFlow]::eCapture)
    foreach ($device in $inputDevices) {
        Write-Host "  $device"
    }
    
    Write-Host "`n=== CURRENT DEFAULTS ===" -ForegroundColor Yellow
    try {
        $currentOutput = [CoreAudioApi.CoreAudioController]::GetDefaultAudioEndpoint([CoreAudioApi.EDataFlow]::eRender, [CoreAudioApi.ERole]::eConsole)
        $currentInput = [CoreAudioApi.CoreAudioController]::GetDefaultAudioEndpoint([CoreAudioApi.EDataFlow]::eCapture, [CoreAudioApi.ERole]::eCommunications)
        Write-Host "  Output: $currentOutput"
        Write-Host "  Input:  $currentInput"
    } catch {
        Write-Warning "Could not get current defaults"
    }
}

# Create the tray icon
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon("C:\Windows\System32\SndVol.exe")
$notifyIcon.Text = "Audio Toggle"
$notifyIcon.Visible = $true

# Create context menu
$contextMenu = New-Object System.Windows.Forms.ContextMenuStrip

$menuToggle = New-Object System.Windows.Forms.ToolStripMenuItem
$menuToggle.Text = "Toggle Audio"
$menuToggle.Add_Click({
    $result = Toggle-AudioSetup
    $notifyIcon.BalloonTipTitle = "Audio Toggle"
    $notifyIcon.BalloonTipText = $result
    $notifyIcon.ShowBalloonTip(2000)
})
$contextMenu.Items.Add($menuToggle)

$menuConfigure = New-Object System.Windows.Forms.ToolStripMenuItem
$menuConfigure.Text = "Configure..."
$menuConfigure.Add_Click({
    $installPath = Join-Path $env:LOCALAPPDATA "AudioToggle\install.ps1"
    if (Test-Path $installPath) {
        Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$installPath`"", "-Reconfigure"
    } else {
        # Download and run if not found locally
        Start-Process powershell -ArgumentList "-NoExit", "-ExecutionPolicy", "Bypass", "-Command", "irm https://raw.githubusercontent.com/pechavarriaa/CrossPlatformAudioToggle/main/install.ps1 | iex; install.ps1 -Reconfigure"
    }
})
$contextMenu.Items.Add($menuConfigure)

$contextMenu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

$menuExit = New-Object System.Windows.Forms.ToolStripMenuItem
$menuExit.Text = "Exit"
$menuExit.Add_Click({
    # Clean up mutex before exiting
    if ($mutex) {
        try {
            $mutex.ReleaseMutex()
            $mutex.Dispose()
        } catch {
            # Ignore errors during cleanup
        }
    }
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})
$contextMenu.Items.Add($menuExit)

$notifyIcon.ContextMenuStrip = $contextMenu

# Left-click to toggle
$notifyIcon.Add_Click({
    if ($_.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        $result = Toggle-AudioSetup
        $notifyIcon.BalloonTipTitle = "Audio Toggle"
        $notifyIcon.BalloonTipText = $result
        $notifyIcon.ShowBalloonTip(2000)
    }
})

# Show initial notification
$notifyIcon.BalloonTipTitle = "Audio Toggle"
$notifyIcon.BalloonTipText = "Click to toggle audio devices"
$notifyIcon.ShowBalloonTip(2000)

# Run the message loop
[System.Windows.Forms.Application]::Run()
