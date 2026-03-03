import QtQuick

import "../.." as Root

Item {
    id: root

    property real radius: 24
    property color tintColor: Root.Theme.isDark ? Qt.rgba(0.09, 0.10, 0.12, 0.50) : Qt.rgba(0.96, 0.97, 0.99, 0.58)
    property color contrastColor: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.030) : Qt.rgba(1, 1, 1, 0.15)
    property color borderColor: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.52)
    property real borderWidth: 1

    property bool edgeLightEnabled: true
    property real edgeOpacity: 0.70
    property color edgeTint: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.90)
    property real lightAngleDeg: 330
    property real lightStrength: 5.0
    property real lightWidthPx: 4.0
    property real lightSharpness: 0.28
    property real cornerBoost: 0.45

    property bool hovered: false
    property bool pressed: false

    readonly property real interactionOpacity: pressed ? 0.60 : (hovered ? 0.95 : 1.0)

    default property alias contentData: contentItem.data

    Rectangle {
        id: tintLayer
        anchors.fill: parent
        radius: root.radius
        color: root.tintColor
        opacity: root.interactionOpacity
        antialiasing: true
    }

    Rectangle {
        id: contrastLayer
        anchors.fill: parent
        radius: root.radius
        color: root.contrastColor
        opacity: root.interactionOpacity
        antialiasing: true
    }

    Rectangle {
        id: contentClip
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        clip: true
        antialiasing: true

        Item {
            id: contentItem
            anchors.fill: parent
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: root.borderWidth
        border.color: root.borderColor
        antialiasing: true
    }

    ShaderEffect {
        anchors.fill: parent
        visible: root.edgeLightEnabled
        property vector2d uSize: Qt.vector2d(width, height)
        property real uRadius: root.radius
        property real uLightAngleDeg: root.lightAngleDeg
        property real uLightStrength: root.lightStrength
        property real uLightWidthPx: root.lightWidthPx
        property real uLightSharpness: root.lightSharpness
        property real uCornerBoost: root.cornerBoost
        property real uEdgeOpacity: root.edgeOpacity
        property color uEdgeTint: root.edgeTint
        fragmentShader: "../../shaders/notification_edge_light.frag.qsb"
    }
}
