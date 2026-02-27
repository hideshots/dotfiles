import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtCore
import QtQml.Models
import Qt5Compat.GraphicalEffects

import "." as Root
import "menu" as Menu
import "modules/notifications" as Notifications
import "widgets" as Widgets

ShellRoot {
    id: shell
    // Force-load notifications backend so NotificationServer is active without UI components.
    readonly property var notificationService: Root.NotificationService
    Component.onCompleted: notificationService.refreshTimeLabels()
    // Notifications { }
    property bool weatherEnabled: true
    property bool calendarEnabled: true
    property bool notificationsPopupEnabled: true
    property int notificationsPopupTopMargin: 33
    property int notificationsPopupRightMargin: 16
    property int notificationsPopupMaxVisible: 5
    property bool notificationsExternalDismissEnabled: true
    property bool notificationsExternalPopupActionsEnabled: true
    property int notificationsDismissWindowBleed: 6
    property int notificationsActionWindowBleed: 3
    property int notificationsDismissHoverOverlapPx: 5
    property int notificationsActionHoverOverlapPx: 6
    property int notificationsControlFadeInMs: 150
    property int notificationsControlFadeOutMs: 200
    readonly property color notificationsControlTintColor: Root.Theme.isDark ? Qt.rgba(0, 0, 0, 0.16) : Qt.rgba(0.98, 0.99, 1.0, 0.24)
    readonly property color notificationsControlHoverTintColor: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.26) : Qt.rgba(1, 1, 1, 0.34)
    readonly property color notificationsControlBorderColor: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.52)
    property bool notificationCenterOpen: false
    property var notificationCenterTriggerItem: null
    property bool notificationCenterEnabled: true
    property int notificationCenterTopMargin: 44
    property int notificationCenterRightMargin: 16
    onNotificationCenterOpenChanged: {
        if (!shell.notificationCenterOpen) {
            shell.notificationCenterTriggerItem = null;
        }
    }
    function toggleNotificationCenter(triggerItem) {
        var hasTrigger = triggerItem !== undefined && triggerItem !== null;

        if (shell.notificationCenterOpen) {
            if (hasTrigger && shell.notificationCenterTriggerItem !== triggerItem) {
                shell.notificationCenterTriggerItem = triggerItem;
                return;
            }
            shell.notificationCenterOpen = false;
            return;
        }

        shell.notificationCenterTriggerItem = hasTrigger ? triggerItem : null;
        shell.notificationCenterOpen = true;
    }
    Shortcut {
        sequence: "Escape"
        context: Qt.ApplicationShortcut
        enabled: shell.notificationCenterOpen
        onActivated: shell.notificationCenterOpen = false
    }
    property int weatherPanelTopMargin: 50
    property int weatherPanelLeftMargin: 10
    property int calendarPanelGap: 10
    property string weatherLocation: "Krasnodar"
    property string weatherDisplayLocation: "Richmond"
    property string weatherUnits: "u"
    property string weatherVariant: "medium"
    property bool widgetGlassDebug: false
    property real widgetGlassRefraction: 8.2
    property real widgetGlassBodyRefractionWidthPx: 32.0
    property real widgetGlassDepth: 0.2
    property real widgetGlassDispersion: 1.0
    property real widgetGlassFrost: 0.7
    property real widgetGlassSplay: 2.5
    property real widgetGlassSplayDepth: 30.0
    property real widgetGlassRimWidth: 15.0
    property real widgetGlassRimStrength: 1.0
    property real widgetGlassBodyDepth: 64.0
    property real widgetGlassBodyExponent: 0.75
    property real widgetGlassBodyStrength: 0.25
    property real widgetGlassMagnifyStrength: -0.1
    property real widgetGlassVibrance: 0.8
    property int widgetGlassDebugView: 0
    property real widgetGlassLightAngleDeg: 335
    property real widgetGlassLightStrength: 3.0
    property real widgetGlassLightWidthPx: 3.0
    property real widgetGlassLightSharpness: 0.0
    property real widgetGlassCornerBoost: 0.5
    property real widgetGlassDispersionLimit: 1.0
    property real widgetGlassDispersionWidthPx: 9.0
    property real widgetGlassDispersionCurve: 0.9
    property real widgetGlassOpacity: 1.0
    property color widgetGlassTint: Qt.rgba(1.0, 1.0, 1.0, 0.08)
    property real widgetGlassBlurSize: 0.7
    property real widgetGlassBlurPasses: 2
    property bool widgetGlassLiveCapture: false
    property bool widgetGlassAutoRecapture: false
    readonly property string _cacheDir: StandardPaths.writableLocation(StandardPaths.GenericCacheLocation)
    readonly property string _wallpaperStatePath: shell._cacheDir + "/quickshell/wallpaper"
    property string _wallpaperPathRaw: ""
    property string _wallpaperProbeLoadedPath: ""
    readonly property string wallpaperPathTrimmed: String(shell._wallpaperPathRaw).trim()
    readonly property bool wallpaperFileExists: shell.wallpaperPathTrimmed.length > 0 && shell._wallpaperProbeLoadedPath === shell.wallpaperPathTrimmed
    readonly property bool useWallpaperSource: shell.wallpaperPathTrimmed.length > 0 && shell.wallpaperFileExists
    readonly property string widgetWallpaperSource: shell.useWallpaperSource ? shell.wallpaperPathTrimmed : ""

    onWallpaperPathTrimmedChanged: shell._wallpaperProbeLoadedPath = ""

    FileView {
        id: wallpaperStateFile
        path: shell._wallpaperStatePath
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: shell._wallpaperPathRaw = wallpaperStateFile.text()
        onLoadFailed: shell._wallpaperPathRaw = ""
        onFileChanged: wallpaperStateFile.reload()
    }

    FileView {
        id: wallpaperProbeFile
        path: shell.wallpaperPathTrimmed.length > 0 ? shell.wallpaperPathTrimmed : ""
        preload: true
        watchChanges: true
        printErrors: false
        onLoaded: shell._wallpaperProbeLoadedPath = wallpaperProbeFile.path
        onLoadFailed: shell._wallpaperProbeLoadedPath = ""
        onFileChanged: wallpaperProbeFile.reload()
    }

    PanelWindow {
        id: weatherPanel
        visible: shell.weatherEnabled

        anchors.top: true
        anchors.left: true
        margins.top: shell.weatherPanelTopMargin
        margins.left: shell.weatherPanelLeftMargin + (shell.calendarEnabled ? (calendarWidget.implicitWidth + shell.calendarPanelGap) : 0)
        exclusionMode: ExclusionMode.Ignore

        color: "transparent"
        surfaceFormat.opaque: false
        focusable: false
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:weather"
        HyprlandWindow.visibleMask: weatherMask

        implicitWidth: weatherWidget.implicitWidth
        implicitHeight: weatherWidget.implicitHeight

        Region {
            id: weatherMask
            item: weatherWidget
        }

        Widgets.WeatherWidget {
            id: weatherWidget
            anchors.fill: parent
            screen: weatherPanel.screen
            location: shell.weatherLocation
            displayLocation: shell.weatherDisplayLocation
            units: shell.weatherUnits
            variant: shell.weatherVariant
            wallpaperSource: shell.widgetWallpaperSource
            refraction: shell.widgetGlassRefraction
            depth: shell.widgetGlassDepth
            dispersion: shell.widgetGlassDispersion
            frost: shell.widgetGlassFrost
            splay: shell.widgetGlassSplay
            splayDepth: shell.widgetGlassSplayDepth
            rimWidth: shell.widgetGlassRimWidth
            rimStrength: shell.widgetGlassRimStrength
            bodyDepth: shell.widgetGlassBodyDepth
            bodyExponent: shell.widgetGlassBodyExponent
            bodyStrength: shell.widgetGlassBodyStrength
            magnifyStrength: shell.widgetGlassMagnifyStrength
            vibrance: shell.widgetGlassVibrance
            lightAngleDeg: shell.widgetGlassLightAngleDeg
            lightStrength: shell.widgetGlassLightStrength
            lightWidthPx: shell.widgetGlassLightWidthPx
            lightSharpness: shell.widgetGlassLightSharpness
            bodyRefractionWidthPx: shell.widgetGlassBodyRefractionWidthPx
            cornerBoost: shell.widgetGlassCornerBoost
            dispersionLimit: shell.widgetGlassDispersionLimit
            dispersionWidthPx: shell.widgetGlassDispersionWidthPx
            dispersionCurve: shell.widgetGlassDispersionCurve
            glassOpacity: shell.widgetGlassOpacity
            glassTint: shell.widgetGlassTint
            blurSize: shell.widgetGlassBlurSize
            blurPasses: shell.widgetGlassBlurPasses
            liveCapture: shell.widgetGlassLiveCapture
            autoRecapture: shell.widgetGlassAutoRecapture
            glassDebug: shell.widgetGlassDebug
            glassDebugView: shell.widgetGlassDebugView
            onRequestContextMenu: function (x, y) {
                weatherSizeMenu.anchorPointX = x + 4;
                weatherSizeMenu.anchorPointY = y + 8;
                weatherSizeMenu.anchor.updateAnchor();
                if (weatherSizeMenu.visible) {
                    weatherSizeMenu.close();
                }
                weatherSizeMenu.open();
            }
        }

        Menu.MenuPopup {
            id: weatherSizeMenu
            anchorItem: weatherWidget
            yOffset: 8
            adaptiveWidth: true
            model: [
                {
                    type: "action",
                    label: "Small",
                    reserveCheckmark: true,
                    checked: shell.weatherVariant === "small",
                    action: function () {
                        shell.weatherVariant = "small";
                    }
                },
                {
                    type: "action",
                    label: "Medium",
                    reserveCheckmark: true,
                    checked: shell.weatherVariant === "medium",
                    action: function () {
                        shell.weatherVariant = "medium";
                    }
                }
            ]
        }
    }

    PanelWindow {
        id: calendarPanel
        visible: shell.weatherEnabled && shell.calendarEnabled

        anchors.top: true
        anchors.left: true
        margins.top: shell.weatherPanelTopMargin
        margins.left: shell.weatherPanelLeftMargin
        exclusionMode: ExclusionMode.Ignore

        color: "transparent"
        surfaceFormat.opaque: false
        focusable: false
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:calendar"
        HyprlandWindow.visibleMask: calendarMask

        implicitWidth: calendarWidget.implicitWidth
        implicitHeight: calendarWidget.implicitHeight

        Region {
            id: calendarMask
            item: calendarWidget
        }

        Widgets.CalendarWidget {
            id: calendarWidget
            anchors.fill: parent
            screen: calendarPanel.screen
            wallpaperSource: shell.widgetWallpaperSource
            refraction: shell.widgetGlassRefraction
            depth: shell.widgetGlassDepth
            dispersion: shell.widgetGlassDispersion
            frost: shell.widgetGlassFrost
            splay: shell.widgetGlassSplay
            splayDepth: shell.widgetGlassSplayDepth
            rimWidth: shell.widgetGlassRimWidth
            rimStrength: shell.widgetGlassRimStrength
            bodyDepth: shell.widgetGlassBodyDepth
            bodyExponent: shell.widgetGlassBodyExponent
            bodyStrength: shell.widgetGlassBodyStrength
            magnifyStrength: shell.widgetGlassMagnifyStrength
            vibrance: shell.widgetGlassVibrance
            lightAngleDeg: shell.widgetGlassLightAngleDeg
            lightStrength: shell.widgetGlassLightStrength
            lightWidthPx: shell.widgetGlassLightWidthPx
            lightSharpness: shell.widgetGlassLightSharpness
            bodyRefractionWidthPx: shell.widgetGlassBodyRefractionWidthPx
            cornerBoost: shell.widgetGlassCornerBoost
            dispersionLimit: shell.widgetGlassDispersionLimit
            dispersionWidthPx: shell.widgetGlassDispersionWidthPx
            dispersionCurve: shell.widgetGlassDispersionCurve
            glassOpacity: shell.widgetGlassOpacity
            glassTint: shell.widgetGlassTint
            blurSize: shell.widgetGlassBlurSize
            blurPasses: shell.widgetGlassBlurPasses
            liveCapture: shell.widgetGlassLiveCapture
            autoRecapture: shell.widgetGlassAutoRecapture
            glassDebug: shell.widgetGlassDebug
            glassDebugView: shell.widgetGlassDebugView
        }
    }

    PanelWindow {
        id: notificationsPopupPanel
        visible: shell.notificationsPopupEnabled && shell.notificationService.activeCount > 0

        anchors.top: true
        anchors.right: true
        margins.top: shell.notificationsPopupTopMargin
        margins.right: shell.notificationsPopupRightMargin
        exclusionMode: ExclusionMode.Ignore

        color: "transparent"
        surfaceFormat.opaque: false
        focusable: false
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:notifications"

        implicitWidth: popupStack.implicitWidth
        implicitHeight: popupStack.implicitHeight

        Notifications.PopupStack {
            id: popupStack
            anchors.fill: parent
            maxVisible: shell.notificationsPopupMaxVisible
            externalDismissEnabled: shell.notificationsExternalDismissEnabled
            externalPopupActionsEnabled: shell.notificationsExternalPopupActionsEnabled
        }
    }

    Instantiator {
        id: popupDismissWindowInstantiator
        model: shell.notificationsExternalDismissEnabled ? popupStack.dismissButtonModel : null

        delegate: PanelWindow {
            id: popupDismissWindow
            required property int notificationId
            required property int buttonX
            required property int buttonY
            required property int buttonSize
            required property real buttonOpacity
            readonly property int hoverOverlapTowardsCard: Math.max(0, shell.notificationsDismissHoverOverlapPx)
            readonly property bool popupActive: popupStack.isPopupNotificationActive(notificationId)
            readonly property int clampedButtonSize: Math.max(0, buttonSize)
            readonly property bool hasValidGeometry: notificationId >= 0 && clampedButtonSize > 0
            readonly property real effectiveButtonOpacity: popupActive && hasValidGeometry ? Math.max(0.0, Math.min(1.0, Number(buttonOpacity))) : 0.0
            property int _trackedNotificationId: -1

            function _clearTrackedDismissHover(notificationIdToClear) {
                if (notificationIdToClear >= 0) {
                    popupStack.setExternalDismissHovered(notificationIdToClear, false);
                }
            }

            visible: shell.notificationsPopupEnabled && shell.notificationsExternalDismissEnabled && popupActive && hasValidGeometry
            exclusionMode: ExclusionMode.Ignore
            anchors.top: true
            anchors.right: true
            margins.top: shell.notificationsPopupTopMargin + buttonY - shell.notificationsDismissWindowBleed
            margins.right: shell.notificationsPopupRightMargin + popupStack.width - (buttonX + clampedButtonSize + shell.notificationsDismissWindowBleed) - hoverOverlapTowardsCard
            screen: notificationsPopupPanel.screen

            color: "transparent"
            surfaceFormat.opaque: false
            focusable: false
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell:notification-dismiss"

            implicitWidth: clampedButtonSize + (shell.notificationsDismissWindowBleed * 2) + hoverOverlapTowardsCard
            implicitHeight: clampedButtonSize + (shell.notificationsDismissWindowBleed * 2) + hoverOverlapTowardsCard

            onVisibleChanged: {
                if (!visible) {
                    _clearTrackedDismissHover(_trackedNotificationId);
                }
            }

            onNotificationIdChanged: {
                if (_trackedNotificationId === notificationId) {
                    return;
                }
                _clearTrackedDismissHover(_trackedNotificationId);
                _trackedNotificationId = notificationId;
            }

            Component.onCompleted: _trackedNotificationId = notificationId

            Component.onDestruction: _clearTrackedDismissHover(_trackedNotificationId)

            Item {
                anchors.fill: parent

                HoverHandler {
                    id: dismissWindowHoverHandler
                    onHoveredChanged: {
                        if (!popupDismissWindow.popupActive || !popupDismissWindow.hasValidGeometry) {
                            popupStack.setExternalDismissHovered(popupDismissWindow.notificationId, false);
                            return;
                        }
                        popupStack.setExternalDismissHovered(popupDismissWindow.notificationId, hovered);
                    }
                }

                Rectangle {
                    id: dismissButton
                    x: shell.notificationsDismissWindowBleed
                    y: shell.notificationsDismissWindowBleed
                    width: popupDismissWindow.clampedButtonSize
                    height: popupDismissWindow.clampedButtonSize
                    radius: Math.round(height / 2)
                    opacity: popupDismissWindow.effectiveButtonOpacity
                    Behavior on opacity {
                        NumberAnimation {
                            duration: popupDismissWindow.effectiveButtonOpacity > dismissButton.opacity ? shell.notificationsControlFadeInMs : shell.notificationsControlFadeOutMs
                            easing.type: Easing.OutCubic
                        }
                    }
                    color: dismissMouseArea.containsMouse ? shell.notificationsControlHoverTintColor : shell.notificationsControlTintColor
                    border.width: 1
                    border.color: shell.notificationsControlBorderColor

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: dismissMouseArea.containsMouse ? Qt.rgba(Root.Theme.menuHighlight.r, Root.Theme.menuHighlight.g, Root.Theme.menuHighlight.b, 0.16) : "transparent"
                    }

                    ShaderEffect {
                        anchors.fill: parent
                        property vector2d uSize: Qt.vector2d(width, height)
                        property real uRadius: dismissButton.radius
                        property real uLightAngleDeg: 330
                        property real uLightStrength: 5.1
                        property real uLightWidthPx: 4.2
                        property real uLightSharpness: 0.28
                        property real uCornerBoost: 0.45
                        property real uEdgeOpacity: 0.72
                        property color uEdgeTint: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.92)
                        fragmentShader: "shaders/notification_edge_light.frag.qsb"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "x"
                        color: Root.Theme.textSecondary
                        font.family: Root.Theme.fontFamilyDisplay
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: dismissMouseArea
                        anchors.fill: parent
                        enabled: popupDismissWindow.effectiveButtonOpacity > 0.01
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        preventStealing: true
                        cursorShape: Qt.PointingHandCursor

                        onPressed: function (mouse) {
                            mouse.accepted = true;
                        }

                        onClicked: function (mouse) {
                            mouse.accepted = true;
                            if (popupDismissWindow.popupActive && popupDismissWindow.notificationId >= 0) {
                                var targetNotificationId = popupDismissWindow.notificationId;
                                var notificationService = Root.NotificationService;
                                popupStack.beginNotificationExternalClose(targetNotificationId);
                                notificationService.dismissNotification(targetNotificationId);
                            }
                        }
                    }
                }
            }
        }
    }

    Instantiator {
        id: popupActionWindowInstantiator
        model: shell.notificationsExternalPopupActionsEnabled ? popupStack.actionOverlayModel : null

        delegate: PanelWindow {
            id: popupActionWindow
            required property int notificationId
            required property int overlayX
            required property int overlayY
            required property int overlayWidth
            required property int overlayHeight
            required property real overlayOpacity
            required property int actionsCount
            required property string actionsJson
            readonly property var resolvedActionsData: _decodedActions(actionsJson)
            readonly property int hoverOverlapTowardsCard: Math.max(0, shell.notificationsActionHoverOverlapPx)
            readonly property bool popupActive: popupStack.isPopupNotificationActive(notificationId)
            readonly property bool hasValidGeometry: notificationId >= 0 && overlayWidth > 0 && overlayHeight > 0
            readonly property bool hasRenderableActions: actionsCount > 0 && resolvedActionsData.length > 0
            readonly property real effectiveOverlayOpacity: popupActive && hasValidGeometry && hasRenderableActions ? Math.max(0.0, Math.min(1.0, Number(overlayOpacity))) : 0.0
            property int _trackedNotificationId: -1

            function _clearTrackedActionHover(notificationIdToClear) {
                if (notificationIdToClear >= 0) {
                    popupStack.setExternalPopupActionsHovered(notificationIdToClear, false);
                }
            }

            function _decodedActions(jsonText) {
                if (!jsonText || jsonText.length === 0) {
                    return [];
                }
                try {
                    var parsed = JSON.parse(jsonText);
                    return parsed && parsed.length !== undefined ? parsed : [];
                } catch (err) {
                    return [];
                }
            }

            visible: shell.notificationsPopupEnabled && shell.notificationsExternalPopupActionsEnabled && popupActive && hasValidGeometry && hasRenderableActions
            exclusionMode: ExclusionMode.Ignore
            anchors.top: true
            anchors.right: true
            margins.top: shell.notificationsPopupTopMargin + overlayY - shell.notificationsActionWindowBleed
            margins.right: shell.notificationsPopupRightMargin + popupStack.width - (overlayX + overlayWidth + shell.notificationsActionWindowBleed)
            screen: notificationsPopupPanel.screen

            color: "transparent"
            surfaceFormat.opaque: false
            focusable: false
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell:notification-actions"

            implicitWidth: Math.max(0, overlayWidth) + (shell.notificationsActionWindowBleed * 2) + hoverOverlapTowardsCard
            implicitHeight: Math.max(0, overlayHeight) + (shell.notificationsActionWindowBleed * 2)

            onVisibleChanged: {
                if (!visible) {
                    _clearTrackedActionHover(_trackedNotificationId);
                }
            }

            onNotificationIdChanged: {
                if (_trackedNotificationId === notificationId) {
                    return;
                }
                _clearTrackedActionHover(_trackedNotificationId);
                _trackedNotificationId = notificationId;
            }

            Component.onCompleted: _trackedNotificationId = notificationId

            Component.onDestruction: _clearTrackedActionHover(_trackedNotificationId)

            Item {
                anchors.fill: parent

                HoverHandler {
                    id: actionWindowHoverHandler
                    onHoveredChanged: {
                        if (!popupActionWindow.popupActive || !popupActionWindow.hasValidGeometry || !popupActionWindow.hasRenderableActions) {
                            popupStack.setExternalPopupActionsHovered(popupActionWindow.notificationId, false);
                            return;
                        }
                        popupStack.setExternalPopupActionsHovered(popupActionWindow.notificationId, hovered);
                    }
                }

                Item {
                    id: actionSurface
                    x: shell.notificationsActionWindowBleed + popupActionWindow.hoverOverlapTowardsCard
                    y: shell.notificationsActionWindowBleed
                    width: popupActionWindow.overlayWidth
                    height: popupActionWindow.overlayHeight
                    opacity: popupActionWindow.effectiveOverlayOpacity
                    Behavior on opacity {
                        NumberAnimation {
                            duration: popupActionWindow.effectiveOverlayOpacity > actionSurface.opacity ? shell.notificationsControlFadeInMs : shell.notificationsControlFadeOutMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    Row {
                        id: popupActionRow
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Repeater {
                            model: popupActionWindow.resolvedActionsData

                            Rectangle {
                                id: popupActionButton
                                required property var modelData
                                readonly property string actionId: modelData && modelData.id !== undefined ? String(modelData.id) : ""
                                readonly property string actionText: modelData && modelData.text !== undefined ? String(modelData.text) : ""

                                visible: actionText.length > 0
                                implicitHeight: 24
                                implicitWidth: Math.min(150, Math.max(70, popupActionLabel.implicitWidth + 16))
                                radius: 8
                                color: popupActionMouseArea.containsMouse ? shell.notificationsControlHoverTintColor : shell.notificationsControlTintColor
                                border.width: 1
                                border.color: shell.notificationsControlBorderColor

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: popupActionMouseArea.containsMouse ? Qt.rgba(Root.Theme.menuHighlight.r, Root.Theme.menuHighlight.g, Root.Theme.menuHighlight.b, 0.22) : "transparent"
                                }

                                ShaderEffect {
                                    anchors.fill: parent
                                    property vector2d uSize: Qt.vector2d(width, height)
                                    property real uRadius: popupActionButton.radius
                                    property real uLightAngleDeg: 330
                                    property real uLightStrength: 5.1
                                    property real uLightWidthPx: 3.5
                                    property real uLightSharpness: 0.28
                                    property real uCornerBoost: 0.45
                                    property real uEdgeOpacity: 0.72
                                    property color uEdgeTint: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.92)
                                    fragmentShader: "shaders/notification_edge_light.frag.qsb"
                                }

                                Text {
                                    id: popupActionLabel
                                    anchors.centerIn: parent
                                    text: popupActionButton.actionText
                                    color: Root.Theme.textPrimary
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    renderType: Text.NativeRendering
                                }

                                MouseArea {
                                    id: popupActionMouseArea
                                    anchors.fill: parent
                                    enabled: popupActionWindow.effectiveOverlayOpacity > 0.01
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor

                                    onPressed: function (mouse) {
                                        mouse.accepted = true;
                                    }

                                    onClicked: function (mouse) {
                                        mouse.accepted = true;
                                        if (popupActionWindow.popupActive && popupActionWindow.notificationId >= 0 && popupActionButton.actionId.length > 0) {
                                            var targetNotificationId = popupActionWindow.notificationId;
                                            var targetActionId = popupActionButton.actionId;
                                            var notificationService = Root.NotificationService;
                                            popupStack.beginNotificationExternalClose(targetNotificationId);
                                            notificationService.invokeAction(targetNotificationId, targetActionId);
                                        }
                                    }
                                }
                            }
                        }
                    }

                }
            }
        }
    }

    Instantiator {
        id: centerDismissWindowInstantiator
        model: shell.notificationCenterEnabled && shell.notificationsExternalDismissEnabled ? notificationCenter.dismissButtonModel : null

        delegate: PanelWindow {
            id: centerDismissWindow
            required property int notificationId
            required property int buttonX
            required property int buttonY
            required property int buttonSize
            required property real buttonOpacity
            readonly property int hoverOverlapTowardsCard: Math.max(0, shell.notificationsDismissHoverOverlapPx)
            readonly property bool centerActive: notificationCenter.isCenterNotificationOverlayActive(notificationId)
            readonly property int clampedButtonSize: Math.max(0, buttonSize)
            readonly property bool hasValidGeometry: notificationId >= 0 && clampedButtonSize > 0
            readonly property real effectiveButtonOpacity: centerActive && hasValidGeometry ? Math.max(0.0, Math.min(1.0, Number(buttonOpacity))) : 0.0
            property int _trackedNotificationId: -1

            function _clearTrackedDismissHover(notificationIdToClear) {
                if (notificationIdToClear >= 0) {
                    notificationCenter.setExternalDismissHovered(notificationIdToClear, false);
                }
            }

            visible: shell.notificationCenterEnabled && shell.notificationCenterOpen && shell.notificationsExternalDismissEnabled && centerActive && hasValidGeometry
            exclusionMode: ExclusionMode.Ignore
            anchors.top: true
            anchors.right: true
            margins.top: shell.notificationCenterTopMargin + buttonY - shell.notificationsDismissWindowBleed
            margins.right: shell.notificationCenterRightMargin + notificationCenter.width - (buttonX + clampedButtonSize + shell.notificationsDismissWindowBleed) - hoverOverlapTowardsCard
            screen: notificationCenterOverlayPanel.screen

            color: "transparent"
            surfaceFormat.opaque: false
            focusable: false
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell:notification-dismiss"

            implicitWidth: clampedButtonSize + (shell.notificationsDismissWindowBleed * 2) + hoverOverlapTowardsCard
            implicitHeight: clampedButtonSize + (shell.notificationsDismissWindowBleed * 2) + hoverOverlapTowardsCard

            onVisibleChanged: {
                if (!visible) {
                    _clearTrackedDismissHover(_trackedNotificationId);
                }
            }

            onNotificationIdChanged: {
                if (_trackedNotificationId === notificationId) {
                    return;
                }
                _clearTrackedDismissHover(_trackedNotificationId);
                _trackedNotificationId = notificationId;
            }

            Component.onCompleted: _trackedNotificationId = notificationId

            Component.onDestruction: _clearTrackedDismissHover(_trackedNotificationId)

            Item {
                anchors.fill: parent

                HoverHandler {
                    onHoveredChanged: {
                        if (!centerDismissWindow.centerActive || !centerDismissWindow.hasValidGeometry) {
                            notificationCenter.setExternalDismissHovered(centerDismissWindow.notificationId, false);
                            return;
                        }
                        notificationCenter.setExternalDismissHovered(centerDismissWindow.notificationId, hovered);
                    }
                }

                Rectangle {
                    id: centerDismissButton
                    x: shell.notificationsDismissWindowBleed
                    y: shell.notificationsDismissWindowBleed
                    width: centerDismissWindow.clampedButtonSize
                    height: centerDismissWindow.clampedButtonSize
                    radius: Math.round(height / 2)
                    opacity: centerDismissWindow.effectiveButtonOpacity
                    Behavior on opacity {
                        NumberAnimation {
                            duration: centerDismissWindow.effectiveButtonOpacity > centerDismissButton.opacity ? shell.notificationsControlFadeInMs : shell.notificationsControlFadeOutMs
                            easing.type: Easing.OutCubic
                        }
                    }
                    color: centerDismissMouseArea.containsMouse ? shell.notificationsControlHoverTintColor : shell.notificationsControlTintColor
                    border.width: 1
                    border.color: shell.notificationsControlBorderColor

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: centerDismissMouseArea.containsMouse ? Qt.rgba(Root.Theme.menuHighlight.r, Root.Theme.menuHighlight.g, Root.Theme.menuHighlight.b, 0.16) : "transparent"
                    }

                    ShaderEffect {
                        anchors.fill: parent
                        property vector2d uSize: Qt.vector2d(width, height)
                        property real uRadius: centerDismissButton.radius
                        property real uLightAngleDeg: 330
                        property real uLightStrength: 5.1
                        property real uLightWidthPx: 4.2
                        property real uLightSharpness: 0.28
                        property real uCornerBoost: 0.45
                        property real uEdgeOpacity: 0.72
                        property color uEdgeTint: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.92)
                        fragmentShader: "shaders/notification_edge_light.frag.qsb"
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "􀅾"
                        color: Root.Theme.textSecondary
                        font.family: Root.Theme.fontFamilyDisplay
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: centerDismissMouseArea
                        anchors.fill: parent
                        enabled: centerDismissWindow.effectiveButtonOpacity > 0.01
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        preventStealing: true
                        cursorShape: Qt.PointingHandCursor

                        onPressed: function (mouse) {
                            mouse.accepted = true;
                        }

                        onClicked: function (mouse) {
                            mouse.accepted = true;
                            if (centerDismissWindow.centerActive && centerDismissWindow.notificationId >= 0) {
                                var targetNotificationId = centerDismissWindow.notificationId;
                                var notificationService = Root.NotificationService;
                                notificationCenter.clearExternalState(targetNotificationId);
                                notificationService.removeFromHistory(targetNotificationId);
                            }
                        }
                    }
                }
            }
        }
    }

    Instantiator {
        id: centerActionWindowInstantiator
        model: shell.notificationCenterEnabled && shell.notificationsExternalPopupActionsEnabled ? notificationCenter.actionOverlayModel : null

        delegate: PanelWindow {
            id: centerActionWindow
            required property int notificationId
            required property int overlayX
            required property int overlayY
            required property int overlayWidth
            required property int overlayHeight
            required property real overlayOpacity
            required property int actionsCount
            required property string actionsJson
            readonly property var resolvedActionsData: _decodedActions(actionsJson)
            readonly property int hoverOverlapTowardsCard: Math.max(0, shell.notificationsActionHoverOverlapPx)
            readonly property bool centerActive: notificationCenter.isCenterNotificationOverlayActive(notificationId)
            readonly property bool hasValidGeometry: notificationId >= 0 && overlayWidth > 0 && overlayHeight > 0
            readonly property bool hasRenderableActions: actionsCount > 0 && resolvedActionsData.length > 0
            readonly property real effectiveOverlayOpacity: centerActive && hasValidGeometry && hasRenderableActions ? Math.max(0.0, Math.min(1.0, Number(overlayOpacity))) : 0.0
            readonly property bool effectiveOverlayInputEnabled: hasValidGeometry && hasRenderableActions && (effectiveOverlayOpacity > 0.01 || _actionPressInProgress)
            property int _trackedNotificationId: -1
            property bool _actionPressInProgress: false

            function _clearTrackedActionHover(notificationIdToClear) {
                if (notificationIdToClear >= 0) {
                    notificationCenter.setExternalPopupActionsHovered(notificationIdToClear, false);
                }
            }

            function _decodedActions(jsonText) {
                if (!jsonText || jsonText.length === 0) {
                    return [];
                }
                try {
                    var parsed = JSON.parse(jsonText);
                    return parsed && parsed.length !== undefined ? parsed : [];
                } catch (err) {
                    return [];
                }
            }

            visible: shell.notificationCenterEnabled && shell.notificationCenterOpen && shell.notificationsExternalPopupActionsEnabled && hasValidGeometry && hasRenderableActions
            exclusionMode: ExclusionMode.Ignore
            anchors.top: true
            anchors.right: true
            margins.top: shell.notificationCenterTopMargin + overlayY - shell.notificationsActionWindowBleed
            margins.right: shell.notificationCenterRightMargin + notificationCenter.width - (overlayX + overlayWidth + shell.notificationsActionWindowBleed)
            screen: notificationCenterOverlayPanel.screen

            color: "transparent"
            surfaceFormat.opaque: false
            focusable: false
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.namespace: "quickshell:notification-actions"

            implicitWidth: Math.max(0, overlayWidth) + (shell.notificationsActionWindowBleed * 2) + hoverOverlapTowardsCard
            implicitHeight: Math.max(0, overlayHeight) + (shell.notificationsActionWindowBleed * 2)

            onVisibleChanged: {
                if (!visible) {
                    _actionPressInProgress = false;
                    _clearTrackedActionHover(_trackedNotificationId);
                }
            }

            onNotificationIdChanged: {
                if (_trackedNotificationId === notificationId) {
                    return;
                }
                _clearTrackedActionHover(_trackedNotificationId);
                _trackedNotificationId = notificationId;
            }

            Component.onCompleted: _trackedNotificationId = notificationId

            Component.onDestruction: _clearTrackedActionHover(_trackedNotificationId)

            Item {
                anchors.fill: parent

                HoverHandler {
                    onHoveredChanged: {
                        if (!centerActionWindow.centerActive || !centerActionWindow.hasValidGeometry || !centerActionWindow.hasRenderableActions) {
                            notificationCenter.setExternalPopupActionsHovered(centerActionWindow.notificationId, false);
                            return;
                        }
                        notificationCenter.setExternalPopupActionsHovered(centerActionWindow.notificationId, hovered);
                    }
                }

                Item {
                    id: centerActionSurface
                    x: shell.notificationsActionWindowBleed + centerActionWindow.hoverOverlapTowardsCard
                    y: shell.notificationsActionWindowBleed
                    width: centerActionWindow.overlayWidth
                    height: centerActionWindow.overlayHeight
                    opacity: centerActionWindow.effectiveOverlayOpacity
                    Behavior on opacity {
                        NumberAnimation {
                            duration: centerActionWindow.effectiveOverlayOpacity > centerActionSurface.opacity ? shell.notificationsControlFadeInMs : shell.notificationsControlFadeOutMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    Row {
                        id: centerActionRow
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Repeater {
                            model: centerActionWindow.resolvedActionsData

                            Rectangle {
                                id: centerActionButton
                                required property var modelData
                                readonly property string actionId: modelData && modelData.id !== undefined ? String(modelData.id) : ""
                                readonly property string actionText: modelData && modelData.text !== undefined ? String(modelData.text) : ""

                                visible: actionText.length > 0
                                implicitHeight: 24
                                implicitWidth: Math.min(150, Math.max(70, centerActionLabel.implicitWidth + 16))
                                radius: 8
                                color: centerActionMouseArea.containsMouse ? shell.notificationsControlHoverTintColor : shell.notificationsControlTintColor
                                border.width: 1
                                border.color: shell.notificationsControlBorderColor

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: centerActionMouseArea.containsMouse ? Qt.rgba(Root.Theme.menuHighlight.r, Root.Theme.menuHighlight.g, Root.Theme.menuHighlight.b, 0.22) : "transparent"
                                }

                                ShaderEffect {
                                    anchors.fill: parent
                                    property vector2d uSize: Qt.vector2d(width, height)
                                    property real uRadius: centerActionButton.radius
                                    property real uLightAngleDeg: 330
                                    property real uLightStrength: 5.1
                                    property real uLightWidthPx: 3.5
                                    property real uLightSharpness: 0.28
                                    property real uCornerBoost: 0.45
                                    property real uEdgeOpacity: 0.72
                                    property color uEdgeTint: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.92)
                                    fragmentShader: "shaders/notification_edge_light.frag.qsb"
                                }

                                Text {
                                    id: centerActionLabel
                                    anchors.centerIn: parent
                                    text: centerActionButton.actionText
                                    color: Root.Theme.textPrimary
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    renderType: Text.NativeRendering
                                }

                                MouseArea {
                                    id: centerActionMouseArea
                                    anchors.fill: parent
                                    propagateComposedEvents: false
                                    enabled: centerActionWindow.effectiveOverlayInputEnabled
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor

                                    onPressed: function (mouse) {
                                        mouse.accepted = true;
                                        centerActionWindow._actionPressInProgress = true;
                                    }

                                    onReleased: function (mouse) {
                                        mouse.accepted = true;
                                    }

                                    onCanceled: centerActionWindow._actionPressInProgress = false

                                    onClicked: function (mouse) {
                                        mouse.accepted = true;
                                        var targetNotificationId = centerActionWindow.notificationId;
                                        var targetActionId = centerActionButton.actionId;
                                        console.log("[NotificationCenter][DEBUG] center action clicked notificationId=" + targetNotificationId + " actionId=" + targetActionId);
                                        centerActionWindow._actionPressInProgress = false;
                                        if (targetNotificationId >= 0 && targetActionId.length > 0) {
                                            var notificationService = Root.NotificationService;
                                            notificationService.invokeAction(targetNotificationId, targetActionId);
                                            notificationService.removeFromHistory(targetNotificationId);
                                            console.log("[NotificationCenter][DEBUG] removed from history id=" + targetNotificationId + " after action " + targetActionId);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: notificationCenterOverlayPanel
        visible: shell.notificationCenterEnabled && (shell.notificationCenterOpen || notificationCenter.opacity > 0.01)

        anchors.top: true
        anchors.left: true
        anchors.right: true
        anchors.bottom: true
        exclusionMode: ExclusionMode.Ignore

        color: "transparent"
        surfaceFormat.opaque: false
        focusable: false
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:notification-center"

        MouseArea {
            id: notificationCenterBackdropMouseArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            preventStealing: true
            function _insideNotificationCenterInteraction(mouseX, mouseY) {
                var panelPos = notificationCenter.mapToItem(notificationCenterBackdropMouseArea, 0, 0);
                var interactionBleed = Math.max(
                    shell.notificationsActionWindowBleed + Math.max(0, shell.notificationsActionHoverOverlapPx),
                    shell.notificationsDismissWindowBleed + Math.max(0, shell.notificationsDismissHoverOverlapPx)
                );
                return mouseX >= (panelPos.x - interactionBleed) && mouseX <= (panelPos.x + notificationCenter.width + interactionBleed) && mouseY >= (panelPos.y - interactionBleed) && mouseY <= (panelPos.y + notificationCenter.height + interactionBleed);
            }

            onPressed: function (mouse) {
                if (_insideNotificationCenterInteraction(mouse.x, mouse.y)) {
                    mouse.accepted = false;
                    return;
                }
                mouse.accepted = true;
            }

            onClicked: function (mouse) {
                if (_insideNotificationCenterInteraction(mouse.x, mouse.y)) {
                    mouse.accepted = false;
                    return;
                }
                mouse.accepted = true;
                shell.notificationCenterOpen = false;
            }
        }

        Notifications.NotificationCenter {
            id: notificationCenter
            z: 1
            width: implicitWidth
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.topMargin: shell.notificationCenterTopMargin
            anchors.bottomMargin: 0
            anchors.rightMargin: shell.notificationCenterRightMargin
            open: shell.notificationCenterOpen
            externalDismissEnabled: shell.notificationsExternalDismissEnabled
            externalPopupActionsEnabled: shell.notificationsExternalPopupActionsEnabled
            onRequestClose: shell.notificationCenterOpen = false
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barPanelWindow
            WlrLayershell.namespace: "qsbar"
            required property var modelData
            screen: barPanelWindow.modelData
            property bool notificationCenterOpenProxy: shell.notificationCenterOpen
            property var notificationCenterTriggerItemProxy: shell.notificationCenterTriggerItem
            function toggleNotificationCenterForBar(triggerItem) {
                shell.toggleNotificationCenter(triggerItem);
            }

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 72
            color: "transparent"

            exclusiveZone: 36

            mask: Region {
                item: barHitbox
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 72
                color: "transparent"

                gradient: Gradient {
                    GradientStop {
                        position: 0.00
                        color: Theme.isDark ? Qt.rgba(0, 0, 0, 0.18) : Qt.rgba(1, 1, 1, 0.12)
                    }
                    GradientStop {
                        position: 0.25
                        color: Theme.isDark ? Qt.rgba(0, 0, 0, 0.10) : Qt.rgba(1, 1, 1, 0.07)
                    }
                    GradientStop {
                        position: 0.60
                        color: Theme.isDark ? Qt.rgba(0, 0, 0, 0.04) : Qt.rgba(1, 1, 1, 0.01)
                    }
                    GradientStop {
                        position: 1.00
                        color: "transparent"
                    }
                }
            }

            Item {
                id: barHitbox
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 36

                Rectangle {
                    anchors.fill: parent
                    color: Theme.background

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        spacing: 0

                        Item {
                            id: leftSection
                            height: parent.height
                            width: leftRow.implicitWidth

                            QtObject {
                                id: leftHi
                                property Item activeTarget: null
                                property Item pulseTarget: null
                                property bool pressed: false
                            }

                            Rectangle {
                                id: leftPill
                                z: 0
                                radius: Theme.borderRadius

                                property Item target: leftHi.activeTarget ?? leftHi.pulseTarget

                                x: target ? target.mapToItem(leftSection, 0, 0).x - Theme.hoverOverlap : 0
                                y: 0
                                width: target ? target.width + (Theme.hoverOverlap * 2) : 0
                                height: parent.height

                                color: leftHi.activeTarget ? Qt.rgba(1, 1, 1, 0.10) : (leftHi.pulseTarget ? Qt.rgba(Theme.menuHighlight.r, Theme.menuHighlight.g, Theme.menuHighlight.b, 0.70) : "transparent")

                                opacity: target ? 1 : 0
                            }

                            Row {
                                id: leftRow
                                z: 1
                                spacing: 0
                                height: parent.height

                                // Apple logo (remove per-item hover bg; let leftPill handle it)
                                Rectangle {
                                    id: logoRect
                                    width: 35
                                    height: parent.height
                                    color: "transparent"
                                    radius: Theme.borderRadius

                                    Text {
                                        id: logoText
                                        anchors.centerIn: parent
                                        text: "􀆿"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.iconSize
                                        renderType: Text.NativeRendering
                                        color: Theme.textPrimary
                                    }

                                    DropShadow {
                                        anchors.fill: logoText
                                        source: logoText
                                        visible: Theme.isDark
                                        horizontalOffset: Theme.shadowHorizontalOffset
                                        verticalOffset: Theme.shadowVerticalOffset
                                        radius: Theme.shadowRadius
                                        samples: 16
                                        spread: 0
                                        color: Theme.shadowColor
                                    }

                                    MouseArea {
                                        id: logoMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onPressed: leftHi.pressed = true
                                        onReleased: leftHi.pressed = false

                                        onClicked: logoMenu.toggle()
                                    }
                                }

                                // Workspace windows (pass the state object down)
                                WorkspaceWindows {
                                    height: parent.height
                                    screen: modelData
                                    highlightState: leftHi
                                }
                            }
                        }

                        // Logo Menu - positioned as a popup window
                        Menu.MenuPopup {
                            id: logoMenu
                            anchorItem: logoRect
                            yOffset: 8

                            model: [
                                {
                                    type: "action",
                                    icon: "􀙗",
                                    label: "About This Mac"
                                },
                                {
                                    type: "separator"
                                },
                                {
                                    type: "action",
                                    icon: "􀈎",
                                    label: "System Settings...",
                                    shortcut: ["􀆔", ","]
                                },
                                {
                                    type: "action",
                                    icon: "􁣡",
                                    label: "App Store..."
                                },
                                {
                                    type: "separator"
                                },
                                {
                                    type: "action",
                                    label: "Applications",
                                    submenu: [
                                        {
                                            type: "action",
                                            label: "Finder"
                                        },
                                        {
                                            type: "action",
                                            label: "Safari"
                                        },
                                        {
                                            type: "action",
                                            label: "Terminal"
                                        }
                                    ]
                                },
                                {
                                    type: "action",
                                    label: "Documents",
                                    submenu: [
                                        {
                                            type: "action",
                                            label: "Downloads"
                                        },
                                        {
                                            type: "action",
                                            label: "Pictures"
                                        },
                                        {
                                            type: "action",
                                            label: "Music"
                                        }
                                    ]
                                },
                                {
                                    type: "separator"
                                },
                                {
                                    type: "action",
                                    icon: "􀜗",
                                    label: "Force Quit...",
                                    shortcut: ["􀆕", "􀆔", "Q"]
                                },
                                {
                                    type: "separator"
                                },
                                {
                                    type: "action",
                                    icon: "􀎥",
                                    label: "Sleep"
                                },
                                {
                                    type: "action",
                                    icon: "􀆨",
                                    label: "Restart..."
                                },
                                {
                                    type: "action",
                                    icon: "􀷃",
                                    label: "Shut Down..."
                                },
                                {
                                    type: "separator"
                                },
                                {
                                    type: "action",
                                    icon: "􀙧",
                                    label: "Lock Screen",
                                    shortcut: ["􀆔", "Q"]
                                },
                                {
                                    type: "action",
                                    icon: "􀉩",
                                    label: "Log Out",
                                    shortcut: ["􀆝", "􀆔", "Q"]
                                }
                            ]

                            onItemClicked: function (item, index) {
                                console.log("Menu item clicked:", item.label);
                            }
                        }
                        Connections {
                            target: logoMenu
                            function onVisibleChanged() {
                                leftHi.activeTarget = logoMenu.visible ? logoRect : null;
                            }
                        }

                        // Spacer to push right section to the end
                        Item {
                            width: parent.width - leftSection.width - rightSection.width
                            height: parent.height
                        }

                        // Right section - System controls
                        Item {
                            id: rightSection
                            height: parent.height
                            width: rightRow.implicitWidth
                            function syncNotificationCenterHighlight() {
                                var shouldHighlight = barPanelWindow.notificationCenterOpenProxy && barPanelWindow.notificationCenterTriggerItemProxy === timeDisplay;
                                if (shouldHighlight) {
                                    rightHi.activeTarget = timeDisplay;
                                } else if (rightHi.activeTarget === timeDisplay) {
                                    rightHi.activeTarget = null;
                                }
                            }
                            Component.onCompleted: syncNotificationCenterHighlight()
                            Component.onDestruction: {
                                if (rightHi.activeTarget === timeDisplay) {
                                    rightHi.activeTarget = null;
                                }
                            }

                            QtObject {
                                id: rightHi
                                property Item activeTarget: null
                                property Item pulseTarget: null
                            }

                            Connections {
                                target: barPanelWindow
                                function onNotificationCenterOpenProxyChanged() {
                                    rightSection.syncNotificationCenterHighlight();
                                }
                                function onNotificationCenterTriggerItemProxyChanged() {
                                    rightSection.syncNotificationCenterHighlight();
                                }
                            }

                            Rectangle {
                                id: rightPill
                                z: 0
                                radius: Theme.borderRadius

                                property Item target: rightHi.activeTarget ?? rightHi.pulseTarget

                                x: target ? target.mapToItem(rightSection, 0, 0).x - Theme.hoverOverlap : 0
                                y: 0
                                width: target ? target.width + (Theme.hoverOverlap * 2) : 0
                                height: parent.height

                                color: rightHi.activeTarget ? Qt.rgba(1, 1, 1, 0.10) : (rightHi.pulseTarget ? Qt.rgba(Theme.menuHighlight.r, Theme.menuHighlight.g, Theme.menuHighlight.b, 0.70) : "transparent")

                                opacity: target ? 1 : 0
                            }

                            Row {
                                id: rightRow
                                z: 1
                                spacing: 0
                                height: parent.height

                                Widgets.SystemTrayArea {
                                    height: parent.height
                                    highlightState: rightHi
                                    iconSize: Theme.iconSize
                                }

                                // IconButton { icon: "􀙇"; highlightState: rightHi; onClicked: {} }
                                // IconButton { icon: "􀊫"; highlightState: rightHi; onClicked: {} }
                                IconButton {
                                    icon: "􀜊"
                                    highlightState: rightHi
                                    onClicked: {}
                                }

                                TimeDisplay {
                                    id: timeDisplay
                                    height: parent.height
                                    highlightState: rightHi
                                    onClicked: barPanelWindow.toggleNotificationCenterForBar(timeDisplay)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
