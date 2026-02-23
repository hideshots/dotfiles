pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

Rectangle {
    id: root

    implicitWidth: isMedium ? 344 : 164
    implicitHeight: isMedium ? 164 : 164
    radius: 22
    clip: true

    property string location: ""
    property string displayLocation: ""
    property string units: "m"
    property string variant: "small"
    signal requestContextMenu(real x, real y)
    signal variantSelected(string value)
    property alias service: weatherService
    readonly property bool isMedium: variant === "medium"

    property real materialOpacity: 1.0
    property var screen: null
    property string wallpaperSource: ""
    readonly property bool useWallpaperSource: root.wallpaperSource.length > 0

    // Shared liquid-glass controls.
    property real refraction: 0.0
    property real depth: 0.0
    property real dispersion: 0.0
    property real frost: 0.0
    property real splay: 0.0
    property real lightAngleDeg: 345
    property real lightStrength: 0.85
    property real lightWidthPx: 14.0
    property real lightSharpness: 0.45
    property real bodyRefractionWidthPx: 28.0
    property real cornerBoost: 0.55
    property real dispersionLimit: 0.35
    property real dispersionWidthPx: 10.0
    property real dispersionCurve: 0.7
    property real glassOpacity: 1.0
    property color glassTint: Qt.rgba(0.92, 0.97, 1.0, 0.0)
    property color widgetBackground: Qt.rgba(20 / 255, 20 / 255, 20 / 255, 0.0)
    property bool liveCapture: false
    property bool autoRecapture: false
    property real blurSize: 0.0
    property real blurPasses: 2
    property bool glassDebug: false

    property real _shaderTime: 0.0
    property bool _capturedOnce: false
    property bool _captureRequested: false

    readonly property var _window: QsWindow.window
    readonly property var _effectiveScreen: root.screen ? root.screen : (root._window ? root._window.screen : null)
    readonly property real _screenX: root._effectiveScreen ? root._effectiveScreen.x : 0.0
    readonly property real _screenY: root._effectiveScreen ? root._effectiveScreen.y : 0.0
    readonly property real _screenLogicalWidth: root._effectiveScreen && root._effectiveScreen.width > 0 ? root._effectiveScreen.width : Math.max(1.0, root.width)
    readonly property real _screenLogicalHeight: root._effectiveScreen && root._effectiveScreen.height > 0 ? root._effectiveScreen.height : Math.max(1.0, root.height)

    readonly property real _captureWidth: root.useWallpaperSource ? root._screenLogicalWidth : (captureView.sourceSize.width > 0 ? captureView.sourceSize.width : root._screenLogicalWidth)
    readonly property real _captureHeight: root.useWallpaperSource ? root._screenLogicalHeight : (captureView.sourceSize.height > 0 ? captureView.sourceSize.height : root._screenLogicalHeight)
    readonly property bool _hasBackgroundTexture: root.useWallpaperSource ? (wallpaperImage.status === Image.Ready) : captureView.hasContent

    readonly property real _logicalToCaptureX: root._captureWidth / Math.max(1.0, root._screenLogicalWidth)
    readonly property real _logicalToCaptureY: root._captureHeight / Math.max(1.0, root._screenLogicalHeight)

    readonly property real _windowWidth: root._window && root._window.width > 0 ? root._window.width : root.width
    readonly property real _windowHeight: root._window && root._window.height > 0 ? root._window.height : root.height
    readonly property real _marginLeft: root._window && root._window.margins ? root._window.margins.left : 0.0
    readonly property real _marginRight: root._window && root._window.margins ? root._window.margins.right : 0.0
    readonly property real _marginTop: root._window && root._window.margins ? root._window.margins.top : 0.0
    readonly property real _marginBottom: root._window && root._window.margins ? root._window.margins.bottom : 0.0
    readonly property bool _anchorLeft: root._window && root._window.anchors ? root._window.anchors.left : true
    readonly property bool _anchorRight: root._window && root._window.anchors ? root._window.anchors.right : false
    readonly property bool _anchorTop: root._window && root._window.anchors ? root._window.anchors.top : true
    readonly property bool _anchorBottom: root._window && root._window.anchors ? root._window.anchors.bottom : false

    readonly property real _windowXOnOutputLogical: root._anchorLeft ? root._marginLeft : (root._anchorRight ? Math.max(0.0, root._screenLogicalWidth - root._windowWidth - root._marginRight) : 0.0)
    readonly property real _windowYOnOutputLogical: root._anchorTop ? root._marginTop : (root._anchorBottom ? Math.max(0.0, root._screenLogicalHeight - root._windowHeight - root._marginBottom) : 0.0)
    readonly property real _itemXOnOutputLogical: root._windowXOnOutputLogical + root.x
    readonly property real _itemYOnOutputLogical: root._windowYOnOutputLogical + root.y

    readonly property real _itemXOnCapture: _clamp(root._itemXOnOutputLogical * root._logicalToCaptureX, 0.0, Math.max(0.0, root._captureWidth - 1.0))
    readonly property real _itemYOnCapture: _clamp(root._itemYOnOutputLogical * root._logicalToCaptureY, 0.0, Math.max(0.0, root._captureHeight - 1.0))
    readonly property real _itemWOnCapture: _clamp(root.width * root._logicalToCaptureX, 1.0, root._captureWidth)
    readonly property real _itemHOnCapture: _clamp(root.height * root._logicalToCaptureY, 1.0, root._captureHeight)

    readonly property int _regionTexWidth: Math.max(1, Math.round(root._itemWOnCapture))
    readonly property int _regionTexHeight: Math.max(1, Math.round(root._itemHOnCapture))
    readonly property vector2d _blurTexel: Qt.vector2d(1.0 / root._regionTexWidth, 1.0 / root._regionTexHeight)

    color: Qt.rgba(20 / 255, 20 / 255, 20 / 255, 0)

    function _clamp(v, minValue, maxValue) {
        return Math.max(minValue, Math.min(maxValue, v));
    }

    function requestCaptureFrame(force) {
        if (root.useWallpaperSource || root.liveCapture || !root.visible || !captureView.captureSource) {
            return;
        }

        if (!root.autoRecapture && root._captureRequested) {
            return;
        }

        if (!force && root._capturedOnce && !root.autoRecapture) {
            return;
        }

        root._captureRequested = true;
        captureView.captureFrame();
    }

    onLiveCaptureChanged: {
        if (root.useWallpaperSource) {
            return;
        }
        root._capturedOnce = false;
        root._captureRequested = false;
    }
    onVisibleChanged: {
        if (root.visible && !root.useWallpaperSource && !root.liveCapture && !root.autoRecapture && !root._captureRequested && !initialCaptureTimer.running) {
            initialCaptureTimer.restart();
        }
        if (root.autoRecapture) {
            requestCaptureFrame(false);
        }
    }
    onWidthChanged: {
        if (root.autoRecapture) {
            requestCaptureFrame(false);
        }
    }
    onHeightChanged: {
        if (root.autoRecapture) {
            requestCaptureFrame(false);
        }
    }

    Timer {
        id: initialCaptureTimer
        interval: 450
        repeat: false
        running: !root.useWallpaperSource
        onTriggered: root.requestCaptureFrame(false)
    }

    NumberAnimation on _shaderTime {
        from: 0.0
        to: 10000.0
        duration: 10000000
        loops: Animation.Infinite
        running: root.visible && root.glassDebug
    }

    Connections {
        target: root._window
        ignoreUnknownSignals: true
        function onMarginsChanged() {
            if (root.autoRecapture)
                root.requestCaptureFrame(false);
        }
        function onAnchorsChanged() {
            if (root.autoRecapture)
                root.requestCaptureFrame(false);
        }
        function onWidthChanged() {
            if (root.autoRecapture)
                root.requestCaptureFrame(false);
        }
        function onHeightChanged() {
            if (root.autoRecapture)
                root.requestCaptureFrame(false);
        }
        function onScreenChanged() {
            if (root.autoRecapture)
                root.requestCaptureFrame(false);
        }
    }

    Connections {
        target: root._effectiveScreen
        ignoreUnknownSignals: true
        function onGeometryChanged() {
            if (root.autoRecapture)
                root.requestCaptureFrame(false);
        }
    }

    WttrService {
        id: weatherService
        location: root.location
        units: root.units
    }

    Item {
        id: glassLayer
        anchors.fill: parent
        z: 0
        readonly property int effectiveBlurPasses: Math.max(1, Math.min(3, Math.round(root.blurPasses)))
        readonly property real blurBase: Math.max(0.001, root.blurSize) * (1.0 + root.frost * 0.8)

        ScreencopyView {
            id: captureView
            visible: !root.useWallpaperSource
            width: Math.max(1, Math.round(root._captureWidth))
            height: Math.max(1, Math.round(root._captureHeight))
            live: root.liveCapture
            paintCursor: false
            captureSource: root.useWallpaperSource ? null : root._effectiveScreen
        }

        Item {
            id: wallpaperSourceItem
            visible: false
            width: Math.max(1, Math.round(root._captureWidth))
            height: Math.max(1, Math.round(root._captureHeight))

            Image {
                id: wallpaperImage
                anchors.fill: parent
                source: root.wallpaperSource
                fillMode: Image.PreserveAspectCrop
                smooth: true
                asynchronous: true
                cache: true
            }
        }

        ShaderEffectSource {
            id: sampledBackground
            sourceItem: root.useWallpaperSource ? wallpaperSourceItem : captureView
            hideSource: true
            live: true
            smooth: true
            mipmap: false
            sourceRect: Qt.rect(root._itemXOnCapture, root._itemYOnCapture, root._itemWOnCapture, root._itemHOnCapture)
            textureSize: Qt.size(root._regionTexWidth, root._regionTexHeight)
        }

        ShaderEffect {
            id: blurPassH
            width: root._regionTexWidth
            height: root._regionTexHeight

            property variant source: sampledBackground
            property vector2d texelSize: root._blurTexel
            property real blurStrength: glassLayer.blurBase * 1.0

            fragmentShader: "../../shaders/blur_h.frag.qsb"
        }

        ShaderEffectSource {
            id: blurPassHSource
            sourceItem: blurPassH
            hideSource: true
            live: true
            smooth: true
            mipmap: false
            textureSize: Qt.size(root._regionTexWidth, root._regionTexHeight)
        }

        ShaderEffect {
            id: blurPassV
            width: root._regionTexWidth
            height: root._regionTexHeight

            property variant source: blurPassHSource
            property vector2d texelSize: root._blurTexel
            property real blurStrength: glassLayer.blurBase * 1.0

            fragmentShader: "../../shaders/blur_v.frag.qsb"
        }

        ShaderEffectSource {
            id: blurPassVSource
            sourceItem: blurPassV
            hideSource: true
            live: true
            smooth: true
            mipmap: false
            textureSize: Qt.size(root._regionTexWidth, root._regionTexHeight)
        }

        ShaderEffect {
            id: blurPass2H
            visible: glassLayer.effectiveBlurPasses >= 2
            width: root._regionTexWidth
            height: root._regionTexHeight

            property variant source: blurPassVSource
            property vector2d texelSize: root._blurTexel
            property real blurStrength: glassLayer.blurBase * 1.7

            fragmentShader: "../../shaders/blur_h.frag.qsb"
        }

        ShaderEffectSource {
            id: blurPass2HSource
            sourceItem: blurPass2H
            hideSource: true
            live: glassLayer.effectiveBlurPasses >= 2
            smooth: true
            mipmap: false
            textureSize: Qt.size(root._regionTexWidth, root._regionTexHeight)
        }

        ShaderEffect {
            id: blurPass2V
            visible: glassLayer.effectiveBlurPasses >= 2
            width: root._regionTexWidth
            height: root._regionTexHeight

            property variant source: blurPass2HSource
            property vector2d texelSize: root._blurTexel
            property real blurStrength: glassLayer.blurBase * 1.7

            fragmentShader: "../../shaders/blur_v.frag.qsb"
        }

        ShaderEffectSource {
            id: blurPass2VSource
            sourceItem: blurPass2V
            hideSource: true
            live: glassLayer.effectiveBlurPasses >= 2
            smooth: true
            mipmap: false
            textureSize: Qt.size(root._regionTexWidth, root._regionTexHeight)
        }

        ShaderEffect {
            id: blurPass3H
            visible: glassLayer.effectiveBlurPasses >= 3
            width: root._regionTexWidth
            height: root._regionTexHeight

            property variant source: blurPass2VSource
            property vector2d texelSize: root._blurTexel
            property real blurStrength: glassLayer.blurBase * 2.4

            fragmentShader: "../../shaders/blur_h.frag.qsb"
        }

        ShaderEffectSource {
            id: blurPass3HSource
            sourceItem: blurPass3H
            hideSource: true
            live: glassLayer.effectiveBlurPasses >= 3
            smooth: true
            mipmap: false
            textureSize: Qt.size(root._regionTexWidth, root._regionTexHeight)
        }

        ShaderEffect {
            id: blurPass3V
            visible: glassLayer.effectiveBlurPasses >= 3
            width: root._regionTexWidth
            height: root._regionTexHeight

            property variant source: blurPass3HSource
            property vector2d texelSize: root._blurTexel
            property real blurStrength: glassLayer.blurBase * 2.4

            fragmentShader: "../../shaders/blur_v.frag.qsb"
        }

        ShaderEffectSource {
            id: blurPass3VSource
            sourceItem: blurPass3V
            hideSource: true
            live: glassLayer.effectiveBlurPasses >= 3
            smooth: true
            mipmap: false
            textureSize: Qt.size(root._regionTexWidth, root._regionTexHeight)
        }

        ShaderEffect {
            id: liquidGlass
            anchors.fill: parent
            visible: root._hasBackgroundTexture && root.glassOpacity > 0.0

            property variant sceneTex: glassLayer.effectiveBlurPasses >= 3
                ? blurPass3VSource
                : (glassLayer.effectiveBlurPasses >= 2 ? blurPass2VSource : blurPassVSource)
            property vector2d uSize: Qt.vector2d(width, height)
            property vector4d uUvRect: Qt.vector4d(0.0, 0.0, 1.0, 1.0)
            property real uRadius: root.radius
            property real uRefraction: root.refraction
            property real uDepth: root.depth
            property real uDispersion: root.dispersion
            property real uFrost: root.frost
            property real uSplay: root.splay
            property real uGlassOpacity: root.glassOpacity * root.materialOpacity
            property color uTint: root.glassTint
            property real uTime: root._shaderTime
            property real uDebug: root.glassDebug ? 1.0 : 0.0
            property real uLightAngleDeg: root.lightAngleDeg
            property real uLightStrength: root.lightStrength
            property real uLightWidthPx: root.lightWidthPx
            property real uLightSharpness: root.lightSharpness
            property real uBodyRefractionWidthPx: root.bodyRefractionWidthPx
            property real uCornerBoost: root.cornerBoost
            property real uDispersionLimit: root.dispersionLimit
            property real uDispersionWidthPx: root.dispersionWidthPx
            property real uDispersionCurve: root.dispersionCurve

            fragmentShader: "../../shaders/liquid_glass.frag.qsb"
        }

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            visible: !root._hasBackgroundTexture || root.glassOpacity <= 0.0
            color: Qt.rgba(root.widgetBackground.r, root.widgetBackground.g, root.widgetBackground.b, root.widgetBackground.a * root.materialOpacity)
        }

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: Qt.rgba(root.widgetBackground.r, root.widgetBackground.g, root.widgetBackground.b, root.widgetBackground.a * root.materialOpacity * root.glassOpacity)
        }

        Connections {
            target: captureView
            function onHasContentChanged() {
                if (root.useWallpaperSource) {
                    return;
                }
                if (root.glassDebug) {
                    console.log("[WeatherGlass] hasContent:", captureView.hasContent);
                }
                if (captureView.hasContent) {
                    root._capturedOnce = true;
                }
            }
            function onSourceSizeChanged() {
                if (root.useWallpaperSource) {
                    return;
                }
                if (root.glassDebug) {
                    console.log("[WeatherGlass] sourceSize:", captureView.sourceSize.width + "x" + captureView.sourceSize.height);
                }
            }
        }

        Connections {
            target: wallpaperImage
            function onStatusChanged() {
                if (!root.glassDebug) {
                    return;
                }
                console.log("[WeatherGlass] wallpaper status:", wallpaperImage.status, "source:", root.wallpaperSource);
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        z: 2
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPressed: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                root.requestContextMenu(mouse.x, mouse.y);
            }
        }
        onClicked: function (mouse) {
            if (mouse.button === Qt.LeftButton) {
                weatherService.refresh();
                return;
            }
        }
    }

    Column {
        id: smallContent
        z: 1
        visible: !root.isMedium
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 16

        Column {
            spacing: -3

            Row {
                spacing: 4

                Text {
                    text: root.displayLocation.trim().length > 0 ? root.displayLocation : weatherService.data.city
                    color: "#FFFFFF"
                    opacity: 0.75
                    elide: Text.ElideRight
                    width: 100
                    font.family: "SF Pro Text"
                    font.weight: Font.ExtraBold
                    font.pixelSize: 14
                }

                Item {
                    width: 2
                    height: 1
                }

                Text {
                    visible: weatherService.offline
                    text: "Offline"
                    color: "#D8A5A5"
                    font.family: "SF Pro Text"
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
            }

            Text {
                text: weatherService.data.temp === "—" ? "—" : weatherService.data.temp + "°"
                color: "#FFFFFF"
                opacity: 0.75
                font.family: "SF Pro Display"
                font.pixelSize: 42
                font.weight: Font.Normal
                lineHeight: 0.9
            }
        }

        Column {
            spacing: 0

            Text {
                width: 19
                height: 19
                text: weatherService.data.symbol
                color: "#FFFFFF"
                opacity: 0.75
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.family: "SF Pro"
                font.pixelSize: 16
                font.weight: Font.Normal
            }

            Text {
                text: weatherService.data.condition
                color: "#FFFFFF"
                opacity: 0.75
                font.family: "SF Pro Text"
                font.pixelSize: 13
                font.weight: Font.Bold
                elide: Text.ElideRight
                width: 120
            }

            Item {
                width: 2
                height: 2
            }

            Text {
                text: "H:" + weatherService.data.high + "° L:" + weatherService.data.low + "°"
                color: "#FFFFFF"
                opacity: 0.75
                font.family: "SF Pro Text"
                font.pixelSize: 13
                font.weight: Font.Bold
            }
        }
    }

    Column {
        id: mediumContent
        z: 1
        visible: root.isMedium
        anchors.fill: parent
        anchors.margins: 16
        spacing: 4

        Row {
            width: parent.width
            spacing: 12

            Column {
                width: 156
                spacing: -2

                Row {
                    spacing: 4

                    Text {
                        text: root.displayLocation.trim().length > 0 ? root.displayLocation : weatherService.data.city
                        color: "#FFFFFF"
                        opacity: 0.75
                        elide: Text.ElideRight
                        width: 112
                        font.family: "SF Pro Text"
                        font.weight: Font.ExtraBold
                        font.pixelSize: 14
                    }

                    Text {
                        visible: weatherService.offline
                        text: "Offline"
                        color: "#D8A5A5"
                        font.family: "SF Pro Text"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: weatherService.data.temp === "—" ? "—" : weatherService.data.temp + "°"
                    color: "#FFFFFF"
                    opacity: 0.75
                    font.family: "SF Pro Display"
                    font.pixelSize: 42
                    font.weight: Font.Normal
                    lineHeight: 0.9
                }
            }

            Column {
                width: parent.width - 168
                spacing: 0

                Text {
                    text: weatherService.data.symbol
                    color: "#FFFFFF"
                    opacity: 0.75
                    horizontalAlignment: Text.AlignRight
                    width: parent.width
                    font.family: "SF Pro"
                    font.pixelSize: 16
                    font.weight: Font.Normal
                }

                Item {
                    width: 2
                    height: 4
                }

                Text {
                    text: weatherService.data.condition
                    color: "#FFFFFF"
                    opacity: 0.75
                    font.family: "SF Pro Text"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignRight
                    width: parent.width
                }

                Text {
                    text: "H:" + weatherService.data.high + "° L:" + weatherService.data.low + "°"
                    color: "#FFFFFF"
                    opacity: 0.75
                    font.family: "SF Pro Text"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    horizontalAlignment: Text.AlignRight
                    width: parent.width
                }
            }
        }

        Row {
            id: hourlyRow
            width: parent.width
            x: -8
            spacing: 4

            Repeater {
                model: 6

                Column {
                    required property int index

                    width: root.isMedium ? (mediumContent.width / 6) : 0
                    spacing: 6

                    readonly property var hourlyEntry: {
                        const hourly = root.service.data.hourly;
                        if (!Array.isArray(hourly) || index >= hourly.length) {
                            return {
                                timeLabel: "—",
                                symbol: "—",
                                temp: "—"
                            };
                        }
                        return hourly[index];
                    }

                    Text {
                        text: parent.hourlyEntry.timeLabel || "—"
                        color: "#FFFFFF"
                        opacity: 0.6
                        font.family: "SF Pro Text"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }

                    Text {
                        text: parent.hourlyEntry.symbol || "—"
                        color: "#FFFFFF"
                        opacity: 0.75
                        font.family: "SF Pro"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }

                    Text {
                        text: parent.hourlyEntry.temp === "—" ? "—" : parent.hourlyEntry.temp + "°"
                        color: "#FFFFFF"
                        opacity: 0.75
                        font.family: "SF Pro Text"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        width: parent.width
                    }
                }
            }
        }
    }

    Text {
        visible: root.glassDebug
        z: 4
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 6
        color: "#FFFFFF"
        style: Text.Outline
        styleColor: "#000000"
        font.family: "SF Pro Text"
        font.pixelSize: 9
        text: "mode=" + (root.useWallpaperSource ? "wallpaper" : "capture")
            + " glass=" + liquidGlass.visible
            + " has=" + root._hasBackgroundTexture
            + " src=" + captureView.sourceSize.width + "x" + captureView.sourceSize.height
            + " tex=" + root._regionTexWidth + "x" + root._regionTexHeight
            + " b=" + root.blurSize + " p=" + glassLayer.effectiveBlurPasses
    }
}
