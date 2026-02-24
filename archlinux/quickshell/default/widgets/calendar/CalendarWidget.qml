pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland

import "../.." as Root

Rectangle {
    id: root

    implicitWidth: 164
    implicitHeight: 164
    radius: 22
    clip: true

    signal requestContextMenu(real x, real y)

    property bool showLabel: false
    property bool followSystemDate: true

    property int shownYear: (new Date()).getFullYear()
    property int shownMonth: (new Date()).getMonth()

    property color calendarBackground: Qt.rgba(20 / 255, 20 / 255, 20 / 255, 0.00)
    property color accentColor: Qt.rgba(Root.Theme.textPrimary.r, Root.Theme.textPrimary.g, Root.Theme.textPrimary.b, 0.75)
    property color weekendColor: Qt.rgba(Root.Theme.textPrimary.r, Root.Theme.textPrimary.g, Root.Theme.textPrimary.b, 0.50)
    property color dateColor: Qt.rgba(Root.Theme.textPrimary.r, Root.Theme.textPrimary.g, Root.Theme.textPrimary.b, 0.75)

    property real materialOpacity: 1.0

    // Liquid glass controls
    property var screen: null
    property string wallpaperSource: ""
    readonly property bool useWallpaperSource: root.wallpaperSource.length > 0
    property real refraction: 0.0
    property real depth: 0.0
    property real dispersion: 5
    property real frost: 0.0
    property real splay: 5.0
    property real splayDepth: 18.0
    property real rimWidth: 18.0
    property real rimStrength: 1.0
    property real bodyDepth: 64.0
    property real bodyExponent: 0.75
    property real bodyStrength: 0.25
    property real magnifyStrength: 0.03
    property real vibrance: 0.0
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
    property color glassTint: Qt.rgba(0.92, 0.97, 1.0, 0)
    property bool liveCapture: false
    property bool autoRecapture: false
    property real blurSize: 0.9
    property real blurPasses: 2
    property bool glassDebug: false
    property int glassDebugView: 2

    readonly property int cellSize: 18
    readonly property int rowGap: 6
    readonly property int gridWidth: 134

    // Model
    property var cells: []
    property int rowsUsed: 6

    property int _lastSystemDay: -1
    property int _lastSystemMonth: -1
    property int _lastSystemYear: -1
    property real _shaderTime: 0.0
    property bool _capturedOnce: false
    property bool _captureRequested: false

    readonly property var weekdayLabels: ["S", "M", "T", "W", "T", "F", "S"]

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

    readonly property real _itemXOnCapture: root._clamp(root._itemXOnOutputLogical * root._logicalToCaptureX, 0.0, Math.max(0.0, root._captureWidth - 1.0))
    readonly property real _itemYOnCapture: root._clamp(root._itemYOnOutputLogical * root._logicalToCaptureY, 0.0, Math.max(0.0, root._captureHeight - 1.0))
    readonly property real _itemWOnCapture: root._clamp(root.width * root._logicalToCaptureX, 1.0, root._captureWidth)
    readonly property real _itemHOnCapture: root._clamp(root.height * root._logicalToCaptureY, 1.0, root._captureHeight)

    // UV mapping into the captured output texture: (u0, v0, uScale, vScale)
    readonly property vector4d uvRect: Qt.vector4d(root._itemXOnCapture / Math.max(1.0, root._captureWidth), root._itemYOnCapture / Math.max(1.0, root._captureHeight), root._itemWOnCapture / Math.max(1.0, root._captureWidth), root._itemHOnCapture / Math.max(1.0, root._captureHeight))

    readonly property int _regionTexWidth: Math.max(1, Math.round(root._itemWOnCapture))
    readonly property int _regionTexHeight: Math.max(1, Math.round(root._itemHOnCapture))
    readonly property vector2d _blurTexel: Qt.vector2d(1.0 / root._regionTexWidth, 1.0 / root._regionTexHeight)

    color: "transparent"

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

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function monthLabel(year, month) {
        const value = new Date(year, month, 1).toLocaleString(Qt.locale(), "MMMM");
        return value.toUpperCase();
    }

    function buildCells(year, month) {
        const result = [];
        const now = new Date();
        const todayDay = now.getDate();
        const todayMonth = now.getMonth();
        const todayYear = now.getFullYear();

        // Sunday-first offset: 0..6
        const firstDayOffset = new Date(year, month, 1).getDay();
        const total = daysInMonth(year, month);

        // How many rows are actually needed this month: 4..6
        const neededRows = Math.ceil((firstDayOffset + total) / 7);
        rowsUsed = Math.max(4, Math.min(6, neededRows));

        for (let i = 0; i < 42; i++) {
            const day = i - firstDayOffset + 1;
            const inMonth = day >= 1 && day <= total;
            const col = i % 7;
            const isToday = inMonth && day === todayDay && month === todayMonth && year === todayYear;
            result.push({
                day: inMonth ? day : 0,
                inMonth: inMonth,
                isToday: isToday,
                col: col
            });
        }

        return result;
    }

    function refreshCells() {
        cells = buildCells(shownYear, shownMonth);
    }

    function colorToRgbaString(value, opacityScale) {
        const alpha = Math.max(0, Math.min(1, value.a * opacityScale));
        return "rgba(" + Math.round(value.r * 255) + "," + Math.round(value.g * 255) + "," + Math.round(value.b * 255) + "," + alpha + ")";
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
        interval: 60 * 1000
        repeat: true
        running: true
        onTriggered: {
            const now = new Date();
            const day = now.getDate();
            const month = now.getMonth();
            const year = now.getFullYear();

            const changed = day !== root._lastSystemDay || month !== root._lastSystemMonth || year !== root._lastSystemYear;

            if (!changed) {
                return;
            }

            root._lastSystemDay = day;
            root._lastSystemMonth = month;
            root._lastSystemYear = year;

            if (root.followSystemDate) {
                root.shownYear = year;
                root.shownMonth = month;
            }

            root.refreshCells();
        }
    }

    Timer {
        id: initialCaptureTimer
        interval: 450
        repeat: false
        running: !root.useWallpaperSource
        onTriggered: root.requestCaptureFrame(false)
    }

    Component.onCompleted: {
        const now = new Date();
        _lastSystemDay = now.getDate();
        _lastSystemMonth = now.getMonth();
        _lastSystemYear = now.getFullYear();
        refreshCells();
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
            id: downsampledCapture
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

            property variant source: downsampledCapture
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
            property real uSplayDepth: root.splayDepth
            property real uRimWidth: root.rimWidth
            property real uRimStrength: root.rimStrength
            property real uBodyDepth: root.bodyDepth
            property real uBodyExponent: root.bodyExponent
            property real uBodyStrength: root.bodyStrength
            property real uMagnifyStrength: root.magnifyStrength
            property real uVibrance: root.vibrance
            property real uGlassOpacity: root.glassOpacity * root.materialOpacity
            property color uTint: root.glassTint
            property real uTime: root._shaderTime
            property real uDebug: root.glassDebug ? 1.0 : 0.0
            property real uDebugView: root.glassDebugView
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
            color: Qt.rgba(root.calendarBackground.r, root.calendarBackground.g, root.calendarBackground.b, root.calendarBackground.a * root.materialOpacity)
        }

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: Qt.rgba(root.calendarBackground.r, root.calendarBackground.g, root.calendarBackground.b, root.calendarBackground.a * root.materialOpacity * root.glassOpacity)
        }

        Connections {
            target: captureView
            function onHasContentChanged() {
                if (root.useWallpaperSource) {
                    return;
                }
                if (root.glassDebug) {
                    console.log("[CalendarGlass] hasContent:", captureView.hasContent);
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
                    console.log("[CalendarGlass] sourceSize:", captureView.sourceSize.width + "x" + captureView.sourceSize.height);
                }
            }
        }

        Connections {
            target: wallpaperImage
            function onStatusChanged() {
                if (!root.glassDebug) {
                    return;
                }

                console.log("[CalendarGlass] wallpaper status:", wallpaperImage.status, "source:", root.wallpaperSource);
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 2
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onEntered: {
            if (root.autoRecapture)
                root.requestCaptureFrame(false);
        }
        onPressed: function (mouse) {
            if (mouse.button === Qt.RightButton) {
                root.requestContextMenu(mouse.x, mouse.y);
            }
        }
    }

    Item {
        id: content
        z: 1
        anchors.fill: parent
        anchors.topMargin: 17
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.bottomMargin: 16

        Item {
            id: monthHeader
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 15

            Text {
                anchors.top: parent.top
                anchors.topMargin: 2
                anchors.left: parent.left
                anchors.leftMargin: 4
                text: root.monthLabel(root.shownYear, root.shownMonth)
                color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, root.accentColor.a * root.materialOpacity)
                font.family: Root.Theme.fontFamily
                font.weight: Font.DemiBold
                font.pixelSize: 11
                renderType: Text.NativeRendering
            }
        }

        Item {
            id: weekdayRow
            anchors.top: monthHeader.bottom
            anchors.topMargin: 3
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.gridWidth
            height: root.cellSize

            readonly property real xStride: (width - (7 * root.cellSize)) / 6

            Repeater {
                model: root.weekdayLabels.length
                delegate: Item {
                    id: weekdayCell
                    required property int index
                    x: index * (root.cellSize + weekdayRow.xStride)
                    width: root.cellSize
                    height: root.cellSize

                    Text {
                        anchors.centerIn: parent
                        text: root.weekdayLabels[weekdayCell.index]
                        color: (weekdayCell.index === 0 || weekdayCell.index === 6) ? root.weekendColor : root.dateColor
                        font.family: Root.Theme.fontFamily
                        font.weight: Font.DemiBold
                        font.pixelSize: 10
                        opacity: root.materialOpacity
                        renderType: Text.NativeRendering
                    }
                }
            }
        }

        Item {
            id: dateGrid
            anchors.top: weekdayRow.bottom
            anchors.topMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.gridWidth
            height: (root.rowsUsed * root.cellSize) + ((root.rowsUsed - 1) * root.rowGap)

            readonly property real xStride: (width - (7 * root.cellSize)) / 6

            Repeater {
                model: root.cells
                delegate: Item {
                    id: dayCell
                    required property int index
                    required property var modelData

                    property int col: modelData.col
                    property int row: Math.floor(index / 7)

                    // Hide rows not used this month so we can shrink the grid height.
                    visible: row < root.rowsUsed

                    x: col * (root.cellSize + dateGrid.xStride)
                    y: row * (root.cellSize + root.rowGap)
                    width: root.cellSize
                    height: root.cellSize

                    Canvas {
                        anchors.fill: parent
                        visible: dayCell.modelData.isToday
                        smooth: true
                        antialiasing: true
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);

                            ctx.fillStyle = root.colorToRgbaString(root.accentColor, root.materialOpacity);
                            ctx.beginPath();
                            ctx.arc(width * 0.5, height * 0.5, Math.min(width, height) * 0.5, 0, Math.PI * 2);
                            ctx.fill();

                            ctx.globalCompositeOperation = "destination-out";
                            ctx.fillStyle = "rgba(0,0,0,1)";
                            ctx.textAlign = "center";
                            ctx.textBaseline = "middle";
                            ctx.font = "800 10px '" + Root.Theme.fontFamily + "'";
                            ctx.fillText(String(dayCell.modelData.day), width * 0.5, height * 0.5 + 0.5);
                        }
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        onVisibleChanged: requestPaint()
                        Component.onCompleted: requestPaint()
                    }

                    Text {
                        anchors.centerIn: parent
                        text: dayCell.modelData.inMonth ? String(dayCell.modelData.day) : ""
                        visible: dayCell.modelData.inMonth && !dayCell.modelData.isToday
                        color: (dayCell.col === 0 || dayCell.col === 6) ? root.weekendColor : root.dateColor
                        font.family: Root.Theme.fontFamily
                        font.weight: Font.ExtraBold
                        font.pixelSize: 10
                        opacity: root.materialOpacity
                        renderType: Text.NativeRendering
                    }
                }
            }
        }
    }

    Text {
        visible: root.showLabel
        anchors.top: root.bottom
        anchors.topMargin: 9
        anchors.horizontalCenter: root.horizontalCenter
        text: "Calendar"
        color: Qt.rgba(Root.Theme.textPrimary.r, Root.Theme.textPrimary.g, Root.Theme.textPrimary.b, 0.92)
        font.family: Root.Theme.fontFamily
        font.weight: Font.DemiBold
        font.pixelSize: 12
        style: Text.Raised
        styleColor: Qt.rgba(Root.Theme.textOutline.r, Root.Theme.textOutline.g, Root.Theme.textOutline.b, 0.7)
        renderType: Text.NativeRendering
    }

    Text {
        visible: root.glassDebug
        z: 4
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 6
        color: Root.Theme.textPrimary
        style: Text.Outline
        styleColor: Root.Theme.textOutline
        font.family: Root.Theme.fontFamily
        font.pixelSize: 9
        text: "mode=" + (root.useWallpaperSource ? "wallpaper" : "capture")
            + " glass=" + liquidGlass.visible
            + " has=" + root._hasBackgroundTexture
            + " src=" + captureView.sourceSize.width + "x" + captureView.sourceSize.height
            + " tex=" + root._regionTexWidth + "x" + root._regionTexHeight
            + " b=" + root.blurSize + " p=" + glassLayer.effectiveBlurPasses
            + " dbg=" + root.glassDebugView
    }
}
