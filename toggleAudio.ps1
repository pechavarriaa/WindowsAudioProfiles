Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$csharpCode = @"
using System;
using System.Runtime.InteropServices;
using System.Collections.Generic;


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


        private static string GetDeviceId(string deviceName) {
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
                if (Marshal.PtrToStringUni(propertyValue.pwszVal) == deviceName) {
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

Add-Type -TypeDefinition $csharpCode

# === CONFIGURE YOUR DEVICES HERE ===
# Run Get-AudioDevices to see available device names
$speakerDevice = "Speakers (Lenovo USB Audio)"
$secondMicDevice = "Microphone (Anker PowerConf C200)"
$headsetOutput = "Headset Earphone (HyperX Virtual Surround Sound)"
$headsetInput = "Headset Microphone (HyperX Virtual Surround Sound)"

function Toggle-AudioSetup {
    try {
        $currentPlayback = [CoreAudioApi.CoreAudioController]::GetDefaultAudioEndpoint([CoreAudioApi.EDataFlow]::eRender, [CoreAudioApi.ERole]::eConsole)
        $currentMic = [CoreAudioApi.CoreAudioController]::GetDefaultAudioEndpoint([CoreAudioApi.EDataFlow]::eCapture, [CoreAudioApi.ERole]::eCommunications)
    }
    catch {
        return "Error: Could not detect current audio device"
    }


    if ($currentPlayback -eq $headsetOutput) {
        # Switch to Profile 1
        try {
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($secondMicDevice, [CoreAudioApi.ERole]::eConsole)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($secondMicDevice, [CoreAudioApi.ERole]::eMultimedia)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($secondMicDevice, [CoreAudioApi.ERole]::eCommunications)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($speakerDevice, [CoreAudioApi.ERole]::eConsole)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($speakerDevice, [CoreAudioApi.ERole]::eMultimedia)
            return "Switched to Profile 1"
        }
        catch {
            return "Error: $($_.Exception.Message)"
        }
    }
    else {
        # Switch to Profile 2
        try {
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($headsetInput, [CoreAudioApi.ERole]::eConsole)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($headsetInput, [CoreAudioApi.ERole]::eMultimedia)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($headsetInput, [CoreAudioApi.ERole]::eCommunications)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($headsetOutput, [CoreAudioApi.ERole]::eConsole)
            [CoreAudioApi.CoreAudioController]::SetDefaultDevice($headsetOutput, [CoreAudioApi.ERole]::eMultimedia)
            return "Switched to Profile 2"
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