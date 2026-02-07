# Windows Audio Profiles

A PowerShell utility for quickly toggling between audio devices (speakers and microphones) on Windows systems. This tool provides a convenient system tray icon for fast audio device switching.

## Features

- Toggle between different speaker devices
- Toggle between different microphone devices
- System tray integration for quick access
- Runs hidden in the background
- Lightweight and fast

## Requirements

- Windows operating system
- PowerShell 5.1 or later
- Administrative privileges may be required for first-time execution policy changes

## Installation

1. Download or clone this repository
2. Place the `toggleAudio.ps1` script in your desired location (e.g., `C:\Users\user\Desktop\toggleAudio.ps1`)

## Usage

### Running the Script

To run the audio toggle utility with a hidden window:

```powershell
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\user\Desktop\toggleAudio.ps1"
```

### Command Parameters Explained

- `-WindowStyle Hidden`: Runs PowerShell without showing the console window
- `-ExecutionPolicy Bypass`: Allows the script to run without being blocked by PowerShell's execution policy
- `-File`: Specifies the path to the PowerShell script

### Creating a Shortcut (Optional)

For easier access, you can create a desktop shortcut:

1. Right-click on your desktop and select `New > Shortcut`
2. Enter the following as the target:
   ```
   powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Users\user\Desktop\toggleAudio.ps1"
   ```
3. Name the shortcut (e.g., "Toggle Audio")
4. Click Finish

### Using the Tray Icon

Once the script is running:

1. Look for the application icon in your system tray (notification area)
2. Click on the tray icon to toggle between audio devices
3. The script runs in a loop, continuously monitoring for clicks

## Troubleshooting

### Script Won't Run

If you encounter issues running the script:

1. **Execution Policy Error**: Run PowerShell as Administrator and execute:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Path Issues**: Make sure the path to `toggleAudio.ps1` is correct and uses the full absolute path

3. **Missing Dependencies**: Ensure your Windows system has PowerShell 5.1 or later installed

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Pablo Echavarria

## Acknowledgments

- Thanks to the PowerShell community for audio device management techniques
- Built for Windows power users who frequently switch audio devices
