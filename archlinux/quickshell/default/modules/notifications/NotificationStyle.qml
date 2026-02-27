pragma Singleton

import QtQuick

import "../.." as Root

QtObject {
    readonly property real edgeLightAngleDeg: 330
    readonly property real edgeLightStrength: 2
    readonly property real edgeLightWidthPx: 4.0
    readonly property real edgeLightSharpness: 0.1
    readonly property real edgeLightOpacity: 1.0
    readonly property color edgeLightTint: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.92)

    readonly property real buttonTintOpacity: Root.Theme.isDark ? 0.24 : 0.30
    readonly property color buttonTintColor: Root.Theme.isDark ? Qt.rgba(1, 1, 1, buttonTintOpacity) : Qt.rgba(0.98, 0.99, 1.0, buttonTintOpacity)
    readonly property color buttonHoverTintColor: Root.Theme.isDark ? Qt.rgba(1, 1, 1, buttonTintOpacity + 0.06) : Qt.rgba(1, 1, 1, buttonTintOpacity + 0.14)
    readonly property color buttonHairlineColor: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.58)
    readonly property real buttonEdgeLightStrength: Math.max(0.2, edgeLightStrength * 0.55)
    readonly property real buttonEdgeLightWidthPx: Math.max(2.0, edgeLightWidthPx * 0.85)
    readonly property real buttonEdgeLightSharpness: Math.min(1.0, edgeLightSharpness + 0.18)
    readonly property real buttonEdgeLightOpacity: Math.min(1.0, edgeLightOpacity * 0.72)
}
