import QtQuick

import "." as Root

Item {
    id: root

    property string glyph: ""
    property color fallbackColor: "white"
    property string fallbackFontFamily: "sans-serif"
    property int pixelSize: 16
    property int fontWeight: Font.Normal
    property bool svgEnabled: Root.Symbols.svgEnabled

    readonly property string _trimmedGlyph: glyph === undefined || glyph === null ? "" : String(glyph)
    readonly property bool _glyphKnown: Root.Symbols.hasGlyphEntry(_trimmedGlyph)
    readonly property string _sfName: svgEnabled ? Root.Symbols.sfNameForGlyph(_trimmedGlyph) : ""
    readonly property string _svgSource: svgEnabled ? Root.Symbols.svgUrlForGlyph(_trimmedGlyph) : ""
    readonly property bool _hasSvgCandidate: svgEnabled && _trimmedGlyph.length > 0 && _sfName.length > 0 && _svgSource.length > 0
    readonly property bool svgReady: _hasSvgCandidate && svgImage.status === Image.Ready

    implicitWidth: svgReady ? pixelSize : fallbackText.implicitWidth
    implicitHeight: svgReady ? pixelSize : fallbackText.implicitHeight

    onSvgEnabledChanged: {
        if (!svgEnabled || _trimmedGlyph.length === 0) {
            return;
        }
        if (_glyphKnown && _sfName.length === 0) {
            Root.Symbols.warnMissingOnce(_trimmedGlyph, "missing mapping");
        }
    }

    onGlyphChanged: {
        if (!svgEnabled || _trimmedGlyph.length === 0) {
            return;
        }
        if (_glyphKnown && _sfName.length === 0) {
            Root.Symbols.warnMissingOnce(_trimmedGlyph, "missing mapping");
        }
    }

    Image {
        id: svgImage
        anchors.fill: parent
        visible: root.svgReady
        source: root._hasSvgCandidate ? root._svgSource : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        antialiasing: true
        cache: true

        onStatusChanged: {
            if (!root._hasSvgCandidate || status !== Image.Error) {
                return;
            }

            Root.Symbols.warnMissingOnce(root._trimmedGlyph, "load failed");
        }
    }

    Text {
        id: fallbackText
        anchors.centerIn: parent
        visible: !root.svgReady
        text: root._trimmedGlyph
        color: root.fallbackColor
        font.family: root.fallbackFontFamily
        font.pixelSize: root.pixelSize
        font.weight: root.fontWeight
        renderType: Text.NativeRendering
    }
}
