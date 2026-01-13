# Contributing to Quickshell Configs

Welcome! This repository contains configuration files for [Quickshell](https://quickshell.org/), a QML-based desktop shell framework. We use it to build bars, panels, and widgets for our Wayland/X11 environment (specifically tailored for Hyprland).

## Getting Started

### Prerequisites

- **Quickshell**: You need Quickshell installed.
- **Hyprland**: This config is designed to integrate with Hyprland workspaces.
- **NixOS**: (Optional) This repo is part of a NixOS dotfiles setup, but the configs can run on any distro with Quickshell.

### Running the Config locally

You don't need to restart your shell to test changes. You can run Quickshell from the terminal:

```bash
# Run the 'default' configuration from this directory
quickshell -c default

# Verbose logging (helpful for debugging)
quickshell -c default -v
```

**Hot Reloading**: Quickshell supports hot-reloading. When you save a `.qml` file, the changes should appear immediately.

## Project Structure

The configuration follows standard Quickshell layout:

- **`default/`**: The main configuration directory.
  - **`shell.qml`**: Entry point. Sets up the PanelWindow.
  - **`Theme.qml`**: Singleton for app-wide colors and constants.
  - **`qmldir`**: Module definition file. **Crucial**: If you add a new `.qml` component, you likely need to register it here!
  - **`Menu*.qml`**: Components for the recursive menu system.

## Development Workflow

1.  **Make changes** in `.qml` files.
2.  **Check the terminal output** where `quickshell` is running.
    -   Look out for `ReferenceError` or "X is not a type".
3.  **Use the Logger**:
    -   We recommend keeping a terminal open with `quickshell log` or running with `-v`.

### Debugging

If things aren't working:
-   **Check `qmldir`**: Did you add your new component to `qmldir`?
-   **Check Property Bindings**: QML is reactive. Ensure your bindings aren't creating loops.
-   **Logs**: `quickshell -vv` gives very verbose debug output.

## Architecture Guidelines

### Component Design
-   **Reusable Components**: Capitalized files (e.g., `IconButton.qml`) are reusable types.
-   **Private Components**: Lowercase files are usually implementations detail or single instances.
-   **Theme**: Use `Theme.qml` for all colors and spacing constants. Do not hardcode hex colors in components.

### Menu System
The specific "default" config features a complex recursive menu system:
-   **`MenuPopup.qml`**: A floating window that handles menu items.
-   **Adaptive Width**: Menus calculate their width based on the widest child. This is handled via `Loader` resizing logic.
-   **Recursive Nesting**: Submenus are loaded via `Loader` pointing recursively to `MenuPopup.qml`.

## Style Guide
-   Use 4 spaces for indentation (or match existing file).
-   Group properties at the top of the object.
-   Use `id` as the first property of an object.
-   Signal handlers (`onClicked:`) go after properties.
