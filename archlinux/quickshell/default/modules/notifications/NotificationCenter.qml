pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects

import "." as Notifications
import "../.." as Root

FocusScope {
    id: root

    property bool open: false
    property int panelWidth: 392
    property int panelMinHeight: 560
    property int panelPadding: 10
    property int headerHeight: 44
    property int listSpacing: 8
    property int maxHistoryVisible: 100
    property int clearButtonCompactWidth: 22
    property int clearButtonHorizontalPadding: 10
    property bool externalDismissEnabled: false
    property bool externalPopupActionsEnabled: false
    property alias dismissButtonModel: dismissWindowModel
    property alias actionOverlayModel: actionOverlayModelData
    property int activeControlsOwnerId: -1
    readonly property real clearButtonExpandedWidth: Math.max(clearButtonCompactWidth, Math.ceil(clearExpandedLabelMeasure.implicitWidth + (clearButtonHorizontalPadding * 2)))

    readonly property var notificationService: Root.NotificationService
    readonly property var notificationStyle: Notifications.NotificationStyle
    readonly property bool isEmpty: notificationService.historyCount === 0
    readonly property bool hasHistory: !isEmpty
    property int _cardHoverOwnerId: -1
    property int _dismissHoverOwnerId: -1
    property int _popupActionsHoverOwnerId: -1
    property int _controlsHandoffGraceOwnerId: -1
    property int _externalExitGraceOwnerId: -1

    signal requestClose
    signal dismissHoverStateChanged(int notificationId, bool hovered)
    signal popupActionsHoverStateChanged(int notificationId, bool hovered)

    implicitWidth: panelWidth
    implicitHeight: panelMinHeight

    visible: open || opacity > 0.01
    opacity: open ? 1 : 0
    x: open ? 0 : 16
    enabled: opacity > 0.95
    focus: open

    Keys.onEscapePressed: function (event) {
        if (!root.open) {
            return;
        }

        event.accepted = true;
        root.requestClose();
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: 170
            easing.type: Easing.OutCubic
        }
    }

    onOpenChanged: {
        if (!open) {
            clearAllExternalState();
        }
    }
    onHasHistoryChanged: {
        if (!hasHistory) {
            clearAllExternalState();
        }
    }
    onExternalDismissEnabledChanged: {
        if (!externalDismissEnabled) {
            dismissWindowModel.clear();
            if (_dismissHoverOwnerId >= 0) {
                dismissHoverStateChanged(_dismissHoverOwnerId, false);
            }
            _dismissHoverOwnerId = -1;
            _controlsHandoffGraceOwnerId = -1;
            _externalExitGraceOwnerId = -1;
            _syncOwnerLifetime(activeControlsOwnerId);
        } else {
            _syncAllOverlayEntries();
        }
    }
    onExternalPopupActionsEnabledChanged: {
        if (!externalPopupActionsEnabled) {
            actionOverlayModelData.clear();
            if (_popupActionsHoverOwnerId >= 0) {
                popupActionsHoverStateChanged(_popupActionsHoverOwnerId, false);
            }
            _popupActionsHoverOwnerId = -1;
            _controlsHandoffGraceOwnerId = -1;
            _externalExitGraceOwnerId = -1;
            _syncOwnerLifetime(activeControlsOwnerId);
        } else {
            _syncAllOverlayEntries();
        }
    }

    Connections {
        target: root.notificationService

        function onHistoryCountChanged() {
            if (root.activeControlsOwnerId >= 0 && !root._hasHistoryNotification(root.activeControlsOwnerId)) {
                root.clearExternalState(root.activeControlsOwnerId);
                return;
            }
            root._syncAllOverlayEntries();
        }
    }

    function _normalizeNotificationId(notificationId) {
        var numericId = Number(notificationId);
        if (!isFinite(numericId) || numericId < 0) {
            return -1;
        }
        return Math.floor(numericId);
    }

    function _hasHistoryNotification(notificationId) {
        var normalizedId = _normalizeNotificationId(notificationId);
        var historyList = notificationService ? notificationService.historyList : null;
        var i = 0;
        if (normalizedId < 0 || !historyList || historyList.count === undefined) {
            return false;
        }

        for (i = 0; i < historyList.count; i++) {
            var row = historyList.get(i);
            var rowId = row && row.notificationId !== undefined ? _normalizeNotificationId(row.notificationId) : _normalizeNotificationId(row ? row.id : -1);
            if (rowId === normalizedId) {
                return true;
            }
        }

        return false;
    }

    function isCenterNotificationOverlayActive(notificationId) {
        var normalizedId = _normalizeNotificationId(notificationId);
        return open && normalizedId >= 0 && activeControlsOwnerId === normalizedId && _hasHistoryNotification(normalizedId);
    }

    function _setDismissHoverState(notificationId, hovered) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }
        var nextHovered = !!hovered;
        if (nextHovered) {
            if (_dismissHoverOwnerId === normalizedId) {
                return;
            }
            if (_dismissHoverOwnerId >= 0) {
                dismissHoverStateChanged(_dismissHoverOwnerId, false);
            }
            _dismissHoverOwnerId = normalizedId;
            dismissHoverStateChanged(normalizedId, true);
            return;
        }

        if (_dismissHoverOwnerId === normalizedId) {
            _dismissHoverOwnerId = -1;
            dismissHoverStateChanged(normalizedId, false);
        }
    }

    function _setPopupActionsHoverState(notificationId, hovered) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }
        var nextHovered = !!hovered;
        if (nextHovered) {
            if (_popupActionsHoverOwnerId === normalizedId) {
                return;
            }
            if (_popupActionsHoverOwnerId >= 0) {
                popupActionsHoverStateChanged(_popupActionsHoverOwnerId, false);
            }
            _popupActionsHoverOwnerId = normalizedId;
            popupActionsHoverStateChanged(normalizedId, true);
            return;
        }

        if (_popupActionsHoverOwnerId === normalizedId) {
            _popupActionsHoverOwnerId = -1;
            popupActionsHoverStateChanged(normalizedId, false);
        }
    }

    function setActiveControlsOwner(notificationId) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0 || !_hasHistoryNotification(normalizedId)) {
            return;
        }

        if (activeControlsOwnerId >= 0 && activeControlsOwnerId !== normalizedId) {
            clearExternalState(activeControlsOwnerId);
        }

        activeControlsOwnerId = normalizedId;
        _cardHoverOwnerId = normalizedId;
        _syncAllOverlayEntries();
    }

    function clearCardHover(notificationId) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }

        if (_cardHoverOwnerId === normalizedId) {
            _cardHoverOwnerId = -1;
        }
        _syncOwnerLifetime(normalizedId);
        _syncAllOverlayEntries();
    }

    function setExternalDismissHovered(notificationId, hovered) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }
        var nextHovered = !!hovered;
        if (nextHovered) {
            if (!isCenterNotificationOverlayActive(normalizedId)) {
                return;
            }
            _setDismissHoverState(normalizedId, true);
        } else {
            _setDismissHoverState(normalizedId, false);
        }

        _syncOwnerLifetime(normalizedId);
        _syncAllOverlayEntries();
    }

    function setExternalPopupActionsHovered(notificationId, hovered) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }
        var nextHovered = !!hovered;
        if (nextHovered) {
            if (!isCenterNotificationOverlayActive(normalizedId)) {
                return;
            }
            _setPopupActionsHoverState(normalizedId, true);
        } else {
            _setPopupActionsHoverState(normalizedId, false);
        }

        _syncOwnerLifetime(normalizedId);
        _syncAllOverlayEntries();
    }

    function setControlsHandoffGrace(notificationId, active) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }

        var nextActive = !!active;
        if (nextActive) {
            if (!open || !_hasHistoryNotification(normalizedId)) {
                return;
            }

            if (_controlsHandoffGraceOwnerId >= 0 && _controlsHandoffGraceOwnerId !== normalizedId) {
                clearExternalState(_controlsHandoffGraceOwnerId);
            }
            _controlsHandoffGraceOwnerId = normalizedId;
            if (activeControlsOwnerId !== normalizedId) {
                activeControlsOwnerId = normalizedId;
            }
        } else if (_controlsHandoffGraceOwnerId === normalizedId) {
            _controlsHandoffGraceOwnerId = -1;
        }

        _syncOwnerLifetime(normalizedId);
        _syncAllOverlayEntries();
    }

    function setExternalExitGrace(notificationId, active) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }

        var nextActive = !!active;
        if (nextActive) {
            if (!open || !_hasHistoryNotification(normalizedId)) {
                return;
            }

            if (_externalExitGraceOwnerId >= 0 && _externalExitGraceOwnerId !== normalizedId) {
                clearExternalState(_externalExitGraceOwnerId);
            }
            _externalExitGraceOwnerId = normalizedId;
            if (activeControlsOwnerId !== normalizedId) {
                activeControlsOwnerId = normalizedId;
            }
        } else if (_externalExitGraceOwnerId === normalizedId) {
            _externalExitGraceOwnerId = -1;
        }

        _syncOwnerLifetime(normalizedId);
        _syncAllOverlayEntries();
    }

    function _syncOwnerLifetime(notificationId) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0 || activeControlsOwnerId !== normalizedId) {
            return;
        }
        if (!isCenterNotificationOverlayActive(normalizedId)) {
            clearExternalState(normalizedId);
            return;
        }

        var heldByCard = _cardHoverOwnerId === normalizedId;
        var heldByExternal = _dismissHoverOwnerId === normalizedId || _popupActionsHoverOwnerId === normalizedId;
        var heldByGrace = _controlsHandoffGraceOwnerId === normalizedId;
        var heldByExternalExitGrace = _externalExitGraceOwnerId === normalizedId;
        if (!heldByCard && !heldByExternal && !heldByGrace && !heldByExternalExitGrace) {
            clearExternalState(normalizedId);
        }
    }

    function clearAllExternalState() {
        if (activeControlsOwnerId >= 0) {
            clearExternalState(activeControlsOwnerId);
            return;
        }

        dismissWindowModel.clear();
        actionOverlayModelData.clear();

        if (_dismissHoverOwnerId >= 0) {
            dismissHoverStateChanged(_dismissHoverOwnerId, false);
            _dismissHoverOwnerId = -1;
        }
        if (_popupActionsHoverOwnerId >= 0) {
            popupActionsHoverStateChanged(_popupActionsHoverOwnerId, false);
            _popupActionsHoverOwnerId = -1;
        }
        _controlsHandoffGraceOwnerId = -1;
        _externalExitGraceOwnerId = -1;
        _cardHoverOwnerId = -1;
    }

    function clearExternalState(notificationId) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }

        _removeDismissModelEntry(normalizedId);
        _removeActionModelEntry(normalizedId);
        _setDismissHoverState(normalizedId, false);
        _setPopupActionsHoverState(normalizedId, false);
        if (_controlsHandoffGraceOwnerId === normalizedId) {
            _controlsHandoffGraceOwnerId = -1;
        }
        if (_externalExitGraceOwnerId === normalizedId) {
            _externalExitGraceOwnerId = -1;
        }

        if (_cardHoverOwnerId === normalizedId) {
            _cardHoverOwnerId = -1;
        }
        if (activeControlsOwnerId === normalizedId) {
            activeControlsOwnerId = -1;
        }
    }

    function _dismissModelIndex(notificationId) {
        var i = 0;
        for (i = 0; i < dismissWindowModel.count; i++) {
            if (_normalizeNotificationId(dismissWindowModel.get(i).notificationId) === notificationId) {
                return i;
            }
        }
        return -1;
    }

    function _removeDismissModelEntry(notificationId) {
        var index = _dismissModelIndex(notificationId);
        if (index >= 0) {
            dismissWindowModel.remove(index);
        }
    }

    function _upsertDismissModelEntry(notificationId, buttonX, buttonY, buttonSize, buttonOpacity) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0 || !externalDismissEnabled || !isCenterNotificationOverlayActive(normalizedId)) {
            _removeDismissModelEntry(normalizedId);
            return;
        }

        var roundedX = Math.round(buttonX);
        var roundedY = Math.round(buttonY);
        var roundedSize = Math.round(Math.max(0, buttonSize));
        var clampedOpacity = Math.max(0.0, Math.min(1.0, Number(buttonOpacity)));
        var index = _dismissModelIndex(normalizedId);

        if (index < 0) {
            dismissWindowModel.append({
                notificationId: normalizedId,
                buttonX: roundedX,
                buttonY: roundedY,
                buttonSize: roundedSize,
                buttonOpacity: clampedOpacity
            });
            return;
        }

        dismissWindowModel.set(index, {
            notificationId: normalizedId,
            buttonX: roundedX,
            buttonY: roundedY,
            buttonSize: roundedSize,
            buttonOpacity: clampedOpacity
        });
    }

    function _actionModelIndex(notificationId) {
        var i = 0;
        for (i = 0; i < actionOverlayModelData.count; i++) {
            if (_normalizeNotificationId(actionOverlayModelData.get(i).notificationId) === notificationId) {
                return i;
            }
        }
        return -1;
    }

    function _removeActionModelEntry(notificationId) {
        var index = _actionModelIndex(notificationId);
        if (index >= 0) {
            actionOverlayModelData.remove(index);
        }
    }

    function _upsertActionModelEntry(notificationId, overlayX, overlayY, overlayWidth, overlayHeight, overlayOpacity, actionsData) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0 || !externalPopupActionsEnabled || !isCenterNotificationOverlayActive(normalizedId)) {
            _removeActionModelEntry(normalizedId);
            return;
        }

        var roundedX = Math.round(overlayX);
        var roundedY = Math.round(overlayY);
        var roundedWidth = Math.round(Math.max(0, overlayWidth));
        var roundedHeight = Math.round(Math.max(0, overlayHeight));
        var clampedOpacity = Math.max(0.0, Math.min(1.0, Number(overlayOpacity)));
        var normalizedActions = [];
        var actionsLength = actionsData && actionsData.length !== undefined ? Number(actionsData.length) : 0;
        var i = 0;
        var index = _actionModelIndex(normalizedId);

        for (i = 0; i < actionsLength; i++) {
            var action = actionsData[i];
            if (!action) {
                continue;
            }

            var actionId = action.id === undefined || action.id === null ? "" : String(action.id);
            var actionText = action.text === undefined || action.text === null ? "" : String(action.text);
            if (actionText.length === 0) {
                continue;
            }

            normalizedActions.push({
                "id": actionId,
                "text": actionText
            });
        }

        var actionsJson = JSON.stringify(normalizedActions);
        var actionsCount = normalizedActions.length;

        if (index < 0) {
            actionOverlayModelData.append({
                notificationId: normalizedId,
                overlayX: roundedX,
                overlayY: roundedY,
                overlayWidth: roundedWidth,
                overlayHeight: roundedHeight,
                overlayOpacity: clampedOpacity,
                actionsCount: actionsCount,
                actionsJson: actionsJson
            });
            return;
        }

        actionOverlayModelData.set(index, {
            notificationId: normalizedId,
            overlayX: roundedX,
            overlayY: roundedY,
            overlayWidth: roundedWidth,
            overlayHeight: roundedHeight,
            overlayOpacity: clampedOpacity,
            actionsCount: actionsCount,
            actionsJson: actionsJson
        });
    }

    function _syncAllOverlayEntries() {
        var children = historyListView.contentItem ? historyListView.contentItem.children : [];
        var i = 0;

        for (i = 0; i < children.length; i++) {
            var child = children[i];
            if (!child) {
                continue;
            }
            if (child.syncExternalDismissEntry !== undefined) {
                child.syncExternalDismissEntry();
            }
            if (child.syncExternalActionEntry !== undefined) {
                child.syncExternalActionEntry();
            }
        }
    }

    Text {
        id: clearExpandedLabelMeasure
        visible: false
        text: "Clear All"
        font.family: Root.Theme.fontFamily
        font.pixelSize: 11
        font.weight: Font.Medium
        renderType: Text.NativeRendering
    }

    ListModel {
        id: dismissWindowModel
    }

    ListModel {
        id: actionOverlayModelData
    }


    Column {
        anchors.fill: parent
        anchors.margins: root.panelPadding
        spacing: 8

        Item {
            id: header
            width: parent.width
            height: root.headerHeight

            Text {
                id: leftTitle
                visible: !root.isEmpty
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(0, header.width - (headerControls.visible ? headerControls.width + 14 : 0))
                text: "Notification Center"
                elide: Text.ElideRight
                font.family: Root.Theme.fontFamilyDisplay
                font.pixelSize: 19
                font.weight: Font.Medium
                font.letterSpacing: -0.76
                color: "#ffffff"
                renderType: Text.NativeRendering
            }

            DropShadow {
                visible: leftTitle.visible
                anchors.fill: leftTitle
                source: leftTitle
                horizontalOffset: 0
                verticalOffset: 0
                radius: 6
                samples: 17
                spread: 0
                color: Qt.rgba(0, 0, 0, 0.5)
                cached: true
            }

            Text {
                id: centeredEmptyTitle
                visible: root.isEmpty
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                text: "No recent notifications"
                font.family: Root.Theme.fontFamilyDisplay
                font.pixelSize: 19
                font.weight: Font.Medium
                font.letterSpacing: -0.76
                color: "#ffffff"
                renderType: Text.NativeRendering
            }

            DropShadow {
                visible: centeredEmptyTitle.visible
                anchors.fill: centeredEmptyTitle
                source: centeredEmptyTitle
                horizontalOffset: 0
                verticalOffset: 0
                radius: 6
                samples: 17
                spread: 0
                color: Qt.rgba(0, 0, 0, 0.5)
                cached: true
            }

            Row {
                id: headerControls
                visible: root.hasHistory
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    id: clearButton
                    property bool hovered: clearButtonHover.hovered || clearMouseArea.containsMouse
                    width: hovered ? root.clearButtonExpandedWidth : root.clearButtonCompactWidth
                    height: 22
                    radius: 11
                    color: "transparent"
                    enabled: root.hasHistory
                    opacity: enabled ? 1 : 0.55
                    clip: true

                    Behavior on width {
                        NumberAnimation {
                            duration: 120
                            easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: clearMouseArea.containsMouse ? root.notificationStyle.buttonHoverTintColor : root.notificationStyle.buttonTintColor
                        border.width: 1
                        border.color: root.notificationStyle.buttonHairlineColor
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: clearMouseArea.containsMouse ? Qt.rgba(Root.Theme.menuHighlight.r, Root.Theme.menuHighlight.g, Root.Theme.menuHighlight.b, 0.16) : "transparent"
                    }

                    ShaderEffect {
                        anchors.fill: parent
                        property vector2d uSize: Qt.vector2d(width, height)
                        property real uRadius: clearButton.radius
                        property real uLightAngleDeg: root.notificationStyle.edgeLightAngleDeg
                        property real uLightStrength: root.notificationStyle.buttonEdgeLightStrength
                        property real uLightWidthPx: root.notificationStyle.buttonEdgeLightWidthPx
                        property real uLightSharpness: root.notificationStyle.buttonEdgeLightSharpness
                        property real uCornerBoost: 0.45
                        property real uEdgeOpacity: root.notificationStyle.buttonEdgeLightOpacity
                        property color uEdgeTint: root.notificationStyle.edgeLightTint
                        fragmentShader: "../../shaders/notification_edge_light.frag.qsb"
                    }

                    Text {
                        id: clearButtonLabel
                        anchors.centerIn: parent
                        text: clearButton.hovered ? "Clear All" : "􀅾"
                        color: Root.Theme.textSecondary
                        font.family: clearButton.hovered ? Root.Theme.fontFamily : Root.Theme.fontFamilyDisplay
                        font.pixelSize: clearButton.hovered ? 11 : 12
                        font.weight: clearButton.hovered ? Font.Medium : Font.DemiBold
                        renderType: Text.NativeRendering
                    }

                    HoverHandler {
                        id: clearButtonHover
                    }

                    MouseArea {
                        id: clearMouseArea
                        anchors.fill: parent
                        enabled: clearButton.enabled
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        preventStealing: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                        onPressed: function (mouse) {
                            mouse.accepted = true;
                        }

                        onClicked: function (mouse) {
                            mouse.accepted = true;
                            root.notificationService.clearHistory();
                        }
                    }
                }
            }
        }

        Item {
            id: bodyArea
            width: parent.width
            height: parent.height - header.height - parent.spacing

            MouseArea {
                id: bodyCloseMouseArea
                anchors.fill: parent
                enabled: root.open
                acceptedButtons: Qt.LeftButton
                preventStealing: true

                onClicked: function (mouse) {
                    mouse.accepted = true;
                    if (root.isEmpty || mouse.y >= historyListView.contentHeight) {
                        root.requestClose();
                    }
                }
            }

            ListView {
                id: historyListView
                anchors.fill: parent
                visible: !root.isEmpty
                clip: true
                spacing: root.listSpacing
                model: root.notificationService.historyList
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height
                orientation: ListView.Vertical
                verticalLayoutDirection: ListView.TopToBottom

                delegate: Item {
                    id: rowWrapper
                    required property int index
                    required property var model

                    readonly property bool withinVisibleLimit: index < Math.max(0, root.maxHistoryVisible)
                    readonly property int rowNotificationId: model && model.notificationId !== undefined ? Number(model.notificationId) : Number(model.id)
                    readonly property int rowRevision: model && model.revision !== undefined ? Number(model.revision) : 0
                    property int _trackedDismissNotificationId: -1
                    property int _trackedActionNotificationId: -1
                    property bool externalDismissHoverState: false
                    property bool externalPopupActionsHoverState: false
                    readonly property var notificationSnapshot: {
                        if (rowRevision < -1) {
                            return null;
                        }
                        if (rowNotificationId < 0) {
                            return null;
                        }
                        return root.notificationService.getNotification(rowNotificationId);
                    }
                    readonly property string resolvedRightSideImageSource: {
                        var snapshot = notificationSnapshot;
                        var rowModel = model;
                        if (snapshot && snapshot.rightSideImageSource !== undefined && String(snapshot.rightSideImageSource).length > 0) {
                            return String(snapshot.rightSideImageSource);
                        }
                        if (snapshot && snapshot.rightImageSource !== undefined && String(snapshot.rightImageSource).length > 0) {
                            return String(snapshot.rightImageSource);
                        }
                        if (rowModel && rowModel.rightSideImageSource !== undefined && String(rowModel.rightSideImageSource).length > 0) {
                            return String(rowModel.rightSideImageSource);
                        }
                        if (rowModel && rowModel.rightImageSource !== undefined && String(rowModel.rightImageSource).length > 0) {
                            return String(rowModel.rightImageSource);
                        }
                        return "";
                    }

                    width: historyListView.width
                    visible: withinVisibleLimit
                    height: visible ? card.implicitHeight : 0
                    opacity: visible ? 1 : 0

                    function _refreshExternalHoverSnapshots() {
                        externalDismissHoverState = root._dismissHoverOwnerId === rowNotificationId;
                        externalPopupActionsHoverState = root._popupActionsHoverOwnerId === rowNotificationId;
                    }

                    function syncExternalDismissEntry() {
                        if (_trackedDismissNotificationId >= 0 && _trackedDismissNotificationId !== rowNotificationId) {
                            root.clearExternalState(_trackedDismissNotificationId);
                        }

                        _trackedDismissNotificationId = rowNotificationId;

                        if (!root.externalDismissEnabled || rowNotificationId < 0 || !card.externalDismissEligible || !root.isCenterNotificationOverlayActive(rowNotificationId)) {
                            root._removeDismissModelEntry(rowNotificationId);
                            return;
                        }

                        var topLeft = card.mapToItem(root, card.dismissVisualX, card.dismissVisualY);
                        root._upsertDismissModelEntry(rowNotificationId, topLeft.x, topLeft.y, card.popupDismissSize, card.externalDismissOpacity);
                    }

                    function syncExternalActionEntry() {
                        if (_trackedActionNotificationId >= 0 && _trackedActionNotificationId !== rowNotificationId) {
                            root.clearExternalState(_trackedActionNotificationId);
                        }

                        _trackedActionNotificationId = rowNotificationId;

                        if (!root.externalPopupActionsEnabled || rowNotificationId < 0 || !card.externalPopupActionsEligible || !root.isCenterNotificationOverlayActive(rowNotificationId)) {
                            root._removeActionModelEntry(rowNotificationId);
                            return;
                        }

                        var actionsData = card.popupVisibleActions;
                        if (!actionsData || actionsData.length === 0) {
                            root._removeActionModelEntry(rowNotificationId);
                            return;
                        }

                        var topLeft = card.mapToItem(root, card.popupActionOverlayX, card.popupActionOverlayY);
                        root._upsertActionModelEntry(rowNotificationId, topLeft.x, topLeft.y, card.popupActionOverlayWidth, card.popupActionOverlayHeight, card.externalPopupActionsOpacity, actionsData);
                    }

                    function syncExternalOverlays() {
                        syncExternalDismissEntry();
                        syncExternalActionEntry();
                    }

                    NotificationCard {
                        id: card
                        width: parent.width
                        height: implicitHeight

                        notificationId: rowWrapper.rowNotificationId
                        appName: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.appName !== undefined ? String(rowWrapper.notificationSnapshot.appName) : (rowWrapper.model.appName ? String(rowWrapper.model.appName) : "")
                        appIcon: rowWrapper.notificationSnapshot ? rowWrapper.notificationSnapshot.appIcon : (rowWrapper.model.appIconHint ? String(rowWrapper.model.appIconHint) : "")
                        appIconHint: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.appIconHint !== undefined ? String(rowWrapper.notificationSnapshot.appIconHint) : (rowWrapper.model.appIconHint ? String(rowWrapper.model.appIconHint) : "")
                        resolvedAppIconSource: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.resolvedAppIconSource !== undefined ? rowWrapper.notificationSnapshot.resolvedAppIconSource : (rowWrapper.model.resolvedAppIconHint ? String(rowWrapper.model.resolvedAppIconHint) : "")
                        resolvedAppIconHint: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.resolvedAppIconHint !== undefined ? String(rowWrapper.notificationSnapshot.resolvedAppIconHint) : (rowWrapper.model.resolvedAppIconHint ? String(rowWrapper.model.resolvedAppIconHint) : "")
                        summary: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.summary !== undefined ? String(rowWrapper.notificationSnapshot.summary) : (rowWrapper.model.summary ? String(rowWrapper.model.summary) : "")
                        body: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.body !== undefined ? String(rowWrapper.notificationSnapshot.body) : (rowWrapper.model.body ? String(rowWrapper.model.body) : "")
                        image: rowWrapper.notificationSnapshot ? rowWrapper.notificationSnapshot.image : (rowWrapper.model.imageHint ? String(rowWrapper.model.imageHint) : "")
                        imageHint: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.imageHint !== undefined ? String(rowWrapper.notificationSnapshot.imageHint) : (rowWrapper.model.imageHint ? String(rowWrapper.model.imageHint) : "")
                        rightSideImageSource: rowWrapper.resolvedRightSideImageSource
                        contentPreviewImageSource: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.contentPreviewImageSource !== undefined ? String(rowWrapper.notificationSnapshot.contentPreviewImageSource) : (rowWrapper.model.contentPreviewImageSource ? String(rowWrapper.model.contentPreviewImageSource) : "")
                        hints: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.hints !== undefined ? rowWrapper.notificationSnapshot.hints : ({})
                        timeLabel: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.timeLabel !== undefined ? String(rowWrapper.notificationSnapshot.timeLabel) : (rowWrapper.model.timeLabel ? String(rowWrapper.model.timeLabel) : "")
                        actions: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.actions ? rowWrapper.notificationSnapshot.actions : []

                        keyboardInteractive: false
                        showActions: true
                        showDismissButton: true
                        showTimeLabel: true
                        dismissMode: "removeHistory"
                        clickActivatesDefault: true

                        mode: "center"
                        draggableDismiss: false
                        pauseTimeoutOnHover: false
                        revealDismissOnHover: true
                        externalDismissOverlayEnabled: root.externalDismissEnabled
                        externalDismissHover: rowWrapper.externalDismissHoverState
                        externalPopupActionsOverlayEnabled: root.externalPopupActionsEnabled
                        externalPopupActionsHover: rowWrapper.externalPopupActionsHoverState
                        controlsHoverOwnerId: root.activeControlsOwnerId
                    }

                    onXChanged: syncExternalOverlays()
                    onYChanged: syncExternalOverlays()
                    onWidthChanged: syncExternalOverlays()
                    onHeightChanged: syncExternalOverlays()

                    onRowNotificationIdChanged: {
                        root.clearExternalState(_trackedDismissNotificationId);
                        if (_trackedActionNotificationId !== _trackedDismissNotificationId) {
                            root.clearExternalState(_trackedActionNotificationId);
                        }

                        _refreshExternalHoverSnapshots();
                        syncExternalOverlays();
                    }
                    onRowRevisionChanged: {
                        card.resetVisualState();
                        syncExternalOverlays();
                    }

                    Component.onCompleted: {
                        _refreshExternalHoverSnapshots();
                        syncExternalOverlays();
                    }
                    Component.onDestruction: {
                        root.clearExternalState(_trackedDismissNotificationId);
                        if (_trackedActionNotificationId !== _trackedDismissNotificationId) {
                            root.clearExternalState(_trackedActionNotificationId);
                        }
                    }

                    Connections {
                        target: card

                        function onDismissVisualXChanged() {
                            rowWrapper.syncExternalDismissEntry();
                        }

                        function onDismissVisualYChanged() {
                            rowWrapper.syncExternalDismissEntry();
                        }

                        function onExternalDismissEligibleChanged() {
                            rowWrapper.syncExternalDismissEntry();
                        }

                        function onExternalDismissOpacityChanged() {
                            rowWrapper.syncExternalDismissEntry();
                        }

                        function onPopupDismissSizeChanged() {
                            rowWrapper.syncExternalDismissEntry();
                        }

                        function onPopupActionOverlayXChanged() {
                            rowWrapper.syncExternalActionEntry();
                        }

                        function onPopupActionOverlayYChanged() {
                            rowWrapper.syncExternalActionEntry();
                        }

                        function onPopupActionOverlayWidthChanged() {
                            rowWrapper.syncExternalActionEntry();
                        }

                        function onPopupActionOverlayHeightChanged() {
                            rowWrapper.syncExternalActionEntry();
                        }

                        function onExternalPopupActionsEligibleChanged() {
                            rowWrapper.syncExternalActionEntry();
                        }

                        function onExternalPopupActionsOpacityChanged() {
                            rowWrapper.syncExternalActionEntry();
                        }

                        function onPopupVisibleActionsChanged() {
                            rowWrapper.syncExternalActionEntry();
                        }

                        function onRequestControlsOwner(notificationId) {
                            root.setActiveControlsOwner(notificationId);
                            rowWrapper.syncExternalOverlays();
                        }

                        function onControlsHandoffGraceChanged(notificationId, active) {
                            root.setControlsHandoffGrace(notificationId, active);
                            rowWrapper.syncExternalOverlays();
                        }

                        function onExternalExitGraceChanged(notificationId, active) {
                            root.setExternalExitGrace(notificationId, active);
                            rowWrapper.syncExternalOverlays();
                        }

                        function onHoveredChanged() {
                            if (card.hovered) {
                                root.setActiveControlsOwner(rowWrapper.rowNotificationId);
                            } else {
                                root.clearCardHover(rowWrapper.rowNotificationId);
                            }
                            rowWrapper.syncExternalOverlays();
                        }
                    }

                    Connections {
                        target: root

                        function onDismissHoverStateChanged(notificationId, hovered) {
                            if (notificationId === rowWrapper.rowNotificationId) {
                                rowWrapper.externalDismissHoverState = hovered;
                                rowWrapper.syncExternalDismissEntry();
                            }
                        }

                        function onPopupActionsHoverStateChanged(notificationId, hovered) {
                            if (notificationId === rowWrapper.rowNotificationId) {
                                rowWrapper.externalPopupActionsHoverState = hovered;
                                rowWrapper.syncExternalActionEntry();
                            }
                        }
                    }
                }
            }
        }
    }
}
