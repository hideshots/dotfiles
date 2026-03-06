import QtQuick
import Qt5Compat.GraphicalEffects

import "." as Root

Item {
    id: root

    property string glyph: ""
    property color fallbackColor: "white"
    property string fallbackFontFamily: "sans-serif"
    property int pixelSize: 16
    property int fontWeight: Font.Normal
    property bool svgEnabled: Root.Symbols.svgEnabled
    property string svgNameOverride: ""
    property bool svgTintEnabled: true
    property color svgTintColor: fallbackColor
    property real svgScale: 1.0
    property bool fallbackWhileSvgLoading: true

    readonly property string _trimmedGlyph: glyph === undefined || glyph === null ? "" : String(glyph)
    readonly property string _trimmedSvgOverride: svgNameOverride === undefined || svgNameOverride === null ? "" : String(svgNameOverride).trim()
    readonly property bool _glyphKnown: Root.Symbols.hasGlyphEntry(_trimmedGlyph)
    readonly property string _sfName: svgEnabled ? Root.Symbols.sfNameForGlyph(_trimmedGlyph) : ""
    readonly property string _svgSource: {
        if (!svgEnabled) {
            return "";
        }

        if (_trimmedSvgOverride.length > 0) {
            return Qt.resolvedUrl(Root.Symbols.svgDir + "/" + _trimmedSvgOverride + ".svg");
        }

        return Root.Symbols.svgUrlForGlyph(_trimmedGlyph);
    }
    readonly property real _glyphSvgScale: svgEnabled ? Root.Symbols.scaleForGlyph(_trimmedGlyph) : 1.0
    readonly property real _effectiveSvgScale: Math.max(0.1, root.svgScale) * Math.max(0.1, _glyphSvgScale)
    readonly property bool _hasSvgCandidate: {
        if (!svgEnabled || _svgSource.length === 0) {
            return false;
        }

        if (_trimmedSvgOverride.length > 0) {
            return true;
        }

        return _trimmedGlyph.length > 0 && _sfName.length > 0;
    }
    readonly property bool svgReady: _hasSvgCandidate && svgImage.status === Image.Ready
    readonly property bool _showSvg: svgReady || (_hasSvgCandidate && !fallbackWhileSvgLoading && svgImage.status !== Image.Error)
    readonly property bool _showFallbackText: !svgReady && (!_hasSvgCandidate || fallbackWhileSvgLoading || svgImage.status === Image.Error)
    readonly property bool svgTintActive: _showSvg && svgTintEnabled
    readonly property real _layoutWidth: root.width > 0 ? root.width : root.implicitWidth
    readonly property real _layoutHeight: root.height > 0 ? root.height : root.implicitHeight
    readonly property real _svgRenderSize: Math.max(1, Math.min(_layoutWidth, _layoutHeight))

    implicitWidth: _showSvg ? pixelSize : fallbackText.implicitWidth
    implicitHeight: _showSvg ? pixelSize : fallbackText.implicitHeight

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
        anchors.centerIn: parent
        width: root._svgRenderSize * root._effectiveSvgScale
        height: root._svgRenderSize * root._effectiveSvgScale
        visible: root._showSvg
        opacity: root.svgTintActive ? 0 : 1
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

    ColorOverlay {
        anchors.fill: svgImage
        visible: root.svgTintActive
        source: svgImage
        color: root.svgTintColor
        cached: true
    }

    Text {
        id: fallbackText
        anchors.centerIn: parent
        visible: root._showFallbackText
        text: root._trimmedGlyph
        color: root.fallbackColor
        font.family: root.fallbackFontFamily
        font.pixelSize: root.pixelSize
        font.weight: root.fontWeight
        renderType: Text.NativeRendering
    }
}
