pragma ComponentBehavior: Bound

import QtQuick

import ".." as Root

Item {
    id: root

    readonly property string privacyKind: Root.PrivacyIndicatorService.activePrimaryKind
    readonly property string privacyGlyph: privacyKind === "systemAudio" ? "􁅀" : (privacyKind === "mic" ? "􀊱" : (privacyKind === "camera" ? "􀌟" : (privacyKind === "location" ? Root.Theme.privacyIndicatorArrowGlyph : "")))
    readonly property color privacyColor: privacyKind === "systemAudio" ? Root.Theme.privacySystemAudioIndicator : (privacyKind === "mic" ? Root.Theme.privacyMicrophoneIndicator : (privacyKind === "camera" ? Root.Theme.privacyCameraIndicator : (privacyKind === "location" ? Root.Theme.privacyLocationIndicator : "transparent")))

    visible: privacyKind !== "none"
    height: parent.height
    width: visible ? Root.Theme.privacyStatusCapsuleWidth : 0

    Rectangle {
        anchors.centerIn: parent
        width: Root.Theme.privacyStatusCapsuleWidth
        height: Root.Theme.privacyStatusCapsuleHeight
        radius: Math.round(height / 2)
        color: root.privacyColor

        Root.SymbolIcon {
            anchors.centerIn: parent
            width: Root.Theme.privacyStatusCapsuleIconSize
            height: Root.Theme.privacyStatusCapsuleIconSize
            svgScale: 1.5
            glyph: root.privacyGlyph
            fallbackColor: "#ffffff"
            fallbackFontFamily: Root.Theme.fontFamilySymbol
            pixelSize: Root.Theme.privacyStatusCapsuleIconSize
            fontWeight: Font.Medium
        }
    }
}
