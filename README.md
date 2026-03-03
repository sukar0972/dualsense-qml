# DualSense QML Plugin for Noctalia Shell

A Noctalia Shell plugin that displays your PS5 DualSense controller's battery level in the system bar and provides a comprehensive settings panel for modifying controller features using the `dualsensectl` CLI tool.



## Features

- **Battery Monitoring**: Real-time battery level display in the system bar
- **Low Battery Notifications**: Real-time notifications when battery is getting low - works in game.
- **Full Controller Control**: Access all `dualsensectl` features through a clean UI
- **Native Noctalia Styling**: Perfectly matches your Noctalia theme using built-in color system
- **Hot Reload Support**: Edit and test without restarting the shell

## Installation

1. **Prerequisites**:
   ```bash
   # Install dualsensectl (Arch Linux example)
   sudo pacman -S dualsensectl
   
   # Or from AUR/other distros
   yay -S dualsensectl
   ```

2. **Plugin Installation**:
   ```bash
   # Clone or copy the plugin to your Noctalia plugins directory
   mkdir -p ~/.config/noctalia/plugins/dualsense-qml
   cp -r dualsense-qml/* ~/.config/noctalia/plugins/dualsense-qml/
   ```

3. **Enable the Plugin**:
   - Press `Super + ,` to open Noctalia Settings
   - Go to **Plugins** tab
   - Find **DualSense Controller** and click **Enable**
   - The battery widget will appear in your bar

## Usage

### Bar Widget
- **Click** the DualSense battery icon to open the settings panel
- Battery level updates automatically every 60 seconds

### Settings Panel Features

**Device Info**
- Current battery percentage and firmware version
- **Power Off** button for quick controller shutdown

**Audio Controls**
- Speaker volume slider
- Microphone volume slider
- Microphone mute toggle

**Lighting**
- Lightbar on/off toggle
- RGB color picker for lightbar
- Player LED selector (0-7)

**Trigger Haptics**
- Left/Right trigger mode selectors:
  - `Off` - Disable haptics
  - `Feedback` - Resistance feedback
  - `Weapon` - Gun trigger emulation
  - `Bow` - Bow string emulation

## Troubleshooting

**"No DualSense detected"**
```
# Verify dualsensectl works
dualsensectl battery
dualsensectl -l
```

**Plugin not appearing**
- Ensure `~/.config/noctalia/plugins/dualsense-qml/manifest.json` exists
- Check Noctalia Settings → Plugins tab
- Restart shell or use hot reload

**Permissions issues**
```
# Ensure user has access to controller
ls -l /dev/input/event*
sudo usermod -a -G input $USER
```

## Supported dualsensectl Commands

| Category | Commands |
|----------|----------|
| **Info** | `battery`, `info` |
| **Power** | `power-off` |
| **Audio** | `volume`, `microphone-volume`, `microphone` |
| **Lighting** | `lightbar`, `player-leds` |
| **Triggers** | `trigger left/right [mode]` |

## License

MIT License - see `LICENSE` file for details.

## Credits

Built using:
- [Noctalia Shell](https://noctalia.dev)
- [dualsensectl](https://github.com/nowrep/dualsensectl)
- [Quickshell](https://quickshell.outfoxxed.me)

***

**Connect your DualSense → See battery → Customize haptics → Play!** 
