pragma ComponentBehavior: Bound

import QtQuick

import ".." as Root

Item {
    id: root

    readonly property var privacyState: Root.PrivacyIndicatorService.state
    readonly property string privacyKind: privacyState.systemAudioRecordingActive || privacyState.screenShareActive ? "systemAudio" : (privacyState.cameraActive ? "camera" : (privacyState.locationActive ? "location" : "none"))
    readonly property string privacyGlyph: privacyKind === "systemAudio" ? "􁅀" : (privacyKind === "camera" ? "􀌟" : (privacyKind === "location" ? Root.Theme.privacyIndicatorArrowGlyph : ""))
    readonly property color privacyColor: privacyKind === "systemAudio" ? Root.Theme.privacySystemAudioIndicator : (privacyKind === "camera" ? Root.Theme.privacyCameraIndicator : (privacyKind === "location" ? Root.Theme.privacyLocationIndicator : "transparent"))
    readonly property real privacySvgScale: privacyKind === "systemAudio" ? Root.Theme.privacyStatusCapsuleSystemAudioSvgScale : (privacyKind === "camera" ? Root.Theme.privacyStatusCapsuleCameraSvgScale : 1.0)
    property int leadingPadding: Root.Theme.rightWidgetPadding
    property int trailingPadding: Root.Theme.rightWidgetPadding

    visible: privacyKind !== "none"
    height: parent.height
    width: visible ? privacyCapsule.width + leadingPadding + trailingPadding : 0

    Rectangle {
        id: privacyCapsule
        anchors.centerIn: parent
        width: Root.Theme.privacyStatusCapsuleWidth
        height: Root.Theme.privacyStatusCapsuleHeight
        radius: Math.round(height / 2)
        color: root.privacyColor

        Root.SymbolIcon {
            anchors.centerIn: parent
            width: Root.Theme.privacyStatusCapsuleIconSize
            height: Root.Theme.privacyStatusCapsuleIconSize
            svgScale: root.privacySvgScale
            glyph: root.privacyGlyph
            fallbackColor: "#ffffff"
            fallbackFontFamily: Root.Theme.fontFamilySymbol
            pixelSize: Root.Theme.privacyStatusCapsuleIconSize
            fontWeight: Font.Medium
        }
    }
}
