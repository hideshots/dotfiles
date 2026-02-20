# Small Weather Widget (Quickshell)

This config provides a standalone 158x158 weather widget for Quickshell.

## Run

From this directory:

```bash
quickshell -p .
```

Or with an absolute path:

```bash
quickshell -p /home/drama/dotfiles/archlinux/quickshell/playground
```

## Configure location and units

Edit `shell.qml`:

- `weatherLocation`: empty string (`""`) uses IP-based location from wttr.in.
- `weatherUnits`: `"m"` for metric or `"u"` for US units.

## Update interval

- Refreshes on startup.
- Refreshes every 10 minutes.
- Click the widget to force an immediate refresh.

## Dependencies

- `curl` must be installed and available in `PATH`.

## Hyprland Blur Rules (Liquid Glass v1)

The widget sets the layer-surface namespace to `quickshell:weather`.
Use this in your Hyprland config to enable backdrop blur for this layer:

```ini
# ~/.config/hypr/hyprland.conf
layerrule = blur on, match:namespace quickshell:weather
layerrule = ignore_alpha 0.2, match:namespace quickshell:weather
layerrule = xray 0, match:namespace quickshell:weather
```

Then reload Hyprland config and verify the namespace is visible:

```bash
hyprctl layers
```

If blur looks too weak or too strong, tune `ignorealpha` and your global `decoration:blur` settings.
