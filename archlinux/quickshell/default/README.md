# macOS-Style Top Bar for Quickshell

A recreation of the macOS top bar for Quickshell/Hyprland with workspace-aware window tracking.

## Features

- **Left Section:**
  - Apple logo (using SF Pro icon)
  - Active window names from the current workspace (e.g., "Kitty", "Firefox")

- **Right Section:**
  - Search icon (􀙇)
  - Notifications icon (􀊫)
  - Settings icon (􀉭)
  - User profile icon (􀜊)
  - Live clock display (e.g., "Mon Jun 10  9:41 AM")

- **Styling:**
  - Transparent background
  - SF Pro font with macOS-style icons
  - Dark/Light theme support
  - Hover effects on interactive elements

## Menu System

The configuration features a robust, macOS-like menu system (`Menu.qml`, `MenuPopup.qml`):
- **Recursive Submenus**: Supports infinite nesting of submenus.
- **Adaptive Sizing**: Menus automatically adjust their width to fit the longest content.
- **Auto-Closing**: Clicking an action in a submenu intelligently closes the entire menu chain.

## Files

### Core
- `shell.qml` - Main panel window with layout.
- `Theme.qml` - Singleton for theme management (dark/light colors).
- `qmldir` - QML module definition.

### Components
- `WorkspaceWindows.qml` - Displays active windows from current workspace.
- `IconButton.qml` - Reusable icon button component.
- `TimeDisplay.qml` - Live time display with formatting.

### Menu Framework
- `Menu.qml` - Top-level menu logic.
- `MenuPopup.qml` - The floating window container for a menu list.
- `MenuItem.qml` - Individual menu entries (buttons, submenus).
- `MenuHeader.qml` - Section headers within menus.
- `MenuSeparator.qml` - Visual separators.

## Usage

The configuration automatically loads when you start Quickshell:

```bash
quickshell -c default
```

Quickshell will hot-reload changes when you save any `.qml` file.

## Theme Switching

To switch between dark and light themes, edit `Theme.qml` and change the `isDark` property:

```qml
// Dark theme (default)
property bool isDark: true

// Light theme
property bool isDark: false
```

The theme will update instantly thanks to Quickshell's live reloading.

## Customization

### Change Icons

Edit the icon strings in `shell.qml` (right section) or use different SF Pro symbols:
- Search: 􀙇
- Notifications: 􀊫
- Settings: 􀉭
- User: 􀜊

### Modify Colors

Edit `Theme.qml` to customize colors:
```qml
readonly property color textPrimary: isDark ? "#ffffff" : "#000000"
readonly property color textSecondary: isDark ? "#ffffffd9" : "#00000033"
```

### Adjust Spacing

Modify padding and spacing in `Theme.qml`:
```qml
readonly property int itemPadding: 11
readonly property int itemVerticalPadding: 4
```

## Requirements

- Quickshell
- Hyprland (for workspace integration)
- SF Pro font installed on your system

## Notes

- Window names are pulled from Hyprland's active workspace
- Multiple windows of the same application are deduplicated
- The bar adapts to all monitors via `Quickshell.screens`
- Icons use SF Pro font symbols (displayed as Unicode characters)
