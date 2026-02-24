pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "NotificationTime.js" as NotificationTime

Singleton {
    id: root

    property int maxActive: 5
    property int maxHistory: 100
    property int defaultPopupTimeoutMs: 5000
    property bool keepTransientInHistory: false
    property bool resetTimestampOnReplace: true
    property bool debugLogging: true
    property bool debugActiveRowUpdates: false
    property int debugMediaLogLimit: 10
    property int _debugMediaLogsEmitted: 0

    readonly property alias activeList: activeListModel
    readonly property alias historyList: historyListModel
    readonly property int activeCount: activeListModel.count
    readonly property int historyCount: historyListModel.count

    // Canonical normalized record by notification id.
    readonly property var byId: _byId
    // Lifecycle metadata by notification id (received/expires/visibility flags).
    readonly property var metadataById: _metadataById

    property var _byId: ({})
    property var _metadataById: ({})
    property var _sourceById: ({})
    property var _sourceTokenById: ({})

    ListModel {
        id: activeListModel
    }

    ListModel {
        id: historyListModel
    }

    NotificationServer {
        id: notificationServer

        // Service capabilities currently implemented by this backend.
        actionsSupported: true
        persistenceSupported: true
        bodyMarkupSupported: false
        bodySupported: true
        imageSupported: true
        actionIconsSupported: false
        inlineReplySupported: false
        bodyImagesSupported: false
        bodyHyperlinksSupported: false
        keepOnReload: true

        onNotification: function (notification) {
            root._handleIncomingNotification(notification);
        }
    }

    // Dedicated timeout handling for popup auto-expire semantics.
    Timer {
        id: expireTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: root._expireTimedOutPopups()
    }

    // Periodically refresh user-facing time labels for active/history models.
    Timer {
        id: timeLabelTimer
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.refreshTimeLabels()
    }

    function hasNotification(id) {
        return _hasOwn(_byId, _idKey(id));
    }

    function getNotification(id) {
        var idKey = _idKey(id);
        if (!_hasOwn(_byId, idKey)) {
            return null;
        }

        var record = _byId[idKey];
        var metadata = _metadataById[idKey] || ({});

        return {
            id: record.id,
            appName: record.appName,
            appIcon: record.appIcon,
            appIconHint: record.appIconHint,
            resolvedAppIconSource: record.resolvedAppIconSource !== undefined ? record.resolvedAppIconSource : record.appIcon,
            resolvedAppIconHint: _safeString(record.resolvedAppIconHint),
            summary: record.summary,
            body: record.body,
            image: record.image,
            imageHint: record.imageHint,
            rightSideImageSource: _safeString(record.rightSideImageSource),
            contentPreviewImageSource: _safeString(record.contentPreviewImageSource),
            mediaCategory: _safeString(record.mediaCategory),
            urgency: record.urgency,
            actions: _copyActions(record.actions),
            actionCount: _safeNumber(record.actionCount, 0),
            resident: record.resident,
            transient: record.transient,
            expireTimeout: record.expireTimeout,
            receivedAt: metadata.receivedAt || record.receivedAt,
            timeLabel: NotificationTime.shortRelativeLabel(metadata.receivedAt || record.receivedAt, Date.now()),
            isPopup: !!metadata.popupVisible,
            inHistory: !!metadata.inHistory,
            lastGeneration: record.lastGeneration,
            desktopEntry: record.desktopEntry,
            hints: record.hints,
            revision: _safeNumber(metadata.revision, 0),
            dismissed: !!metadata.dismissed,
            expired: !!metadata.expired,
            closeReason: _safeString(metadata.closeReason)
        };
    }

    function dismissNotification(id) {
        return _closeNotification(id, "dismiss");
    }

    function expireNotification(id) {
        return _closeNotification(id, "expire");
    }

    function clearAllPopups() {
        var ids = [];
        var i = 0;

        for (i = 0; i < activeListModel.count; i++) {
            ids.push(_modelRowId(activeListModel.get(i)));
        }

        for (i = 0; i < ids.length; i++) {
            dismissNotification(ids[i]);
        }

        _debug("cleared popups count=" + ids.length);
    }

    function clearHistory() {
        var ids = [];
        var i = 0;

        for (i = 0; i < historyListModel.count; i++) {
            ids.push(_modelRowId(historyListModel.get(i)));
        }

        historyListModel.clear();

        for (i = 0; i < ids.length; i++) {
            var idKey = _idKey(ids[i]);
            if (_hasOwn(_metadataById, idKey)) {
                _metadataById[idKey].inHistory = false;
                _upsertActiveRow(idKey);
                _dropStateIfUnreferenced(idKey);
            }
        }

        _debug("cleared history count=" + ids.length);
    }

    function clearAll() {
        // Clear semantics: dismiss visible popups, then clear the in-memory history list.
        clearAllPopups();
        clearHistory();
    }

    function setPopupTimeoutPaused(id, paused) {
        var idKey = _idKey(id);
        if (!_hasOwn(_byId, idKey) || !_hasOwn(_metadataById, idKey)) {
            return false;
        }

        var metadata = _metadataById[idKey];
        if (!metadata.popupVisible) {
            return false;
        }

        var shouldPause = _safeBool(paused, false);
        var isPaused = _safeBool(metadata.timeoutPaused, false);
        if (shouldPause === isPaused) {
            return true;
        }

        var now = Date.now();

        if (shouldPause) {
            var expiresAt = _safeNumber(metadata.expiresAt, -1);
            if (expiresAt > 0) {
                metadata.pausedRemainingMs = Math.max(0, expiresAt - now);
                metadata.expiresAt = -1;
            } else {
                metadata.pausedRemainingMs = -1;
            }
            metadata.timeoutPaused = true;
        } else {
            var remainingMs = _safeNumber(metadata.pausedRemainingMs, -1);
            metadata.timeoutPaused = false;
            metadata.pausedRemainingMs = 0;

            if (remainingMs > 0) {
                metadata.expiresAt = now + remainingMs;
            } else if (remainingMs === 0) {
                metadata.expiresAt = now;
            } else {
                metadata.expiresAt = -1;
            }
        }

        _metadataById[idKey] = metadata;
        return true;
    }

    function removeFromHistory(id) {
        var idKey = _idKey(id);
        if (!_hasOwn(_byId, idKey)) {
            return false;
        }

        var removed = _removeModelRowById(historyListModel, _byId[idKey].id);
        if (!removed) {
            return false;
        }

        if (_hasOwn(_metadataById, idKey)) {
            _metadataById[idKey].inHistory = false;
            _upsertActiveRow(idKey);
            _dropStateIfUnreferenced(idKey);
        }

        _debug("removed from history id=" + id);
        return true;
    }

    function invokeAction(id, actionId) {
        var idKey = _idKey(id);
        if (!_hasOwn(_byId, idKey)) {
            return {
                ok: false,
                reason: "not-found"
            };
        }

        var source = _sourceById[idKey];
        if (!source) {
            return {
                ok: false,
                reason: "source-unavailable"
            };
        }

        var action = _findSourceAction(source, actionId);
        if (!action) {
            return {
                ok: false,
                reason: "action-not-found"
            };
        }

        try {
            action.invoke();
            _debug("invoked action id=" + id + " actionId=" + _safeString(actionId));
            return {
                ok: true,
                invoked: true
            };
        } catch (error) {
            _debug("action invoke failed id=" + id + " actionId=" + _safeString(actionId) + " error=" + error);
            return {
                ok: false,
                reason: "invoke-failed",
                error: _safeString(error)
            };
        }
    }

    function defaultActivate(id) {
        var idKey = _idKey(id);
        if (!_hasOwn(_byId, idKey)) {
            return {
                ok: false,
                reason: "not-found"
            };
        }

        var actions = _byId[idKey].actions || [];
        var meaningful = [];
        var i = 0;

        for (i = 0; i < actions.length; i++) {
            var action = actions[i];
            if (!action) {
                continue;
            }

            var actionId = _safeString(action.id);
            if (actionId.length === 0) {
                continue;
            }

            meaningful.push(action);
        }

        if (meaningful.length === 1) {
            var result = invokeAction(id, meaningful[0].id);
            if (result.ok) {
                result.defaultActivated = true;
            }
            return result;
        }

        return {
            ok: true,
            invoked: false,
            defaultActivated: false,
            reason: meaningful.length === 0 ? "no-actions" : "multiple-actions",
            actionCount: meaningful.length
        };
    }

    function refreshTimeLabels() {
        _refreshModelTimeLabels(activeListModel);
        _refreshModelTimeLabels(historyListModel);
    }

    function _handleIncomingNotification(notification) {
        if (!notification) {
            return;
        }

        var incomingId = _safeNumber(notification.id, -1);
        if (incomingId < 0) {
            _debug("dropped notification with invalid id");
            return;
        }

        var replacesId = _extractReplacementId(notification);
        var idKey = _resolveRecordIdKey(incomingId, replacesId);
        var recordId = _safeNumber(idKey, incomingId);
        var existed = _hasOwn(_byId, idKey);
        var now = Date.now();
        var receivedAt = now;

        if (existed && !resetTimestampOnReplace && _hasOwn(_metadataById, idKey)) {
            receivedAt = _safeNumber(_metadataById[idKey].receivedAt, now);
        }

        // Track notification lifetime while it is represented in active/history models.
        try {
            notification.tracked = true;
        } catch (error) {
            _debug("failed to set tracked=true id=" + incomingId + " error=" + error);
        }

        var record = _normalizeNotification(notification, receivedAt, recordId);
        var metadata = _metadataById[idKey] || ({});

        metadata.receivedAt = receivedAt;
        metadata.expiresAt = _computeExpiresAt(record.expireTimeout, receivedAt, record.resident);
        metadata.timeoutPaused = false;
        metadata.pausedRemainingMs = 0;
        metadata.popupVisible = true;
        metadata.dismissed = false;
        metadata.expired = false;
        metadata.closeReason = "";
        metadata.sourceAlive = true;
        metadata.revision = _safeNumber(metadata.revision, 0) + 1;
        if (metadata.inHistory !== true && _shouldAddToHistory(record)) {
            metadata.inHistory = true;
        } else if (metadata.inHistory !== true) {
            metadata.inHistory = false;
        }

        _byId[idKey] = record;
        _metadataById[idKey] = metadata;
        _sourceById[idKey] = notification;
        _sourceTokenById[idKey] = _safeNumber(_sourceTokenById[idKey], 0) + 1;

        _attachClosedHandler(notification, idKey, _sourceTokenById[idKey]);
        _attachUpdateHandlers(notification, idKey, _sourceTokenById[idKey]);
        _upsertActiveRow(idKey);

        if (metadata.inHistory) {
            _upsertHistoryRow(idKey);
        } else {
            _removeModelRowById(historyListModel, record.id);
        }

        _enforceLimits();
        _debugReceiveDecision(incomingId, replacesId, record.id, existed);
        _debugMediaFields(incomingId, record);
        _debug((existed ? "updated" : "received") + " id=" + record.id + " incomingId=" + incomingId + " replaceId=" + (replacesId > 0 ? replacesId : "none") + " app=" + record.appName + " popupVisible=" + metadata.popupVisible + " inHistory=" + metadata.inHistory + " timeout=" + record.expireTimeout + " lastGeneration=" + record.lastGeneration + " revision=" + metadata.revision);
    }

    function _attachClosedHandler(notification, idKey, token) {
        if (!notification || !notification.closed || !notification.closed.connect) {
            return;
        }

        try {
            notification.closed.connect(function (reason) {
                root._handleClosedNotification(idKey, token, reason);
            });
        } catch (error) {
            _debug("failed to connect closed handler id=" + idKey + " error=" + error);
        }
    }

    function _attachUpdateHandlers(notification, idKey, token) {
        if (!notification) {
            return;
        }

        function bind(signalName) {
            _connectSourceSignal(notification, signalName, function () {
                root._refreshFromSource(idKey, token, signalName);
            });
        }

        bind("appNameChanged");
        bind("appIconChanged");
        bind("summaryChanged");
        bind("bodyChanged");
        bind("imageChanged");
        bind("actionsChanged");
        bind("urgencyChanged");
        bind("residentChanged");
        bind("transientChanged");
        bind("expireTimeoutChanged");
        bind("lastGenerationChanged");
        bind("desktopEntryChanged");
        bind("hintsChanged");
    }

    function _connectSourceSignal(notification, signalName, callback) {
        if (!notification || !signalName || !callback) {
            return false;
        }

        var signalObject = notification[signalName];
        if (!signalObject || !signalObject.connect) {
            return false;
        }

        try {
            signalObject.connect(callback);
            return true;
        } catch (error) {
            _debug("failed to connect source signal id=" + _safeString(notification.id) + " signal=" + signalName + " error=" + error);
        }

        return false;
    }

    function _refreshFromSource(idKey, expectedToken, triggerName) {
        if (!_hasOwn(_sourceTokenById, idKey)) {
            return;
        }

        if (_safeNumber(_sourceTokenById[idKey], 0) !== _safeNumber(expectedToken, -1)) {
            return;
        }

        if (!_hasOwn(_byId, idKey) || !_hasOwn(_metadataById, idKey)) {
            return;
        }

        var source = _sourceById[idKey];
        if (!source) {
            return;
        }

        var metadata = _metadataById[idKey];
        var now = Date.now();
        var receivedAt = resetTimestampOnReplace ? now : _safeNumber(metadata.receivedAt, now);
        var recordId = _safeNumber(_byId[idKey].id, _safeNumber(source.id, 0));
        var record = _normalizeNotification(source, receivedAt, recordId);

        metadata.receivedAt = receivedAt;
        metadata.expiresAt = _computeExpiresAt(record.expireTimeout, receivedAt, record.resident);
        metadata.timeoutPaused = false;
        metadata.pausedRemainingMs = 0;
        metadata.popupVisible = true;
        metadata.dismissed = false;
        metadata.expired = false;
        metadata.closeReason = "";
        metadata.sourceAlive = true;
        metadata.revision = _safeNumber(metadata.revision, 0) + 1;
        if (metadata.inHistory !== true && _shouldAddToHistory(record)) {
            metadata.inHistory = true;
        } else if (metadata.inHistory !== true) {
            metadata.inHistory = false;
        }

        _byId[idKey] = record;
        _metadataById[idKey] = metadata;

        _upsertActiveRow(idKey);
        if (metadata.inHistory) {
            _upsertHistoryRow(idKey);
        } else {
            _removeModelRowById(historyListModel, record.id);
        }

        _enforceLimits();
        _debugMediaFields(_safeNumber(source.id, record.id), record);
        _debug("source update id=" + record.id + " trigger=" + _safeString(triggerName) + " revision=" + metadata.revision);
    }

    function _handleClosedNotification(idKey, expectedToken, reason) {
        if (!_hasOwn(_sourceTokenById, idKey)) {
            return;
        }

        if (_safeNumber(_sourceTokenById[idKey], 0) !== _safeNumber(expectedToken, -1)) {
            _debug("ignored stale close signal id=" + idKey);
            return;
        }

        if (_hasOwn(_metadataById, idKey)) {
            _metadataById[idKey].sourceAlive = false;
        }

        _sourceById[idKey] = null;
        _applyClose(idKey, reason, false);
        _debug("closed id=" + idKey + " reason=" + _closeReasonToString(reason));
    }

    function _closeNotification(id, mode) {
        var idKey = _idKey(id);
        if (!_hasOwn(_byId, idKey)) {
            return false;
        }

        var source = _sourceById[idKey];
        var closeReason = mode === "expire" ? NotificationCloseReason.Expired : NotificationCloseReason.Dismissed;

        // UI state updates happen immediately; source object close is best-effort.
        _applyClose(idKey, closeReason, !!source);

        if (!source) {
            return true;
        }

        try {
            if (mode === "expire") {
                source.expire();
                _debug("expire requested id=" + id);
            } else {
                source.dismiss();
                _debug("dismiss requested id=" + id);
            }
        } catch (error) {
            _debug("failed close request id=" + id + " mode=" + mode + " error=" + error);
        }

        return true;
    }

    function _applyClose(idKey, reason, sourceAlive) {
        if (!_hasOwn(_byId, idKey) || !_hasOwn(_metadataById, idKey)) {
            return;
        }

        var record = _byId[idKey];
        var metadata = _metadataById[idKey];
        var reasonName = _closeReasonToString(reason);

        metadata.popupVisible = false;
        metadata.expiresAt = -1;
        metadata.timeoutPaused = false;
        metadata.pausedRemainingMs = 0;
        metadata.closeReason = reasonName;
        metadata.sourceAlive = sourceAlive;
        metadata.revision = _safeNumber(metadata.revision, 0) + 1;

        if (reason === NotificationCloseReason.Dismissed || reasonName === "Dismissed") {
            metadata.dismissed = true;
        }

        if (reason === NotificationCloseReason.Expired || reasonName === "Expired") {
            metadata.expired = true;
        }

        _metadataById[idKey] = metadata;

        _removeModelRowById(activeListModel, record.id);
        _upsertHistoryRow(idKey);
        _dropStateIfUnreferenced(idKey);
    }

    function _expireTimedOutPopups() {
        var ids = [];
        var i = 0;

        for (i = 0; i < activeListModel.count; i++) {
            ids.push(_modelRowId(activeListModel.get(i)));
        }

        var now = Date.now();
        for (i = 0; i < ids.length; i++) {
            var idKey = _idKey(ids[i]);
            if (!_hasOwn(_metadataById, idKey)) {
                continue;
            }

            var metadata = _metadataById[idKey];
            if (!metadata.popupVisible) {
                continue;
            }

            if (_safeBool(metadata.timeoutPaused, false)) {
                continue;
            }

            var expiresAt = _safeNumber(metadata.expiresAt, -1);
            if (expiresAt > 0 && now >= expiresAt) {
                _debug("auto-expire id=" + ids[i]);
                expireNotification(ids[i]);
            }
        }
    }

    function _shouldAddToHistory(record) {
        // Transient notifications are popup-only unless explicitly enabled.
        if (record.transient && !keepTransientInHistory) {
            return false;
        }
        return true;
    }

    function _normalizeNotification(notification, receivedAt, recordId) {
        var appIconValue = _normalizeMediaValue(notification.appIcon);
        var imageValue = _normalizeMediaValue(notification.image);
        var actionsValue = _normalizeActions(notification);
        var hintsValue = notification.hints !== undefined ? notification.hints : ({});
        var desktopEntryValue = _extractDesktopEntry(notification, hintsValue);

        var normalized = {
            id: _safeNumber(recordId, _safeNumber(notification.id, 0)),
            appName: _safeString(notification.appName),
            appIcon: appIconValue,
            appIconHint: _mediaSourceHint(appIconValue),
            summary: _safeString(notification.summary),
            body: _safeString(notification.body),
            image: imageValue,
            imageHint: _mediaSourceHint(imageValue),
            urgency: _urgencyToString(notification.urgency),
            actions: actionsValue,
            actionCount: actionsValue.length,
            resident: _safeBool(notification.resident, false),
            transient: _safeBool(notification.transient, false),
            expireTimeout: _safeNumber(notification.expireTimeout, -1),
            receivedAt: _safeNumber(receivedAt, Date.now()),
            timeLabel: NotificationTime.shortRelativeLabel(receivedAt, Date.now()),
            isPopup: true,
            inHistory: false,
            lastGeneration: _safeBool(notification.lastGeneration, false),
            desktopEntry: desktopEntryValue,
            hints: hintsValue
        };

        // Keep app identity icon, right-side IM avatar, and large preview as separate roles.
        var mediaRoles = _classifyMediaRoles(normalized);
        normalized.resolvedAppIconSource = mediaRoles.resolvedAppIconSource;
        normalized.resolvedAppIconHint = mediaRoles.resolvedAppIconHint;
        normalized.rightSideImageSource = mediaRoles.rightSideImageSource;
        normalized.contentPreviewImageSource = mediaRoles.contentPreviewImageSource;
        normalized.mediaCategory = mediaRoles.category;

        return normalized;
    }

    function _extractDesktopEntry(notification, hintsValue) {
        var candidates = [notification ? notification.desktopEntry : "", notification ? notification.desktopentry : "", notification ? notification.desktop_entry : "", _hintStringValue(hintsValue, "desktop-entry"), _hintStringValue(hintsValue, "desktop_entry"), _hintStringValue(hintsValue, "desktopEntry")];
        var i = 0;
        for (i = 0; i < candidates.length; i++) {
            var text = _safeString(candidates[i]).trim();
            if (text.length > 0) {
                return text;
            }
        }

        return "";
    }

    function _extractReplacementId(notification) {
        if (!notification) {
            return -1;
        }

        var candidates = [notification.replacesId, notification.replacesID, notification.replaceId, notification.replaceID, notification.replacedId, notification.replacedID, notification.replaces, notification.replaced, notification.replaces_id, notification.replaced_id];
        var i = 0;
        for (i = 0; i < candidates.length; i++) {
            var value = _safeNumber(candidates[i], -1);
            if (value > 0) {
                return value;
            }
        }

        return -1;
    }

    function _resolveRecordIdKey(incomingId, replacesId) {
        var incomingKey = _idKey(incomingId);
        if (_hasOwn(_byId, incomingKey)) {
            return incomingKey;
        }

        if (replacesId <= 0) {
            return incomingKey;
        }

        var replaceKey = _idKey(replacesId);
        if (_hasOwn(_byId, replaceKey)) {
            return replaceKey;
        }

        return incomingKey;
    }

    function _normalizeActions(notification) {
        var normalized = [];
        var sourceActions = notification && notification.actions ? notification.actions : [];
        var count = _listLikeLength(sourceActions);
        var i = 0;

        for (i = 0; i < count; i++) {
            var action = sourceActions[i];
            if (!action) {
                continue;
            }

            normalized.push({
                id: _actionIdentifier(action),
                text: _safeString(action.text)
            });
        }

        return normalized;
    }

    function _findSourceAction(notification, actionId) {
        if (!notification) {
            return null;
        }

        var expected = _safeString(actionId);
        var sourceActions = notification.actions ? notification.actions : [];
        var count = _listLikeLength(sourceActions);
        var i = 0;

        for (i = 0; i < count; i++) {
            var action = sourceActions[i];
            if (!action) {
                continue;
            }

            if (_actionIdentifier(action) === expected) {
                return action;
            }
        }

        return null;
    }

    function _enforceLimits() {
        _enforceActiveLimit();
        _enforceHistoryLimit();
    }

    function _enforceActiveLimit() {
        while (activeListModel.count > Math.max(0, maxActive)) {
            var row = activeListModel.get(0);
            var rowId = _modelRowId(row);
            activeListModel.remove(0);
            if (_safeNumber(rowId, -1) < 0) {
                _debug("dropped popup row with invalid id due maxActive=" + maxActive + " row=" + _debugValuePreview(row));
                continue;
            }

            var idKey = _idKey(rowId);
            if (_hasOwn(_metadataById, idKey)) {
                _metadataById[idKey].popupVisible = false;
                _metadataById[idKey].expiresAt = -1;
                _metadataById[idKey].closeReason = "DroppedActiveLimit";
                _metadataById[idKey].revision = _safeNumber(_metadataById[idKey].revision, 0) + 1;
                _upsertHistoryRow(idKey);
                _dropStateIfUnreferenced(idKey);
            }

            _debug("dropped popup id=" + rowId + " due maxActive=" + maxActive);
        }
    }

    function _enforceHistoryLimit() {
        while (historyListModel.count > Math.max(0, maxHistory)) {
            var lastIndex = historyListModel.count - 1;
            var row = historyListModel.get(lastIndex);
            var rowId = _modelRowId(row);
            historyListModel.remove(lastIndex);
            var idKey = _idKey(rowId);
            if (_hasOwn(_metadataById, idKey)) {
                _metadataById[idKey].inHistory = false;
                _dropStateIfUnreferenced(idKey);
            }

            _debug("dropped history id=" + rowId + " due maxHistory=" + maxHistory);
        }
    }

    function _upsertActiveRow(idKey) {
        if (!_hasOwn(_byId, idKey) || !_hasOwn(_metadataById, idKey)) {
            return;
        }

        var record = _byId[idKey];
        var metadata = _metadataById[idKey];
        if (!metadata.popupVisible) {
            _removeModelRowById(activeListModel, record.id);
            return;
        }

        var row = _toModelRow(record, metadata, true);
        var existingIndex = _findModelIndexById(activeListModel, row.notificationId);
        _upsertModelRow(activeListModel, row);

        if (debugActiveRowUpdates) {
            _debugActiveRow(existingIndex < 0 ? "append" : "update", row);
        }
    }

    function _upsertHistoryRow(idKey) {
        if (!_hasOwn(_byId, idKey) || !_hasOwn(_metadataById, idKey)) {
            return;
        }

        var record = _byId[idKey];
        var metadata = _metadataById[idKey];

        if (!metadata.inHistory) {
            _removeModelRowById(historyListModel, record.id);
            return;
        }

        var row = _toModelRow(record, metadata, false);
        var existingIndex = _findModelIndexById(historyListModel, row.notificationId);

        if (existingIndex === 0) {
            historyListModel.set(0, row);
            return;
        }

        if (existingIndex > 0) {
            historyListModel.remove(existingIndex);
        }

        historyListModel.insert(0, row);
    }

    function _toModelRow(record, metadata, popupRow) {
        var actionCount = _safeNumber(record.actionCount, _copyActions(record.actions).length);
        // Keep ListModel rows primitive-only; rich variants stay in _byId and are fetched by id in delegates.
        return {
            notificationId: record.id,
            appName: record.appName,
            appIconHint: _safeString(record.appIconHint),
            resolvedAppIconHint: _safeString(record.resolvedAppIconHint),
            summary: record.summary,
            body: record.body,
            imageHint: _safeString(record.imageHint),
            rightSideImageSource: _safeString(record.rightSideImageSource),
            contentPreviewImageSource: _safeString(record.contentPreviewImageSource),
            mediaCategory: _safeString(record.mediaCategory),
            urgency: record.urgency,
            actionCount: actionCount,
            hasActions: actionCount > 0,
            resident: record.resident,
            transient: record.transient,
            expireTimeout: record.expireTimeout,
            receivedAt: metadata.receivedAt,
            timeLabel: NotificationTime.shortRelativeLabel(metadata.receivedAt, Date.now()),
            isPopup: popupRow && metadata.popupVisible,
            inHistory: metadata.inHistory,
            lastGeneration: record.lastGeneration,
            desktopEntry: record.desktopEntry,
            hasImage: _safeString(record.imageHint).length > 0,
            revision: _safeNumber(metadata.revision, 0)
        };
    }

    function _copyActions(sourceActions) {
        var copied = [];
        var actions = sourceActions || [];
        var i = 0;

        for (i = 0; i < _listLikeLength(actions); i++) {
            var action = actions[i];
            if (!action) {
                continue;
            }

            copied.push({
                id: _safeString(action.id),
                text: _safeString(action.text)
            });
        }

        return copied;
    }

    function _listLikeLength(value) {
        if (!value) {
            return 0;
        }

        var lengthValue = _safeNumber(value.length, -1);
        if (lengthValue >= 0) {
            return Math.floor(lengthValue);
        }

        var countValue = _safeNumber(value.count, -1);
        if (countValue >= 0) {
            return Math.floor(countValue);
        }

        return 0;
    }

    function _actionIdentifier(action) {
        if (!action) {
            return "";
        }

        if (action.identifier !== undefined && action.identifier !== null) {
            return _safeString(action.identifier);
        }

        return _safeString(action.id);
    }

    function _normalizeMediaValue(value) {
        if (value === undefined || value === null) {
            return "";
        }

        if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
            return value;
        }

        return value;
    }

    function _mediaSourceHint(value) {
        if (value === undefined || value === null) {
            return "";
        }

        if (typeof value === "string" || typeof value === "number" || typeof value === "boolean") {
            return _safeString(value).trim();
        }

        if (typeof value === "object") {
            var candidateKeys = ["source", "path", "url", "name", "icon", "iconName"];
            var i = 0;
            for (i = 0; i < candidateKeys.length; i++) {
                var key = candidateKeys[i];
                if (!_hasOwn(value, key)) {
                    continue;
                }

                var candidateText = _safeString(value[key]).trim();
                if (candidateText.length > 0) {
                    return candidateText;
                }
            }
        }

        var fallbackText = _safeString(value).trim();
        if (fallbackText === "[object Object]") {
            return "";
        }

        return fallbackText;
    }

    function _hintStringValue(hints, key) {
        if (!hints || typeof hints !== "object" || !_hasOwn(hints, key)) {
            return "";
        }

        return _safeString(hints[key]).trim();
    }

    function _notificationCategory(hints) {
        var candidates = [_hintStringValue(hints, "category"), _hintStringValue(hints, "Category"), _hintStringValue(hints, "x-category"), _hintStringValue(hints, "x_category")];
        var i = 0;
        for (i = 0; i < candidates.length; i++) {
            var candidate = _safeString(candidates[i]).trim();
            if (candidate.length > 0) {
                return candidate.toLowerCase();
            }
        }

        return "";
    }

    function _classifyMediaRoles(record) {
        var category = _notificationCategory(record ? record.hints : null);
        var resolvedAppIconSource = record ? record.appIcon : "";
        var resolvedAppIconHint = _safeString(record ? record.appIconHint : "").trim();
        var imageHint = _safeString(record ? record.imageHint : "").trim();
        var imageAsIcon = imageHint.indexOf("image://icon/") === 0;
        var rightSideImageSource = "";
        var contentPreviewImageSource = "";

        if (resolvedAppIconHint.length === 0) {
            var desktopEntryIcon = _resolveAppIconFromDesktopEntry(record ? record.desktopEntry : "");
            if (desktopEntryIcon.length > 0) {
                resolvedAppIconSource = desktopEntryIcon;
                resolvedAppIconHint = desktopEntryIcon;
            }
        }

        if (resolvedAppIconHint.length > 0 && _looksLikeDesktopEntryValue(resolvedAppIconHint)) {
            var canonicalDesktopIcon = _resolveAppIconFromDesktopEntry(resolvedAppIconHint);
            if (canonicalDesktopIcon.length > 0) {
                resolvedAppIconSource = canonicalDesktopIcon;
                resolvedAppIconHint = canonicalDesktopIcon;
            }
        }

        // Some sources encode the app icon in notification.image as image://icon/... .
        if (resolvedAppIconHint.length === 0 && imageAsIcon) {
            resolvedAppIconSource = imageHint;
            resolvedAppIconHint = imageHint;
            imageHint = "";
        }

        if (imageHint.length > 0) {
            if (category === "im.received") {
                // IM notifications prefer compact right-side avatars over large previews.
                rightSideImageSource = imageHint;
            } else {
                contentPreviewImageSource = imageHint;
            }
        }

        // Duplicate suppression: icon identity wins, and only one image slot is shown.
        var iconKey = _normalizeMediaCompareKey(resolvedAppIconHint);
        var rightKey = _normalizeMediaCompareKey(rightSideImageSource);
        var previewKey = _normalizeMediaCompareKey(contentPreviewImageSource);

        if (rightKey.length > 0 && rightKey === iconKey) {
            rightSideImageSource = "";
            rightKey = "";
        }

        if (previewKey.length > 0 && previewKey === iconKey) {
            contentPreviewImageSource = "";
            previewKey = "";
        }

        if (rightKey.length > 0 && previewKey.length > 0) {
            contentPreviewImageSource = "";
        }

        return {
            resolvedAppIconSource: resolvedAppIconSource,
            resolvedAppIconHint: resolvedAppIconHint,
            rightSideImageSource: rightSideImageSource,
            contentPreviewImageSource: contentPreviewImageSource,
            category: category
        };
    }

    function _resolveAppIconFromDesktopEntry(desktopEntry) {
        var candidates = _desktopEntryIconCandidates(desktopEntry);
        if (candidates.length === 0) {
            return "";
        }

        return _toIconProviderSource(candidates[0]);
    }

    function _desktopEntryIconCandidates(desktopEntry) {
        var candidates = [];
        var text = _safeString(desktopEntry).trim();
        if (text.length === 0) {
            return candidates;
        }

        var name = text;
        if (name.indexOf("/") >= 0) {
            var parts = name.split("/");
            name = parts[parts.length - 1];
        }

        if (name.toLowerCase().slice(-8) === ".desktop") {
            name = name.slice(0, -8);
        }

        if (name.length === 0) {
            return candidates;
        }

        var nameLower = name.toLowerCase();
        if (nameLower.indexOf("telegram") >= 0) {
            _pushUniqueMediaCandidate(candidates, "telegram");
            _pushUniqueMediaCandidate(candidates, "telegram-desktop");
        }

        _pushUniqueMediaCandidate(candidates, name);
        _pushUniqueMediaCandidate(candidates, nameLower);
        _pushUniqueMediaCandidate(candidates, name.replace(/\./g, "-"));
        _pushUniqueMediaCandidate(candidates, nameLower.replace(/\./g, "-"));

        var segments = nameLower.split(".");
        if (segments.length > 0) {
            _pushUniqueMediaCandidate(candidates, segments[segments.length - 1]);
        }
        if (segments.length > 1) {
            _pushUniqueMediaCandidate(candidates, segments[segments.length - 2] + "-" + segments[segments.length - 1]);
        }

        return candidates;
    }

    function _pushUniqueMediaCandidate(candidates, value) {
        var candidate = _safeString(value).trim();
        if (candidate.length === 0) {
            return;
        }

        var i = 0;
        for (i = 0; i < candidates.length; i++) {
            if (_safeString(candidates[i]).toLowerCase() === candidate.toLowerCase()) {
                return;
            }
        }

        candidates.push(candidate);
    }

    function _looksLikeDesktopEntryValue(value) {
        var text = _safeString(value).trim();
        if (text.length === 0) {
            return false;
        }

        if (text.indexOf("/") >= 0 || text.indexOf(":") >= 0) {
            return false;
        }

        var lower = text.toLowerCase();
        if (lower.slice(-8) === ".desktop") {
            return true;
        }

        return text.indexOf(".") >= 0;
    }

    function _toIconProviderSource(iconName) {
        var icon = _safeString(iconName).trim();
        if (icon.length === 0) {
            return "";
        }

        if (icon.indexOf("image://") === 0 || icon.indexOf("/") === 0 || icon.indexOf("file://") === 0 || icon.indexOf("qrc:/") === 0 || icon.indexOf(":/") === 0) {
            return icon;
        }

        return "image://icon/" + icon;
    }

    function _normalizeMediaCompareKey(value) {
        var key = _safeString(value).trim();
        if (key.length === 0) {
            return "";
        }

        if (key.indexOf("file://") === 0) {
            key = key.slice(7);
        }

        return key.toLowerCase();
    }

    function _debugReceiveDecision(incomingId, replacesId, canonicalId, existed) {
        _debug("receive decision incomingId=" + incomingId + " replaceId=" + (replacesId > 0 ? replacesId : "none") + " canonicalId=" + canonicalId + " mode=" + (existed ? "update" : "insert"));
    }

    function _debugMediaFields(incomingId, record) {
        if (!debugLogging) {
            return;
        }

        if (_debugMediaLogsEmitted >= Math.max(0, debugMediaLogLimit)) {
            return;
        }
        _debugMediaLogsEmitted += 1;

        _debug("media sample incomingId=" + incomingId + " recordId=" + _safeString(record && record.id !== undefined ? record.id : "") + " appIconType=" + _valueType(record ? record.appIcon : undefined) + " appIconHint=\"" + _mediaSourceHint(record ? record.appIcon : undefined) + "\"" + " appIconValue=" + _debugValuePreview(record ? record.appIcon : undefined) + " imageType=" + _valueType(record ? record.image : undefined) + " imageHint=\"" + _mediaSourceHint(record ? record.image : undefined) + "\"" + " imageValue=" + _debugValuePreview(record ? record.image : undefined));
        _debug("media decision incomingId=" + incomingId + " desktopEntry=\"" + _trimForDebug(_safeString(record ? record.desktopEntry : "")) + "\"" + " category=\"" + _trimForDebug(_safeString(record ? record.mediaCategory : "")) + "\"" + " resolvedAppIcon=\"" + _trimForDebug(_safeString(record ? record.resolvedAppIconHint : "")) + "\"" + " rightSideImage=\"" + _trimForDebug(_safeString(record ? record.rightSideImageSource : "")) + "\"" + " contentPreviewImage=\"" + _trimForDebug(_safeString(record ? record.contentPreviewImageSource : "")) + "\"");
        _debug("media hints incomingId=" + incomingId + " hints=" + _debugValuePreview(record ? record.hints : undefined));
    }

    function _valueType(value) {
        if (value === undefined) {
            return "undefined";
        }
        if (value === null) {
            return "null";
        }
        if (Array.isArray(value)) {
            return "array";
        }
        return typeof value;
    }

    function _debugValuePreview(value) {
        if (value === undefined) {
            return "undefined";
        }
        if (value === null) {
            return "null";
        }

        if (typeof value === "string") {
            return "\"" + _trimForDebug(value) + "\"";
        }
        if (typeof value === "number" || typeof value === "boolean") {
            return _safeString(value);
        }
        if (Array.isArray(value)) {
            return "array(len=" + value.length + ")";
        }

        if (typeof value === "object") {
            var parts = [];
            var key = "";
            for (key in value) {
                if (!_hasOwn(value, key)) {
                    continue;
                }
                parts.push(key + "=" + _trimForDebug(_safeString(value[key])));
                if (parts.length >= 4) {
                    break;
                }
            }
            if (parts.length > 0) {
                return "{" + parts.join(",") + "}";
            }
        }

        return _trimForDebug(_safeString(value));
    }

    function _trimForDebug(value) {
        var text = _safeString(value);
        if (text.length <= 80) {
            return text;
        }
        return text.slice(0, 77) + "...";
    }

    function _upsertModelRow(model, row) {
        var index = _findModelIndexById(model, row.notificationId);
        if (index < 0) {
            model.append(row);
            return;
        }

        model.set(index, row);
    }

    function _removeModelRowById(model, id) {
        var index = _findModelIndexById(model, id);
        if (index < 0) {
            return false;
        }

        model.remove(index);
        return true;
    }

    function _findModelIndexById(model, id) {
        var i = 0;
        for (i = 0; i < model.count; i++) {
            if (_safeNumber(_modelRowId(model.get(i)), -1) === _safeNumber(id, -2)) {
                return i;
            }
        }
        return -1;
    }

    function _modelRowId(row) {
        if (!row) {
            return -1;
        }

        if (row.notificationId !== undefined && row.notificationId !== null) {
            return row.notificationId;
        }

        if (row.id !== undefined && row.id !== null) {
            // Legacy compatibility for rows created before the notificationId role migration.
            return row.id;
        }

        return -1;
    }

    function _dropStateIfUnreferenced(idKey) {
        if (!_hasOwn(_metadataById, idKey)) {
            return;
        }

        var metadata = _metadataById[idKey];
        if (metadata.popupVisible || metadata.inHistory) {
            return;
        }

        delete _byId[idKey];
        delete _metadataById[idKey];
        delete _sourceById[idKey];
        delete _sourceTokenById[idKey];
    }

    function _refreshModelTimeLabels(model) {
        var now = Date.now();
        var i = 0;

        for (i = 0; i < model.count; i++) {
            var row = model.get(i);
            var nextLabel = NotificationTime.shortRelativeLabel(row.receivedAt, now);
            if (row.timeLabel !== nextLabel) {
                model.setProperty(i, "timeLabel", nextLabel);
            }
        }
    }

    function _computeExpiresAt(expireTimeoutMs, receivedAt, resident) {
        // Resident notifications stay until explicitly dismissed by the source or user.
        if (resident) {
            return -1;
        }

        var timeoutMs = _safeNumber(expireTimeoutMs, -1);
        if (timeoutMs > 0) {
            return _safeNumber(receivedAt, Date.now()) + Math.round(timeoutMs);
        }

        // 0 means explicitly persistent.
        if (timeoutMs === 0) {
            return -1;
        }

        // < 0 means "server default"; apply local popup fallback.
        var fallbackTimeoutMs = Math.max(0, _safeNumber(defaultPopupTimeoutMs, 0));
        if (fallbackTimeoutMs <= 0) {
            return -1;
        }

        return _safeNumber(receivedAt, Date.now()) + fallbackTimeoutMs;
    }

    function _urgencyToString(value) {
        try {
            return _safeString(NotificationUrgency.toString(value));
        } catch (error) {
            return _safeString(value);
        }
    }

    function _closeReasonToString(value) {
        try {
            return _safeString(NotificationCloseReason.toString(value));
        } catch (error) {
            return _safeString(value);
        }
    }

    function _idKey(value) {
        return _safeString(value);
    }

    function _hasOwn(objectValue, key) {
        return Object.prototype.hasOwnProperty.call(objectValue, key);
    }

    function _safeString(value) {
        if (value === undefined || value === null) {
            return "";
        }
        return String(value);
    }

    function _safeNumber(value, fallbackValue) {
        var numeric = Number(value);
        if (!isFinite(numeric)) {
            return fallbackValue;
        }
        return numeric;
    }

    function _safeBool(value, fallbackValue) {
        if (value === undefined || value === null) {
            return fallbackValue;
        }
        return !!value;
    }

    function _debug(message) {
        if (!debugLogging) {
            return;
        }

        console.log("[NotificationService] " + message);
    }

    function _debugActiveRow(action, row) {
        var summaryText = _safeString(row && row.summary !== undefined ? row.summary : "");
        var appNameText = _safeString(row && row.appName !== undefined ? row.appName : "");
        var bodyText = _safeString(row && row.body !== undefined ? row.body : "");
        console.log("[NotificationService] active-row " + _safeString(action) + " id=" + _safeString(_modelRowId(row)) + " app=\"" + appNameText + "\"" + " summary=\"" + summaryText + "\"" + " bodyLen=" + bodyText.length);
    }
}
