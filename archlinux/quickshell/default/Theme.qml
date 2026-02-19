pragma Singleton
import QtQuick

QtObject {
    // Theme mode: true = dark, false = light
    property bool isDark: true

    // Background colors (transparent)
    readonly property color background: "transparent"

    // How much the hover background should extend left/right beyond the hovered item.
    readonly property int hoverOverlap: 6

    // Text colors
    readonly property color textPrimary: isDark ? "#ffffff" : "#000000"
    readonly property color textSecondary: isDark ? "#ffffff" : "#000000"

    // Text shadow properties for DropShadow
    readonly property color shadowColor: isDark ? '#a6909090' : "transparent"
    readonly property int shadowRadius: isDark ? 6 : 0
    readonly property int shadowVerticalOffset: isDark ? 1 : 0
    readonly property int shadowHorizontalOffset: 1

    // Font settings - SF Pro
    readonly property string fontFamily: "SF Pro Text"
    readonly property int fontSize: 13
    readonly property int iconSize: 16

    // Hover opacity
    readonly property real hoverOpacity: 0.8
    readonly property real activeOpacity: 0.6

    // Animation settings
    readonly property int animationDuration: 90
    readonly property int animationEasing: Easing.OutCubic

    // Workspace window display mode: "classic" | "macos"
    property string workspaceWindowsMode: "macos"

    // Spacing and sizing
    readonly property int itemPadding: 11
    readonly property int itemVerticalPadding: 4
    readonly property int borderRadius: 99

    // Material background effects (from CSS variables)
    readonly property color materialUltraThick: isDark
        ? Qt.rgba(0, 0, 0, 0.5)
        : Qt.rgba(246/255, 246/255, 246/255, 0.84)

    readonly property color materialThick: isDark
        ? Qt.rgba(0, 0, 0, 0.4)
        : Qt.rgba(246/255, 246/255, 246/255, 0.72)

    // Menu colors
    readonly property color menuBackground: isDark
        ? Qt.rgba(0.15, 0.15, 0.15, 0.65)
        : Qt.rgba(0.96, 0.96, 0.96, 0.64)
    readonly property color menuHighlight: "#0088FF"
    readonly property color menuText: isDark ? "#ffffff" : "#4c4c4c"
    readonly property color menuTextDisabled: "#636363"
    readonly property color menuShortcutText: "#636363"
    readonly property color menuSeparator: isDark ? Qt.rgba(1, 1, 1, 0.1) : "#bababa"
    readonly property color menuHeaderText: "#808080"

    // Menu sizing
    readonly property int menuWidth: 250
    readonly property int menuItemHeight: 24
    readonly property int menuBorderRadius: 13
    readonly property int menuItemBorderRadius: 8
}
