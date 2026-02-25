pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import "../.." as Root

FocusScope {
    id: root

    property int notificationId: -1
    property string appName: ""
    property var appIcon: ""
    property string appIconHint: ""
    property var resolvedAppIconSource: undefined
    property string resolvedAppIconHint: ""
    property string summary: ""
    property string body: ""
    property var image: ""
    property string imageHint: ""
    property string rightSideImageSource: ""
    property string contentPreviewImageSource: ""
    property var hints: ({})
    property string timeLabel: ""
    property var actions: []
    property int maxActionButtons: 2
    property bool keyboardInteractive: false
    property bool clickActivatesDefault: true
    property bool showDismissButton: true
    property bool showTimeLabel: true
    property bool showActions: true
    // "dismiss" (active popup semantics) | "removeHistory" (history list semantics)
    property string dismissMode: "dismiss"

    // Shared interaction model across popup and center usages.
    property string interactionMode: "popup" // "popup" | "center"
    property bool draggableDismiss: interactionMode === "popup"
    property bool expandable: interactionMode === "center"
    property bool expanded: false
    readonly property bool hovered: hoverTracker.hovered
    readonly property bool pressed: cardMouseArea.pressed && !dragInProgress
    property bool showActionsWhenExpanded: interactionMode === "center"
    property bool pauseTimeoutOnHover: interactionMode === "popup"
    property bool externalHoverHold: false
    property bool revealDismissOnHover: interactionMode === "popup"

    property real dismissThresholdPx: Math.max(96, width * 0.30)
    property real dragStartThresholdPx: 8

    signal requestExpandToggle

    readonly property var notificationService: Root.NotificationService
    readonly property int cardPadding: 10
    readonly property real cardRadius: 14
    property bool edgeLightEnabled: isPopupMode
    property real edgeLightStrength: 2
    property real edgeLightAngleDeg: 330
    property real edgeLightWidthPx: 4.0
    property real edgeLightSharpness: 0.1
    property real edgeLightOpacity: 1.0
    property bool buttonEdgeLightEnabled: true
    property real buttonEdgeLightStrength: Math.max(0.2, edgeLightStrength * 0.55)
    property real buttonEdgeLightWidthPx: Math.max(2.0, edgeLightWidthPx * 0.85)
    property real buttonEdgeLightSharpness: Math.min(1.0, edgeLightSharpness + 0.18)
    property real buttonEdgeLightOpacity: Math.min(1.0, edgeLightOpacity * 0.72)
    property real buttonTintOpacity: isPopupMode ? (Root.Theme.isDark ? 0.24 : 0.30) : (Root.Theme.isDark ? 0.22 : 0.24)
    property real cardTintOpacity: isPopupMode ? (Root.Theme.isDark ? 0.46 : 0.54) : 0.96
    readonly property color buttonTintColor: Root.Theme.isDark ? Qt.rgba(1, 1, 1, buttonTintOpacity) : Qt.rgba(0.98, 0.99, 1.0, buttonTintOpacity)
    readonly property color buttonHoverTintColor: Root.Theme.isDark ? Qt.rgba(1, 1, 1, buttonTintOpacity + 0.06) : Qt.rgba(1, 1, 1, buttonTintOpacity + 0.14)
    readonly property color buttonHairlineColor: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.58)
    readonly property color cardTintColor: Root.Theme.isDark ? Qt.rgba(0.10, 0.11, 0.13, cardTintOpacity) : Qt.rgba(0.97, 0.98, 0.99, cardTintOpacity)
    readonly property color cardContrastColor: Root.Theme.isDark ? Qt.rgba(1, 1, 1, isPopupMode ? 0.030 : 0.0) : Qt.rgba(1, 1, 1, isPopupMode ? 0.16 : 0.0)
    readonly property color cardHairlineColor: Root.Theme.isDark ? Qt.rgba(1, 1, 1, isPopupMode ? 0.07 : 0.05) : Qt.rgba(1, 1, 1, isPopupMode ? 0.52 : 0.70)
    readonly property bool hasBody: _trimmed(body).length > 0
    readonly property int actionButtonCount: Math.min(maxActionButtons, _safeLength(actions))
    readonly property string effectiveTitle: _trimmed(summary).length > 0 ? _trimmed(summary) : (_trimmed(appName).length > 0 ? _trimmed(appName) : "Notification")
    readonly property string fallbackIconText: _fallbackLabel()
    readonly property bool actionsVisible: showActions && actionButtonCount > 0 && (!showActionsWhenExpanded || expanded)
    readonly property var effectiveAppIconSource: _hasMediaValue(resolvedAppIconSource) ? resolvedAppIconSource : appIcon
    readonly property string effectiveAppIconHint: _trimmed(resolvedAppIconHint).length > 0 ? _trimmed(resolvedAppIconHint) : (_trimmed(appIconHint).length > 0 ? _trimmed(appIconHint) : _mediaHint(effectiveAppIconSource))
    readonly property bool iconUsesRasterImage: _looksLikePathOrUrl(effectiveAppIconHint)
    readonly property string iconRasterSource: iconUsesRasterImage ? _toRenderableSource(effectiveAppIconHint) : ""
    readonly property bool iconHasSource: iconUsesRasterImage ? iconRasterSource.length > 0 : _hasMediaValue(effectiveAppIconSource)
    readonly property string rightImageSource: _toRenderableSource(_trimmed(rightSideImageSource))
    readonly property bool hasRightImage: rightImageSource.length > 0
    // Preview slot binds strictly to the service-classified preview role.
    // Do not fallback to raw image/app icon/right-side image here, otherwise icon-only
    // notifications incorrectly render a large preview.
    readonly property string previewImageSource: _toRenderableSource(_trimmed(contentPreviewImageSource))
    readonly property bool hasPreviewImage: previewImageSource.length > 0
    readonly property bool isPopupMode: interactionMode === "popup"
    readonly property bool isCenterMode: interactionMode === "center"
    readonly property int popupDismissSize: 22
    readonly property int popupAvatarSize: 32
    readonly property int popupRailWidth: 32
    readonly property int popupOverlayInset: 5
    readonly property int popupRightRailReservedWidth: hasRightImage ? popupRailWidth : 0
    readonly property int popupRightRailReservedSpacing: hasRightImage ? popupMainRow.spacing : 0
    property int popupActionsBottomGap: 0
    readonly property bool popupActionsOverlayEligible: isPopupMode && actionsVisible
    readonly property bool popupActionsOverlayShown: popupActionsOverlayEligible && !dragInProgress && (hovered || popupActionsOverlayHover.hovered || popupActionsOverlayMouseArea.containsMouse || _popupActionsOverlayPressed)
    readonly property bool popupTimeoutHold: pauseTimeoutOnHover && (hovered || externalHoverHold || dragInProgress || popupActionsOverlayHover.hovered || popupActionsOverlayMouseArea.containsMouse || _popupActionsOverlayPressed)
    readonly property real dragProgress: Math.min(1, Math.abs(dragOffsetX) / Math.max(1, dismissThresholdPx))
    readonly property real dragOpacity: draggableDismiss ? (1 - (dragProgress * 0.24)) : 1

    property real dragOffsetX: 0
    property bool dragInProgress: false
    property bool _popupActionsOverlayPressed: false
    property real _pressX: 0
    property real _pressY: 0
    property bool _pointerPressed: false
    property bool _suppressNextDefaultActivation: false
    property int _timeoutPauseId: -1

    implicitWidth: 352
    implicitHeight: contentColumn.implicitHeight + (cardPadding * 2)
    activeFocusOnTab: keyboardInteractive

    Keys.onReturnPressed: if (keyboardInteractive)
        activateDefault()
    Keys.onEnterPressed: if (keyboardInteractive)
        activateDefault()
    Keys.onSpacePressed: if (keyboardInteractive)
        activateDefault()
    Keys.onEscapePressed: if (keyboardInteractive)
        dismiss()

    onNotificationIdChanged: {
        resetVisualState();
        _syncTimeoutPauseRegistration();
    }
    onPauseTimeoutOnHoverChanged: _syncTimeoutPauseRegistration()
    onPopupTimeoutHoldChanged: _updateTimeoutPauseState()

    Component.onCompleted: {
        resetVisualState();
        _syncTimeoutPauseRegistration();
    }
    Component.onDestruction: _releaseTimeoutPause()

    Behavior on dragOffsetX {
        enabled: !root.dragInProgress
        NumberAnimation {
            duration: 170
            easing.type: Easing.OutCubic
        }
    }

    function _trimmed(value) {
        if (value === undefined || value === null) {
            return "";
        }
        return String(value).trim();
    }

    function _safeLength(value) {
        if (!value || value.length === undefined || value.length === null) {
            return 0;
        }
        var length = Number(value.length);
        if (!isFinite(length) || length < 0) {
            return 0;
        }
        return Math.floor(length);
    }

    function _fallbackLabel() {
        var name = _trimmed(appName);
        if (name.length === 0) {
            name = _trimmed(summary);
        }
        if (name.length === 0) {
            return "N";
        }
        return name.charAt(0).toUpperCase();
    }

    function _safeAction(index) {
        if (!actions || index < 0 || index >= _safeLength(actions)) {
            return null;
        }
        return actions[index];
    }

    function _actionId(action) {
        if (!action || action.id === undefined || action.id === null) {
            return "";
        }
        return String(action.id);
    }

    function _actionText(action) {
        if (!action || action.text === undefined || action.text === null) {
            return "";
        }
        return String(action.text);
    }

    function _hasMediaValue(value) {
        if (value === undefined || value === null) {
            return false;
        }
        if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
            return _trimmed(value).length > 0;
        }
        return true;
    }

    function _mediaHint(value) {
        if (value === undefined || value === null) {
            return "";
        }

        if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
            return _trimmed(value);
        }

        if (typeof value === "object") {
            var keys = ["source", "path", "url", "name", "icon", "iconName"];
            var i = 0;
            for (i = 0; i < keys.length; i++) {
                var key = keys[i];
                if (!Object.prototype.hasOwnProperty.call(value, key)) {
                    continue;
                }

                var candidate = _trimmed(value[key]);
                if (candidate.length > 0) {
                    return candidate;
                }
            }
        }

        var fallback = _trimmed(value);
        return fallback === "[object Object]" ? "" : fallback;
    }

    function _looksLikePathOrUrl(value) {
        var text = _trimmed(value);
        if (text.length === 0) {
            return false;
        }

        if (text.indexOf("/") === 0 || text.indexOf("file://") === 0 || text.indexOf("qrc:/") === 0 || text.indexOf(":/") === 0) {
            return true;
        }

        return /^[A-Za-z][A-Za-z0-9+.-]*:/.test(text);
    }

    function _toRenderableSource(value) {
        var text = _trimmed(value);
        if (text.length === 0) {
            return "";
        }
        if (text.indexOf("/") === 0) {
            return "file://" + text;
        }
        return text;
    }

    function _supportsTimeoutPause() {
        return !!notificationService && notificationService.setPopupTimeoutPaused !== undefined;
    }

    function _releaseTimeoutPause() {
        if (_timeoutPauseId < 0) {
            return;
        }

        if (_supportsTimeoutPause()) {
            notificationService.setPopupTimeoutPaused(_timeoutPauseId, false);
        }

        _timeoutPauseId = -1;
    }

    function _syncTimeoutPauseRegistration() {
        if (!pauseTimeoutOnHover || notificationId < 0) {
            _releaseTimeoutPause();
            return;
        }

        if (_timeoutPauseId >= 0 && _timeoutPauseId !== notificationId && _supportsTimeoutPause()) {
            notificationService.setPopupTimeoutPaused(_timeoutPauseId, false);
        }

        _timeoutPauseId = notificationId;
        _updateTimeoutPauseState();
    }

    function _updateTimeoutPauseState() {
        if (_timeoutPauseId < 0 || !_supportsTimeoutPause()) {
            return;
        }

        notificationService.setPopupTimeoutPaused(_timeoutPauseId, popupTimeoutHold);
    }

    function resetVisualState() {
        // Reset transform/opacity/drag state to avoid recycled delegate visual leakage in popup bursts.
        x = 0;
        opacity = 1;
        scale = 1;
        dragInProgress = false;
        dragOffsetX = 0;
        _popupActionsOverlayPressed = false;
        _suppressNextDefaultActivation = false;
        _resetPointerState();
    }

    function _resetPointerState() {
        _pointerPressed = false;
        _pressX = 0;
        _pressY = 0;
    }

    function _handlePointerPress(mouse) {
        _pointerPressed = true;
        _pressX = mouse.x;
        _pressY = mouse.y;
    }

    function _handlePointerMove(mouse) {
        if (!_pointerPressed || !draggableDismiss) {
            return;
        }

        var deltaX = mouse.x - _pressX;
        var deltaY = mouse.y - _pressY;

        if (!dragInProgress) {
            var movedFarEnough = Math.abs(deltaX) >= dragStartThresholdPx;
            var horizontalDominant = Math.abs(deltaX) > Math.abs(deltaY);
            if (!movedFarEnough || !horizontalDominant) {
                return;
            }
            dragInProgress = true;
        }

        dragOffsetX = deltaX;
    }

    function _handlePointerRelease() {
        _resetPointerState();

        if (!dragInProgress) {
            if (_suppressNextDefaultActivation) {
                _suppressNextDefaultActivation = false;
                return;
            }

            if (keyboardInteractive) {
                forceActiveFocus();
            }
            if (clickActivatesDefault) {
                activateDefault();
            }
            return;
        }

        var shouldDismiss = Math.abs(dragOffsetX) >= dismissThresholdPx;
        dragInProgress = false;

        if (shouldDismiss) {
            dismiss();
            return;
        }

        dragOffsetX = 0;
    }

    function _handlePointerCancel() {
        _resetPointerState();
        _popupActionsOverlayPressed = false;
        _suppressNextDefaultActivation = false;

        if (dragInProgress) {
            dragInProgress = false;
            dragOffsetX = 0;
        }
    }

    function _consumeCardReleaseActivation() {
        _suppressNextDefaultActivation = true;
    }

    function activateDefault() {
        if (notificationId < 0) {
            return;
        }
        notificationService.defaultActivate(notificationId);
    }

    function dismiss() {
        if (notificationId < 0) {
            return;
        }

        if (dismissMode === "removeHistory") {
            notificationService.removeFromHistory(notificationId);
            return;
        }

        notificationService.dismissNotification(notificationId);
    }

    function invokeAction(actionId) {
        if (notificationId < 0 || _trimmed(actionId).length === 0) {
            return;
        }
        notificationService.invokeAction(notificationId, actionId);
    }

    Item {
        id: cardSurface
        anchors.fill: parent
        x: root.dragOffsetX
        opacity: root.dragOpacity

        Rectangle {
            anchors.fill: parent
            radius: root.cardRadius
            color: root.cardTintColor
        }

        Rectangle {
            anchors.fill: parent
            radius: root.cardRadius
            color: root.cardContrastColor
        }

        Rectangle {
            anchors.fill: parent
            radius: root.cardRadius
            color: "transparent"
            border.width: 1
            border.color: root.cardHairlineColor
        }

        ShaderEffect {
            id: edgeLightOverlay
            anchors.fill: parent
            visible: root.isPopupMode && root.edgeLightEnabled
            property vector2d uSize: Qt.vector2d(width, height)
            property real uRadius: root.cardRadius
            property real uLightAngleDeg: root.edgeLightAngleDeg
            property real uLightStrength: root.edgeLightStrength
            property real uLightWidthPx: root.edgeLightWidthPx
            property real uLightSharpness: root.edgeLightSharpness
            property real uCornerBoost: 0.5
            property real uEdgeOpacity: root.edgeLightOpacity
            property color uEdgeTint: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.98) : Qt.rgba(1, 1, 1, 0.90)
            fragmentShader: "../../shaders/notification_edge_light.frag.qsb"
        }

        MouseArea {
            id: cardMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            cursorShape: Qt.PointingHandCursor

            onPressed: function (mouse) {
                mouse.accepted = true;
                root._handlePointerPress(mouse);
            }

            onPositionChanged: function (mouse) {
                root._handlePointerMove(mouse);
            }

            onReleased: function (mouse) {
                mouse.accepted = true;
                root._handlePointerRelease();
            }

            onCanceled: root._handlePointerCancel()
        }

        Column {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: root.cardPadding
            spacing: 0

            Item {
                id: popupContentLayout
                width: parent.width
                visible: root.isPopupMode
                implicitHeight: popupMainRow.implicitHeight
                height: visible ? implicitHeight : 0

                Row {
                    id: popupMainRow
                    width: parent.width
                    spacing: 10

                    Item {
                        id: leftRail
                        width: root.popupRailWidth
                        height: popupTextColumn.implicitHeight

                        Rectangle {
                            id: popupIconSlot
                            anchors.centerIn: parent
                            width: root.popupRailWidth
                            height: root.popupRailWidth
                            radius: 8
                            color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.07)

                            Image {
                                id: popupAppIconRasterImage
                                anchors.fill: parent
                                anchors.margins: 5
                                source: root.iconRasterSource
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                visible: root.iconUsesRasterImage && status === Image.Ready
                            }

                            IconImage {
                                id: popupAppIconImage
                                anchors.fill: parent
                                anchors.margins: 5
                                source: root.iconUsesRasterImage ? "" : root.effectiveAppIconSource
                                visible: !root.iconUsesRasterImage && root.iconHasSource
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.fallbackIconText
                                visible: !popupAppIconRasterImage.visible && !popupAppIconImage.visible
                                font.family: Root.Theme.fontFamilyDisplay
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: Root.Theme.textPrimary
                                renderType: Text.NativeRendering
                            }
                        }
                    }

                    Column {
                        id: popupTextColumn
                        width: Math.max(0, popupMainRow.width - leftRail.width - root.popupRightRailReservedWidth - popupMainRow.spacing - root.popupRightRailReservedSpacing)
                        spacing: 8

                        Column {
                            width: parent.width
                            spacing: 2

                            Text {
                                width: parent.width
                                text: root.effectiveTitle
                                color: Root.Theme.textPrimary
                                font.family: Root.Theme.fontFamilyDisplay
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                wrapMode: Text.NoWrap
                                renderType: Text.NativeRendering
                            }

                            Text {
                                id: popupBodyText
                                width: parent.width
                                visible: root.hasBody
                                text: root._trimmed(root.body)
                                color: Root.Theme.textSecondary
                                opacity: 0.92
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                maximumLineCount: 4
                                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                renderType: Text.NativeRendering
                            }
                        }

                        Rectangle {
                            id: popupBodyImageFrame
                            width: parent.width
                            height: visible ? Math.round(Math.max(72, Math.min(176, width * 0.52))) : 0
                            radius: 10
                            clip: true
                            visible: root.hasPreviewImage
                            color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.04)
                            border.width: 1
                            border.color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.08)

                            Image {
                                id: popupBodyImage
                                anchors.fill: parent
                                source: root.previewImageSource
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: popupBodyImage.status === Image.Error
                                text: "Image unavailable"
                                color: Root.Theme.textSecondary
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 11
                                renderType: Text.NativeRendering
                            }
                        }
                    }

                    Item {
                        id: rightRail
                        visible: root.hasRightImage
                        width: visible ? root.popupRailWidth : 0
                        height: popupTextColumn.implicitHeight

                        Rectangle {
                            id: popupRightRailImageFrame
                            anchors.centerIn: parent
                            width: root.popupAvatarSize
                            height: root.popupAvatarSize
                            radius: 8
                            clip: true
                            visible: root.hasRightImage
                            opacity: root.hovered ? 0 : 1
                            color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.07)
                            border.width: 1
                            border.color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.10)

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 120
                                    easing.type: Easing.OutCubic
                                }
                            }

                            Image {
                                id: popupRightRailImage
                                anchors.fill: parent
                                source: popupRightRailImageFrame.visible ? root.rightImageSource : ""
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: popupRightRailImage.status === Image.Error
                                text: root.fallbackIconText
                                font.family: Root.Theme.fontFamilyDisplay
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: Root.Theme.textPrimary
                                renderType: Text.NativeRendering
                            }
                        }
                    }
                }
            }

            Item {
                id: centerContentLayout
                width: parent.width
                visible: root.isCenterMode
                implicitHeight: centerContentColumn.implicitHeight
                height: visible ? implicitHeight : 0

                Column {
                    id: centerContentColumn
                    width: parent.width
                    spacing: 8

                    Row {
                        id: headerRow
                        width: parent.width
                        spacing: 10

                        Rectangle {
                            id: iconSlot
                            width: 32
                            height: 32
                            radius: 8
                            color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.07)

                            Image {
                                id: appIconRasterImage
                                anchors.fill: parent
                                anchors.margins: 5
                                source: root.iconRasterSource
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                visible: root.iconUsesRasterImage && status === Image.Ready
                            }

                            IconImage {
                                id: appIconImage
                                anchors.fill: parent
                                anchors.margins: 5
                                source: root.iconUsesRasterImage ? "" : root.effectiveAppIconSource
                                visible: !root.iconUsesRasterImage && root.iconHasSource
                            }

                            Text {
                                anchors.centerIn: parent
                                text: root.fallbackIconText
                                visible: !appIconRasterImage.visible && !appIconImage.visible
                                font.family: Root.Theme.fontFamilyDisplay
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: Root.Theme.textPrimary
                                renderType: Text.NativeRendering
                            }
                        }

                        Column {
                            id: textColumn
                            width: Math.max(0, headerRow.width - iconSlot.width - (controlsColumn.visible ? controlsColumn.width : 0) - (headerRow.spacing * (controlsColumn.visible ? 2 : 1)))
                            spacing: 2

                            Text {
                                width: parent.width
                                text: root.effectiveTitle
                                color: Root.Theme.textPrimary
                                font.family: Root.Theme.fontFamilyDisplay
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                wrapMode: Text.NoWrap
                                renderType: Text.NativeRendering
                            }

                            Text {
                                id: bodyText
                                width: parent.width
                                visible: root.hasBody
                                text: root._trimmed(root.body)
                                color: Root.Theme.textSecondary
                                opacity: 0.92
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 12
                                elide: root.expandable && root.expanded ? Text.ElideNone : Text.ElideRight
                                maximumLineCount: root.expandable ? (root.expanded ? 8 : 2) : 2
                                wrapMode: root.expandable && root.expanded ? Text.WrapAnywhere : Text.WordWrap
                                renderType: Text.NativeRendering
                            }
                        }

                        Column {
                            id: controlsColumn
                            visible: root.isCenterMode
                            spacing: 4
                            width: visible ? Math.max(timeText.implicitWidth, (centerDismissButton.visible ? centerDismissButton.width : 0), (expandButton.visible ? expandButton.width : 0), (rightImageFrame.visible ? rightImageFrame.width : 0)) : 0

                            Text {
                                id: timeText
                                width: parent.width
                                text: root._trimmed(root.timeLabel)
                                visible: root.showTimeLabel && root._trimmed(root.timeLabel).length > 0
                                color: Root.Theme.textSecondary
                                opacity: 0.82
                                font.family: Root.Theme.fontFamily
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignRight
                                wrapMode: Text.NoWrap
                                renderType: Text.NativeRendering
                            }

                            Rectangle {
                                id: rightImageFrame
                                width: root.isCenterMode && root.hasRightImage ? 32 : 0
                                height: root.isCenterMode && root.hasRightImage ? 32 : 0
                                radius: 8
                                x: parent.width - width
                                clip: true
                                visible: root.isCenterMode && root.hasRightImage
                                color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.07)
                                border.width: 1
                                border.color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.10)

                                Image {
                                    id: rightImage
                                    anchors.fill: parent
                                    source: rightImageFrame.visible ? root.rightImageSource : ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    asynchronous: true
                                    visible: status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: rightImage.status === Image.Error
                                    text: root.fallbackIconText
                                    font.family: Root.Theme.fontFamilyDisplay
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: Root.Theme.textPrimary
                                    renderType: Text.NativeRendering
                                }
                            }

                            Rectangle {
                                id: expandButton
                                visible: root.expandable && (root.hasBody || root.actionButtonCount > 0)
                                width: 20
                                height: 20
                                radius: 10
                                x: parent.width - width
                                color: expandMouseArea.containsMouse ? (Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)) : "transparent"

                                Text {
                                    anchors.centerIn: parent
                                    text: root.expanded ? "v" : ">"
                                    color: Root.Theme.textSecondary
                                    font.family: Root.Theme.fontFamilyDisplay
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    renderType: Text.NativeRendering
                                }

                                MouseArea {
                                    id: expandMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor

                                    onPressed: function (mouse) {
                                        mouse.accepted = true;
                                        root._consumeCardReleaseActivation();
                                    }

                                    onClicked: function (mouse) {
                                        mouse.accepted = true;
                                        root.requestExpandToggle();
                                        root._suppressNextDefaultActivation = false;
                                    }
                                }
                            }

                            Rectangle {
                                id: centerDismissButton
                                visible: root.showDismissButton && root.interactionMode === "center"
                                width: 20
                                height: 20
                                radius: 10
                                x: parent.width - width
                                color: "transparent"

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: centerDismissMouseArea.containsMouse ? root.buttonHoverTintColor : root.buttonTintColor
                                    border.width: 1
                                    border.color: root.buttonHairlineColor
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: centerDismissMouseArea.containsMouse ? Qt.rgba(Root.Theme.menuHighlight.r, Root.Theme.menuHighlight.g, Root.Theme.menuHighlight.b, 0.16) : "transparent"
                                }

                                ShaderEffect {
                                    anchors.fill: parent
                                    visible: root.buttonEdgeLightEnabled
                                    property vector2d uSize: Qt.vector2d(width, height)
                                    property real uRadius: centerDismissButton.radius
                                    property real uLightAngleDeg: root.edgeLightAngleDeg
                                    property real uLightStrength: root.buttonEdgeLightStrength
                                    property real uLightWidthPx: root.buttonEdgeLightWidthPx
                                    property real uLightSharpness: root.buttonEdgeLightSharpness
                                    property real uCornerBoost: 0.45
                                    property real uEdgeOpacity: root.buttonEdgeLightOpacity
                                    property color uEdgeTint: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.92)
                                    fragmentShader: "../../shaders/notification_edge_light.frag.qsb"
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
                                    id: centerDismissMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor

                                    onPressed: function (mouse) {
                                        mouse.accepted = true;
                                        root._consumeCardReleaseActivation();
                                    }

                                    onClicked: function (mouse) {
                                        mouse.accepted = true;
                                        root.dismiss();
                                        root._suppressNextDefaultActivation = false;
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: bodyImageFrame
                        width: parent.width
                        height: visible ? Math.round(Math.max(72, Math.min(176, width * 0.52))) : 0
                        radius: 10
                        clip: true
                        visible: root.hasPreviewImage
                        color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.04)
                        border.width: 1
                        border.color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.08)

                        Image {
                            id: bodyImage
                            anchors.fill: parent
                            source: root.previewImageSource
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            asynchronous: true
                            visible: status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: bodyImage.status === Image.Error
                            text: "Image unavailable"
                            color: Root.Theme.textSecondary
                            font.family: Root.Theme.fontFamily
                            font.pixelSize: 11
                            renderType: Text.NativeRendering
                        }
                    }

                    Row {
                        id: actionRow
                        visible: root.actionsVisible
                        spacing: 6

                        Repeater {
                            model: root.actionButtonCount

                            Rectangle {
                                id: actionButton
                                required property int index
                                readonly property var actionData: root._safeAction(index)
                                readonly property string actionId: root._actionId(actionData)
                                readonly property string actionText: root._actionText(actionData)

                                visible: actionText.length > 0
                                implicitHeight: 24
                                implicitWidth: Math.min(150, Math.max(70, actionLabel.implicitWidth + 16))
                                radius: 8
                                color: "transparent"

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: actionMouseArea.containsMouse ? root.buttonHoverTintColor : root.buttonTintColor
                                    border.width: 1
                                    border.color: root.buttonHairlineColor
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: parent.radius
                                    color: actionMouseArea.containsMouse ? Qt.rgba(Root.Theme.menuHighlight.r, Root.Theme.menuHighlight.g, Root.Theme.menuHighlight.b, 0.22) : "transparent"
                                }

                                ShaderEffect {
                                    anchors.fill: parent
                                    visible: root.buttonEdgeLightEnabled
                                    property vector2d uSize: Qt.vector2d(width, height)
                                    property real uRadius: actionButton.radius
                                    property real uLightAngleDeg: root.edgeLightAngleDeg
                                    property real uLightStrength: root.buttonEdgeLightStrength
                                    property real uLightWidthPx: root.buttonEdgeLightWidthPx
                                    property real uLightSharpness: root.buttonEdgeLightSharpness
                                    property real uCornerBoost: 0.5
                                    property real uEdgeOpacity: root.buttonEdgeLightOpacity
                                    property color uEdgeTint: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.92)
                                    fragmentShader: "../../shaders/notification_edge_light.frag.qsb"
                                }

                                Text {
                                    id: actionLabel
                                    anchors.centerIn: parent
                                    text: actionButton.actionText
                                    color: Root.Theme.textPrimary
                                    font.family: Root.Theme.fontFamily
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                    renderType: Text.NativeRendering
                                }

                                MouseArea {
                                    id: actionMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton
                                    preventStealing: true
                                    cursorShape: Qt.PointingHandCursor

                                    onPressed: function (mouse) {
                                        mouse.accepted = true;
                                        root._consumeCardReleaseActivation();
                                    }

                                    onClicked: function (mouse) {
                                        mouse.accepted = true;
                                        root.invokeAction(actionButton.actionId);
                                        root._suppressNextDefaultActivation = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: popupActionsOverlay
            visible: root.popupActionsOverlayEligible
            enabled: root.popupActionsOverlayShown
            z: 2
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: root.cardPadding
            anchors.bottomMargin: root.cardPadding + Math.max(0, root.popupActionsBottomGap)
            implicitWidth: popupActionsOverlayBackground.implicitWidth
            implicitHeight: popupActionsOverlayBackground.implicitHeight
            width: implicitWidth
            height: implicitHeight
            opacity: root.popupActionsOverlayShown ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                id: popupActionsOverlayBackground
                implicitWidth: popupActionsOverlayRow.implicitWidth + 8
                implicitHeight: popupActionsOverlayRow.implicitHeight + 8
                radius: 9
                color: "transparent"
                border.width: 0
                border.color: "transparent"
                width: implicitWidth
                height: implicitHeight

                MouseArea {
                    id: popupActionsOverlayMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true
                    cursorShape: Qt.ArrowCursor

                    onPressed: function (mouse) {
                        mouse.accepted = true;
                        root._popupActionsOverlayPressed = true;
                        root._consumeCardReleaseActivation();
                    }

                    onReleased: function (mouse) {
                        mouse.accepted = true;
                        root._popupActionsOverlayPressed = false;
                    }

                    onCanceled: root._popupActionsOverlayPressed = false

                    onClicked: function (mouse) {
                        mouse.accepted = true;
                        root._suppressNextDefaultActivation = false;
                    }
                }

                Row {
                    id: popupActionsOverlayRow
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6

                    Repeater {
                        model: root.actionButtonCount

                        Rectangle {
                            id: popupActionButton
                            required property int index
                            readonly property var actionData: root._safeAction(index)
                            readonly property string actionId: root._actionId(actionData)
                            readonly property string actionText: root._actionText(actionData)

                            visible: actionText.length > 0
                            implicitHeight: 24
                            implicitWidth: Math.min(150, Math.max(70, popupActionLabel.implicitWidth + 16))
                            radius: 8
                            color: "transparent"

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: popupActionMouseArea.containsMouse ? root.buttonHoverTintColor : root.buttonTintColor
                                border.width: 1
                                border.color: root.buttonHairlineColor
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: popupActionMouseArea.containsMouse ? Qt.rgba(Root.Theme.menuHighlight.r, Root.Theme.menuHighlight.g, Root.Theme.menuHighlight.b, 0.22) : "transparent"
                            }

                            ShaderEffect {
                                anchors.fill: parent
                                visible: root.buttonEdgeLightEnabled
                                property vector2d uSize: Qt.vector2d(width, height)
                                property real uRadius: popupActionButton.radius
                                property real uLightAngleDeg: root.edgeLightAngleDeg
                                property real uLightStrength: root.buttonEdgeLightStrength
                                property real uLightWidthPx: root.buttonEdgeLightWidthPx
                                property real uLightSharpness: root.buttonEdgeLightSharpness
                                property real uCornerBoost: 0.5
                                property real uEdgeOpacity: root.buttonEdgeLightOpacity
                                property color uEdgeTint: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.92)
                                fragmentShader: "../../shaders/notification_edge_light.frag.qsb"
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
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton
                                preventStealing: true
                                cursorShape: Qt.PointingHandCursor

                                onPressed: function (mouse) {
                                    mouse.accepted = true;
                                    root._popupActionsOverlayPressed = true;
                                    root._consumeCardReleaseActivation();
                                }

                                onReleased: function (mouse) {
                                    mouse.accepted = true;
                                    root._popupActionsOverlayPressed = false;
                                }

                                onCanceled: root._popupActionsOverlayPressed = false

                                onClicked: function (mouse) {
                                    mouse.accepted = true;
                                    root.invokeAction(popupActionButton.actionId);
                                    root._suppressNextDefaultActivation = false;
                                }
                            }
                        }
                    }
                }
            }

            HoverHandler {
                id: popupActionsOverlayHover
            }
        }

        HoverHandler {
            id: hoverTracker
        }
    }

    Item {
        id: overlayLayer
        anchors.fill: parent
        clip: false
        z: 6

        // Popup-only dismiss overlay: corner-straddled, hover-revealed, and out of normal flow.
        Rectangle {
            id: popupDismissButton
            visible: root.showDismissButton && root.isPopupMode
            width: root.popupDismissSize
            height: root.popupDismissSize
            radius: 11
            z: 1
            x: cardSurface.x - Math.round(width / 2) + root.popupOverlayInset
            y: cardSurface.y - Math.round(height / 2) + root.popupOverlayInset
            opacity: root.revealDismissOnHover ? ((root.hovered || popupDismissHover.hovered || popupDismissMouseArea.containsMouse) ? 1 : 0) : 1
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: popupDismissMouseArea.containsMouse ? root.buttonHoverTintColor : root.buttonTintColor
                border.width: 1
                border.color: root.buttonHairlineColor
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: popupDismissMouseArea.containsMouse ? Qt.rgba(Root.Theme.menuHighlight.r, Root.Theme.menuHighlight.g, Root.Theme.menuHighlight.b, 0.16) : "transparent"
            }

            ShaderEffect {
                anchors.fill: parent
                visible: root.buttonEdgeLightEnabled
                property vector2d uSize: Qt.vector2d(width, height)
                property real uRadius: popupDismissButton.radius
                property real uLightAngleDeg: root.edgeLightAngleDeg
                property real uLightStrength: root.buttonEdgeLightStrength
                property real uLightWidthPx: root.buttonEdgeLightWidthPx
                property real uLightSharpness: root.buttonEdgeLightSharpness
                property real uCornerBoost: 0.45
                property real uEdgeOpacity: root.buttonEdgeLightOpacity
                property color uEdgeTint: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.95) : Qt.rgba(1, 1, 1, 0.92)
                fragmentShader: "../../shaders/notification_edge_light.frag.qsb"
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutCubic
                }
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

            HoverHandler {
                id: popupDismissHover
            }

            MouseArea {
                id: popupDismissMouseArea
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton
                preventStealing: true
                cursorShape: Qt.PointingHandCursor

                onPressed: function (mouse) {
                    mouse.accepted = true;
                    root._consumeCardReleaseActivation();
                }

                onClicked: function (mouse) {
                    mouse.accepted = true;
                    root.dismiss();
                    root._suppressNextDefaultActivation = false;
                }
            }
        }
    }
}
