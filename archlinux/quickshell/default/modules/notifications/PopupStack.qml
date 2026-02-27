pragma ComponentBehavior: Bound

import QtQuick

import "../.." as Root

Item {
    id: root

    property int edgeMargin: 12
    property int spacing: 8
    property int maxVisible: 5
    property int cardWidth: 352
    property int popupOverlayBleed: 11
    // Extra headroom so the top-most popup can render corner overlays above card bounds.
    property int popupOverlayTopBleed: 14
    property int maxHeight: 720
    property string anchorCorner: "top-right"
    property bool externalDismissEnabled: false
    property bool externalPopupActionsEnabled: false
    readonly property bool stackHovered: stackHoverHandler.hovered
    property alias dismissButtonModel: dismissWindowModel
    property alias actionOverlayModel: actionOverlayModelData
    property int activeControlsOwnerId: -1
    signal dismissHoverStateChanged(int notificationId, bool hovered)
    signal popupActionsHoverStateChanged(int notificationId, bool hovered)
    signal controlsHandoffGraceStateChanged(int notificationId, bool active)

    readonly property var notificationService: Root.NotificationService
    readonly property int visibleCount: notificationService.activeCount
    readonly property real contentHeightWithMargins: listView.contentHeight + (edgeMargin * 2) + popupOverlayTopBleed

    implicitWidth: cardWidth + (edgeMargin * 2)
    implicitHeight: visibleCount > 0 ? Math.min(maxHeight, contentHeightWithMargins) : 0

    width: implicitWidth
    height: implicitHeight
    clip: true
    visible: visibleCount > 0

    Component.onCompleted: {
        _syncServiceActiveLimit();
        _syncActivePopupStateFromService();
    }
    onMaxVisibleChanged: _syncServiceActiveLimit()
    onVisibleCountChanged: _syncActivePopupStateFromService()
    onExternalDismissEnabledChanged: {
        if (!externalDismissEnabled) {
            var dismissKey = "";
            var graceKey = "";
            for (dismissKey in _dismissHoverById) {
                if (Object.prototype.hasOwnProperty.call(_dismissHoverById, dismissKey) && _boolFromMap(_dismissHoverById, dismissKey)) {
                    dismissHoverStateChanged(Number(dismissKey), false);
                }
            }
            for (graceKey in _controlsHandoffGraceById) {
                if (Object.prototype.hasOwnProperty.call(_controlsHandoffGraceById, graceKey) && _boolFromMap(_controlsHandoffGraceById, graceKey)) {
                    controlsHandoffGraceStateChanged(Number(graceKey), false);
                }
            }
            dismissWindowModel.clear();
            _dismissHoverById = ({});
            _controlsHandoffGraceById = ({});
            if (!externalPopupActionsEnabled) {
                activeControlsOwnerId = -1;
                _activePopupById = ({});
            }
        } else {
            _syncActivePopupStateFromService();
            _syncAllOverlayEntries();
        }
    }
    onExternalPopupActionsEnabledChanged: {
        if (!externalPopupActionsEnabled) {
            var actionKey = "";
            var graceKey = "";
            for (actionKey in _popupActionsHoverById) {
                if (Object.prototype.hasOwnProperty.call(_popupActionsHoverById, actionKey) && _boolFromMap(_popupActionsHoverById, actionKey)) {
                    popupActionsHoverStateChanged(Number(actionKey), false);
                }
            }
            for (graceKey in _controlsHandoffGraceById) {
                if (Object.prototype.hasOwnProperty.call(_controlsHandoffGraceById, graceKey) && _boolFromMap(_controlsHandoffGraceById, graceKey)) {
                    controlsHandoffGraceStateChanged(Number(graceKey), false);
                }
            }
            actionOverlayModelData.clear();
            _popupActionsHoverById = ({});
            _controlsHandoffGraceById = ({});
            if (!externalDismissEnabled) {
                activeControlsOwnerId = -1;
                _activePopupById = ({});
            }
        } else {
            _syncActivePopupStateFromService();
            _syncAllOverlayEntries();
        }
    }

    function _syncServiceActiveLimit() {
        if (!notificationService || notificationService.maxActive === undefined) {
            return;
        }

        var nextLimit = Math.max(0, maxVisible);
        if (notificationService.maxActive !== nextLimit) {
            notificationService.maxActive = nextLimit;
        }
    }

    function setActiveControlsOwner(notificationId) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0 || !isPopupNotificationActive(normalizedId)) {
            return;
        }

        activeControlsOwnerId = normalizedId;
    }

    function clearActiveControlsOwner(notificationId) {
        var numericId = Number(notificationId);
        if (!isFinite(numericId) || numericId < 0) {
            return;
        }

        if (activeControlsOwnerId === Math.floor(numericId)) {
            activeControlsOwnerId = -1;
        }
    }

    property var _dismissHoverById: ({})
    property var _popupActionsHoverById: ({})
    property var _controlsHandoffGraceById: ({})
    property var _activePopupById: ({})

    function _normalizeNotificationId(notificationId) {
        var numericId = Number(notificationId);
        if (!isFinite(numericId) || numericId < 0) {
            return -1;
        }
        return Math.floor(numericId);
    }

    function _boolFromMap(map, key) {
        return Object.prototype.hasOwnProperty.call(map, key) && !!map[key];
    }

    function _setMapFlag(map, key, enabled) {
        var source = map || ({});
        var next = ({});
        var mapKey = "";

        for (mapKey in source) {
            if (!Object.prototype.hasOwnProperty.call(source, mapKey) || (!source[mapKey] && mapKey !== key)) {
                continue;
            }
            next[mapKey] = source[mapKey];
        }

        if (enabled) {
            next[key] = true;
        } else {
            delete next[key];
        }

        return next;
    }

    function _setPopupActive(notificationId, active) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }

        var key = String(normalizedId);
        _activePopupById = _setMapFlag(_activePopupById, key, !!active);
    }

    function _hasActivePopupInService(notificationId) {
        var normalizedId = _normalizeNotificationId(notificationId);
        var activeList = notificationService ? notificationService.activeList : null;
        var i = 0;
        if (normalizedId < 0 || !activeList || activeList.count === undefined) {
            return false;
        }

        for (i = 0; i < activeList.count; i++) {
            var row = activeList.get(i);
            var rowId = row && row.notificationId !== undefined ? _normalizeNotificationId(row.notificationId) : _normalizeNotificationId(row ? row.id : -1);
            if (rowId === normalizedId) {
                return true;
            }
        }

        return false;
    }

    function _buildServiceActivePopupMap() {
        var activeMap = ({});
        var activeList = notificationService ? notificationService.activeList : null;
        var i = 0;
        if (!activeList || activeList.count === undefined) {
            return activeMap;
        }

        for (i = 0; i < activeList.count; i++) {
            var row = activeList.get(i);
            var rowId = row && row.notificationId !== undefined ? _normalizeNotificationId(row.notificationId) : _normalizeNotificationId(row ? row.id : -1);
            if (rowId >= 0) {
                activeMap[String(rowId)] = true;
            }
        }

        return activeMap;
    }

    function _pruneInactiveOverlayEntries(activePopupMap) {
        var staleByKey = ({});
        var i = 0;
        var mapKey = "";

        for (i = 0; i < dismissWindowModel.count; i++) {
            var dismissId = _normalizeNotificationId(dismissWindowModel.get(i).notificationId);
            var dismissKey = String(dismissId);
            if (dismissId < 0 || !_boolFromMap(activePopupMap, dismissKey)) {
                staleByKey[dismissKey] = true;
            }
        }

        for (i = 0; i < actionOverlayModelData.count; i++) {
            var actionId = _normalizeNotificationId(actionOverlayModelData.get(i).notificationId);
            var actionKey = String(actionId);
            if (actionId < 0 || !_boolFromMap(activePopupMap, actionKey)) {
                staleByKey[actionKey] = true;
            }
        }

        for (mapKey in staleByKey) {
            if (!Object.prototype.hasOwnProperty.call(staleByKey, mapKey)) {
                continue;
            }
            clearExternalState(Number(mapKey));
        }
    }

    function _syncActivePopupStateFromService() {
        var activePopupMap = _buildServiceActivePopupMap();
        _activePopupById = activePopupMap;
        _pruneStaleExternalState();
        _pruneInactiveOverlayEntries(activePopupMap);
    }

    function isPopupNotificationActive(notificationId) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return false;
        }
        return _hasActivePopupInService(normalizedId);
    }

    function setControlsHandoffGrace(notificationId, active) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }

        var key = String(normalizedId);
        var nextActive = !!active;
        if (nextActive && !isPopupNotificationActive(normalizedId)) {
            return;
        }
        var prevActive = _boolFromMap(_controlsHandoffGraceById, key);
        if (prevActive === nextActive) {
            return;
        }

        _controlsHandoffGraceById = _setMapFlag(_controlsHandoffGraceById, key, nextActive);
        controlsHandoffGraceStateChanged(normalizedId, nextActive);
    }

    function beginNotificationExternalClose(notificationId) {
        clearExternalState(notificationId);
    }

    function clearExternalState(notificationId) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }

        // Gate external windows immediately so closure is not dependent on hover updates.
        _setPopupActive(normalizedId, false);
        setExternalDismissHovered(normalizedId, false);
        setExternalPopupActionsHovered(normalizedId, false);
        setControlsHandoffGrace(normalizedId, false);
        clearActiveControlsOwner(normalizedId);
        _removeDismissModelEntry(normalizedId);
        _removeActionModelEntry(normalizedId);
    }

    function clearNotificationExternalState(notificationId) {
        clearExternalState(notificationId);
    }

    function _pruneStaleExternalState() {
        var mapKey = "";

        for (mapKey in _dismissHoverById) {
            if (!Object.prototype.hasOwnProperty.call(_dismissHoverById, mapKey)) {
                continue;
            }
            if (_boolFromMap(_dismissHoverById, mapKey) && !_boolFromMap(_activePopupById, mapKey)) {
                setExternalDismissHovered(Number(mapKey), false);
            }
        }

        for (mapKey in _popupActionsHoverById) {
            if (!Object.prototype.hasOwnProperty.call(_popupActionsHoverById, mapKey)) {
                continue;
            }
            if (_boolFromMap(_popupActionsHoverById, mapKey) && !_boolFromMap(_activePopupById, mapKey)) {
                setExternalPopupActionsHovered(Number(mapKey), false);
            }
        }

        for (mapKey in _controlsHandoffGraceById) {
            if (!Object.prototype.hasOwnProperty.call(_controlsHandoffGraceById, mapKey)) {
                continue;
            }
            if (_boolFromMap(_controlsHandoffGraceById, mapKey) && !_boolFromMap(_activePopupById, mapKey)) {
                setControlsHandoffGrace(Number(mapKey), false);
            }
        }

        if (activeControlsOwnerId >= 0 && !isPopupNotificationActive(activeControlsOwnerId)) {
            activeControlsOwnerId = -1;
        }
    }

    function _dismissHoverKey(notificationId) {
        return String(notificationId);
    }

    function isExternalDismissHovered(notificationId) {
        var key = _dismissHoverKey(notificationId);
        return Object.prototype.hasOwnProperty.call(_dismissHoverById, key) && !!_dismissHoverById[key];
    }

    function setExternalDismissHovered(notificationId, hovered) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }

        var key = _dismissHoverKey(normalizedId);
        var nextHovered = !!hovered;
        if (nextHovered && !isPopupNotificationActive(normalizedId)) {
            clearExternalState(normalizedId);
            return;
        }
        var previousHovered = _boolFromMap(_dismissHoverById, key);
        if (previousHovered === nextHovered) {
            return;
        }

        _dismissHoverById = _setMapFlag(_dismissHoverById, key, nextHovered);
        dismissHoverStateChanged(normalizedId, nextHovered);

        if (nextHovered) {
            setActiveControlsOwner(normalizedId);
            return;
        }

        if (!isExternalPopupActionsHovered(normalizedId) && !isPopupNotificationActive(normalizedId)) {
            clearActiveControlsOwner(normalizedId);
        }
    }

    function _popupActionsHoverKey(notificationId) {
        return String(notificationId);
    }

    function isExternalPopupActionsHovered(notificationId) {
        var key = _popupActionsHoverKey(notificationId);
        return Object.prototype.hasOwnProperty.call(_popupActionsHoverById, key) && !!_popupActionsHoverById[key];
    }

    function setExternalPopupActionsHovered(notificationId, hovered) {
        var normalizedId = _normalizeNotificationId(notificationId);
        if (normalizedId < 0) {
            return;
        }

        var key = _popupActionsHoverKey(normalizedId);
        var nextHovered = !!hovered;
        if (nextHovered && !isPopupNotificationActive(normalizedId)) {
            clearExternalState(normalizedId);
            return;
        }
        var previousHovered = _boolFromMap(_popupActionsHoverById, key);
        if (previousHovered === nextHovered) {
            return;
        }

        _popupActionsHoverById = _setMapFlag(_popupActionsHoverById, key, nextHovered);
        popupActionsHoverStateChanged(normalizedId, nextHovered);

        if (nextHovered) {
            setActiveControlsOwner(normalizedId);
            return;
        }

        if (!isExternalDismissHovered(normalizedId) && !isPopupNotificationActive(normalizedId)) {
            clearActiveControlsOwner(normalizedId);
        }
    }

    function _dismissModelIndex(notificationId) {
        var i = 0;
        for (i = 0; i < dismissWindowModel.count; i++) {
            if (Number(dismissWindowModel.get(i).notificationId) === notificationId) {
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
        if (normalizedId < 0 || !isPopupNotificationActive(normalizedId)) {
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
            if (Number(actionOverlayModelData.get(i).notificationId) === notificationId) {
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
        if (normalizedId < 0 || !isPopupNotificationActive(normalizedId)) {
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
        var children = listView.contentItem ? listView.contentItem.children : [];
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

    ListModel {
        id: dismissWindowModel
    }

    ListModel {
        id: actionOverlayModelData
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.leftMargin: Math.max(0, root.edgeMargin - root.popupOverlayBleed)
        anchors.topMargin: root.edgeMargin
        anchors.rightMargin: root.edgeMargin
        anchors.bottomMargin: root.edgeMargin
        // Reserve renderable space *inside* the viewport so the first popup's
        // corner overlay can protrude above its delegate bounds without clipping.
        topMargin: root.popupOverlayTopBleed
        spacing: root.spacing
        clip: true
        // Keep popup delegates non-reused to avoid stale role visuals near maxVisible boundaries.
        reuseItems: false
        model: root.notificationService.activeList
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        orientation: ListView.Vertical
        verticalLayoutDirection: ListView.BottomToTop

        delegate: Item {
            id: rowWrapper
            required property var model
            readonly property int rowNotificationId: model && model.notificationId !== undefined ? Number(model.notificationId) : (model && model.id !== undefined ? Number(model.id) : -1)
            readonly property int rowRevision: model && model.revision !== undefined ? Number(model.revision) : 0
            property int _trackedDismissNotificationId: -1
            property int _trackedActionNotificationId: -1
            property bool externalDismissHoverState: false
            property bool externalPopupActionsHoverState: false
            readonly property var notificationSnapshot: {
                // Popups are capped service-side (maxActive) to avoid delegate visible/index gating loops.
                if (rowRevision < -1) {
                    return null;
                }
                if (rowNotificationId < 0) {
                    return null;
                }
                return root.notificationService.getNotification(rowNotificationId);
            }

            width: listView.width
            height: card.implicitHeight

            function _refreshExternalHoverSnapshots() {
                externalDismissHoverState = root.isExternalDismissHovered(rowNotificationId);
                externalPopupActionsHoverState = root.isExternalPopupActionsHovered(rowNotificationId);
            }

            function syncExternalDismissEntry() {
                if (_trackedDismissNotificationId >= 0 && _trackedDismissNotificationId !== rowNotificationId) {
                    root.clearNotificationExternalState(_trackedDismissNotificationId);
                }

                _trackedDismissNotificationId = rowNotificationId;

                if (!root.externalDismissEnabled || rowNotificationId < 0 || !card.externalDismissEligible) {
                    root._removeDismissModelEntry(rowNotificationId);
                    root.setExternalDismissHovered(rowNotificationId, false);
                    return;
                }
                if (!root.isPopupNotificationActive(rowNotificationId)) {
                    root.clearExternalState(rowNotificationId);
                    return;
                }

                var topLeft = card.mapToItem(root, card.dismissVisualX, card.dismissVisualY);
                root._upsertDismissModelEntry(rowNotificationId, topLeft.x, topLeft.y, card.popupDismissSize, card.externalDismissOpacity);
            }

            function syncExternalActionEntry() {
                if (_trackedActionNotificationId >= 0 && _trackedActionNotificationId !== rowNotificationId) {
                    root.clearNotificationExternalState(_trackedActionNotificationId);
                }

                _trackedActionNotificationId = rowNotificationId;

                if (!root.externalPopupActionsEnabled || rowNotificationId < 0 || !card.externalPopupActionsEligible) {
                    root._removeActionModelEntry(rowNotificationId);
                    root.setExternalPopupActionsHovered(rowNotificationId, false);
                    return;
                }
                if (!root.isPopupNotificationActive(rowNotificationId)) {
                    root.clearExternalState(rowNotificationId);
                    return;
                }

                var actionsData = card.popupVisibleActions;
                if (!actionsData || actionsData.length === 0) {
                    root._removeActionModelEntry(rowNotificationId);
                    root.setExternalPopupActionsHovered(rowNotificationId, false);
                    return;
                }

                var topLeft = card.mapToItem(root, card.popupActionOverlayX, card.popupActionOverlayY);
                root._upsertActionModelEntry(rowNotificationId, topLeft.x, topLeft.y, card.popupActionOverlayWidth, card.popupActionOverlayHeight, card.externalPopupActionsOpacity, actionsData);
            }

            NotificationCard {
                id: card
                width: root.cardWidth
                height: parent.height
                anchors.right: parent.right
                anchors.top: parent.top

                notificationId: rowWrapper.rowNotificationId
                appName: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.appName !== undefined ? String(rowWrapper.notificationSnapshot.appName) : (rowWrapper.model && rowWrapper.model.appName ? String(rowWrapper.model.appName) : "")
                appIcon: rowWrapper.notificationSnapshot ? rowWrapper.notificationSnapshot.appIcon : (rowWrapper.model && rowWrapper.model.appIconHint ? String(rowWrapper.model.appIconHint) : "")
                appIconHint: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.appIconHint !== undefined ? String(rowWrapper.notificationSnapshot.appIconHint) : (rowWrapper.model && rowWrapper.model.appIconHint ? String(rowWrapper.model.appIconHint) : "")
                resolvedAppIconSource: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.resolvedAppIconSource !== undefined ? rowWrapper.notificationSnapshot.resolvedAppIconSource : (rowWrapper.model && rowWrapper.model.resolvedAppIconHint ? String(rowWrapper.model.resolvedAppIconHint) : "")
                resolvedAppIconHint: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.resolvedAppIconHint !== undefined ? String(rowWrapper.notificationSnapshot.resolvedAppIconHint) : (rowWrapper.model && rowWrapper.model.resolvedAppIconHint ? String(rowWrapper.model.resolvedAppIconHint) : "")
                summary: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.summary !== undefined ? String(rowWrapper.notificationSnapshot.summary) : (rowWrapper.model && rowWrapper.model.summary ? String(rowWrapper.model.summary) : "")
                body: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.body !== undefined ? String(rowWrapper.notificationSnapshot.body) : (rowWrapper.model && rowWrapper.model.body ? String(rowWrapper.model.body) : "")
                image: rowWrapper.notificationSnapshot ? rowWrapper.notificationSnapshot.image : (rowWrapper.model && rowWrapper.model.imageHint ? String(rowWrapper.model.imageHint) : "")
                imageHint: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.imageHint !== undefined ? String(rowWrapper.notificationSnapshot.imageHint) : (rowWrapper.model && rowWrapper.model.imageHint ? String(rowWrapper.model.imageHint) : "")
                rightSideImageSource: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.rightSideImageSource !== undefined ? String(rowWrapper.notificationSnapshot.rightSideImageSource) : (rowWrapper.model && rowWrapper.model.rightSideImageSource ? String(rowWrapper.model.rightSideImageSource) : "")
                contentPreviewImageSource: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.contentPreviewImageSource !== undefined ? String(rowWrapper.notificationSnapshot.contentPreviewImageSource) : (rowWrapper.model && rowWrapper.model.contentPreviewImageSource ? String(rowWrapper.model.contentPreviewImageSource) : "")
                hints: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.hints !== undefined ? rowWrapper.notificationSnapshot.hints : ({})
                timeLabel: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.timeLabel !== undefined ? String(rowWrapper.notificationSnapshot.timeLabel) : (rowWrapper.model && rowWrapper.model.timeLabel ? String(rowWrapper.model.timeLabel) : "")
                actions: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.actions ? rowWrapper.notificationSnapshot.actions : []
                keyboardInteractive: false
                interactionMode: "popup"
                showTimeLabel: false
                draggableDismiss: true
                pauseTimeoutOnHover: true
                externalHoverHold: root.stackHovered
                externalDismissOverlayEnabled: root.externalDismissEnabled
                externalDismissHover: rowWrapper.externalDismissHoverState
                externalPopupActionsOverlayEnabled: root.externalPopupActionsEnabled
                externalPopupActionsHover: rowWrapper.externalPopupActionsHoverState
                controlsHoverOwnerId: root.activeControlsOwnerId
                expandable: false
            }

            function syncExternalOverlays() {
                syncExternalDismissEntry();
                syncExternalActionEntry();
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
                root._setPopupActive(rowNotificationId, true);
                root._syncActivePopupStateFromService();
                _refreshExternalHoverSnapshots();
                card.resetVisualState();
                syncExternalOverlays();
            }
            onRowRevisionChanged: {
                card.resetVisualState();
                syncExternalOverlays();
            }

            Component.onCompleted: {
                root._setPopupActive(rowNotificationId, true);
                root._syncActivePopupStateFromService();
                _refreshExternalHoverSnapshots();
                syncExternalOverlays();
            }
            Component.onDestruction: {
                root.clearNotificationExternalState(_trackedDismissNotificationId);
                if (_trackedActionNotificationId !== _trackedDismissNotificationId) {
                    root.clearNotificationExternalState(_trackedActionNotificationId);
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
                }

                function onControlsHandoffGraceChanged(notificationId, active) {
                    root.setControlsHandoffGrace(notificationId, active);
                }
            }

            Connections {
                target: root

                function onDismissHoverStateChanged(notificationId, hovered) {
                    if (notificationId === rowWrapper.rowNotificationId) {
                        rowWrapper.externalDismissHoverState = hovered;
                    }
                }

                function onPopupActionsHoverStateChanged(notificationId, hovered) {
                    if (notificationId === rowWrapper.rowNotificationId) {
                        rowWrapper.externalPopupActionsHoverState = hovered;
                    }
                }
            }
        }
    }

    HoverHandler {
        id: stackHoverHandler
    }
}
