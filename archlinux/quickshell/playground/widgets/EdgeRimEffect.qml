import QtQuick

Item {
    id: root

    property real radius: 22
    property real rimWidthPx: 1.25
    property real glowWidthPx: 6.0
    property real highlightOpacity: 0.12
    property real shadeOpacity: 0.10
    property real cornerBoost: 0.20
    property bool debug: false
    property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1.0

    ShaderEffect {
        id: highlightPass
        anchors.fill: parent
        visible: root.enabled

        property real uRadius: root.radius
        property real uRimWidthPx: root.rimWidthPx
        property real uGlowWidthPx: root.glowWidthPx
        property real uHighlightOpacity: root.highlightOpacity
        property real uShadeOpacity: 0.0
        property real uCornerBoost: root.cornerBoost
        property real uDpr: root.dpr
        property real uMode: 0.0
        property real uDebug: root.debug ? 1.0 : 0.0
        property vector2d uSize: Qt.vector2d(width, height)
        fragmentShader: "shaders/edge_rim.frag.qsb"
    }

    ShaderEffect {
        id: shadePass
        anchors.fill: parent
        visible: root.enabled && !root.debug

        property real uRadius: root.radius
        property real uRimWidthPx: root.rimWidthPx
        property real uGlowWidthPx: root.glowWidthPx
        property real uHighlightOpacity: 0.0
        property real uShadeOpacity: root.shadeOpacity
        property real uCornerBoost: root.cornerBoost
        property real uDpr: root.dpr
        property real uMode: 1.0
        property real uDebug: 0.0
        property vector2d uSize: Qt.vector2d(width, height)
        fragmentShader: "shaders/edge_rim.frag.qsb"
    }
}
