# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Repository

This is a quickshell configuration managed within a NixOS dotfiles repository. Quickshell is a QML-based framework for building desktop shell components (bars, panels, widgets, overlays) for Wayland/X11 environments.

## Configuration Structure

The configuration follows quickshell's standard layout:
- **Config location**: `~/.config/quickshell` (symlinked from this repo via NixOS home-manager)
- **Entry point**: `default/shell.qml` - The main configuration file that quickshell loads
- **Config naming**: The `default` subdirectory name represents the config name

Each named subdirectory containing a `shell.qml` file is recognized as a separate configuration.

## Running and Testing

**Launch quickshell:**
```bash
quickshell                      # Auto-discovers configs in XDG paths
quickshell -c default           # Run specific named config
quickshell -p /path/to/config   # Run from custom path
quickshell -d                   # Daemonize (detach from terminal)
quickshell -n                   # No duplicate - exit if already running
```

**Live reloading**: Quickshell automatically reloads when you save QML files. Keep it running during development.

**NixOS integration**: This config is symlinked via home-manager at `archlinux/home.nix:43`. Changes to files here immediately affect the running quickshell session due to the symlink.

## Testing and Debugging

**CRITICAL: Always check logs after making changes!**

After editing any QML files, immediately run:
```bash
quickshell log
```

This shows real-time logs and will catch:
- Syntax errors in QML
- Missing type declarations
- Runtime errors
- Property binding issues

**Useful debugging options:**
```bash
quickshell -v                   # Verbose (INFO level logs)
quickshell -vv                  # Very verbose (DEBUG level logs)
quickshell --log-times          # Add timestamps to logs
quickshell --debug 9000         # Open port 9000 for QML debugger
quickshell list                 # List all running quickshell instances
quickshell kill                 # Kill quickshell instances
```

**Common errors and solutions:**
- `"X is not a type"` → Add the component to `qmldir` file
- `ReferenceError` → Check property/object names and bindings
- Config not loading → Verify `shell.qml` exists in config directory
- Hot reload not working → Check file permissions and symlink integrity

## QML Development in Quickshell

**Core concepts:**
- **Declarative syntax**: QML combines object hierarchies with JavaScript logic
- **Reactive bindings**: Property changes automatically propagate through the component tree
- **Window types**:
  - `PanelWindow` for bars/widgets with anchor positioning (`anchors.top`, `anchors.left`, etc.)
  - `FloatingWindow` for standard desktop windows

**File naming conventions:**
- Uppercase-starting files (`Bar.qml`, `Clock.qml`) become reusable component types
- Lowercase files are typically entry points or utilities
- `pragma Singleton` creates app-wide shared objects
- **IMPORTANT**: If a `qmldir` file exists in the directory, ALL custom components must be declared in it:
  ```qml
  singleton Theme 1.0 Theme.qml
  WorkspaceWindows 1.0 WorkspaceWindows.qml
  IconButton 1.0 IconButton.qml
  ```

**Component patterns:**
- Use `Variants` type with `Quickshell.screens` to create monitor-aware components that spawn/destroy with display changes
- Avoid root imports (`import "root:/path"`) - they break LSP and singletons
- Import Quickshell modules: `import Quickshell`, `import QtQuick`

**Built-in integrations available:**
- Process execution: `Process`, `StdioCollector`
- System: `SystemClock` (preferred over shell `date` commands)
- Desktop environment: Hyprland, i3, Wayland protocols
- Services: PipeWire, Notifications, DBus, SystemTray, UPower, Bluetooth

## Architecture Notes

The current configuration is minimal (basic PanelWindow with top/left/right anchoring). When expanding:
- Multi-monitor setups benefit from reactive `Quickshell.screens` bindings
- Complex bars should be split into separate component files
- Shared state (like system data) belongs in singleton modules

## Menu Framework Patterns

**Core Components:**
- **MenuPopup.qml**: The primary container for menus.
  - Uses `PopupWindow` to float above other windows (solves layout clipping).
  - Supports recursive nesting for submenus.
  - Features `adaptiveWidth` to automatically stretch logic based on content.
- **MenuItem.qml**: Standard item with standardized styling, hover states, and shortcuts.

**Submenu Implementation:**
- Submenus use RECURSIVE loading of `MenuPopup.qml` via a `Loader`.
- **Placement**: Use `placement: "right"` prop to position submenus correctly.
- **Data Model**: Submenus are defined recursively in the `model` array (e.g. `submenu: [...]`).

**Important Note on Sizing:**
- `Loader.width` must be carefully managed to avoid dependency cycles during adaptive sizing. 
- Use `width: Math.max(implicitWidth, parent.width)` in Loaders to allow implicit width propagation.

## Documentation

Official docs: https://quickshell.org/docs/master/guide/introduction/
- Type definitions for all Quickshell modules
- QtQuick type reference
- Example configurations repository
