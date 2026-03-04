# Optional SF Symbols SVG Override

This folder is for user-provided SF Symbols SVG exports.

## Naming

- File name format: `<sf-symbol-name>.svg`
- Example: `switch.2.svg`

## Enabling

1. Export your SVGs to this folder.
2. Normalize CoreSVG colors for Qt compatibility:
   - `./assets/svg/normalize-coresvg.sh`
3. Set `Symbols.svgEnabled` to `true` in `Symbols.qml`.

## Fallback Behavior

- If SVG mode is enabled and an SVG is missing or fails to load, the UI falls back to the existing font glyph.
- Missing mappings/assets are logged once per glyph key.
