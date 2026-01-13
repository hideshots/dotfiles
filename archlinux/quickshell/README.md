# Quickshell Configurations

This repository contains configuration files for [Quickshell](https://quickshell.org/), a flexible QML-based desktop shell for Wayland and X11.

## Configurations

-   **[default](./default)**: A macOS-style top bar configuration featuring:
    -   Global menu bar
    -   System status indicators
    -   Workspace-aware window titles
    -   Dark/Light theme toggle

## Getting Started

To run the default configuration:

```bash
quickshell -c default
```

For more details on development and contributing, please see [CONTRIBUTING.md](./CONTRIBUTING.md).

## Requirements

-   Quickshell
-   NixOS (optional, used for deployment in this dotfiles repo)
-   Hyprland (recommended for full feature support)
