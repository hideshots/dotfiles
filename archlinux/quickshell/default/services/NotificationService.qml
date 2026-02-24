pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "NotificationTime.js" as NotificationTime

Singleton {
    id: root

    property int maxActive: 5
    property int maxHistory: 100
    property bool keepTransientInHistory: false
    property bool resetTimestampOnReplace: true
    property bool debugLogging: false

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
            summary: record.summary,
            body: record.body,
            image: record.image,
            urgency: record.urgency,
            actions: _copyActions(record.actions),
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
            ids.push(activeListModel.get(i).id);
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
            ids.push(historyListModel.get(i).id);
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

        var notificationId = _safeNumber(notification.id, -1);
        if (notificationId < 0) {
            _debug("dropped notification with invalid id");
            return;
        }

        var idKey = _idKey(notificationId);
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
            _debug("failed to set tracked=true id=" + notificationId + " error=" + error);
        }

        var record = _normalizeNotification(notification, receivedAt);
        var metadata = _metadataById[idKey] || ({});

        metadata.receivedAt = receivedAt;
        metadata.expiresAt = _computeExpiresAt(record.expireTimeout, receivedAt, record.resident);
        metadata.popupVisible = true;
        metadata.dismissed = false;
        metadata.expired = false;
        metadata.closeReason = "";
        metadata.sourceAlive = true;
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
        _upsertActiveRow(idKey);

        if (metadata.inHistory) {
            _upsertHistoryRow(idKey);
        } else {
            _removeModelRowById(historyListModel, record.id);
        }

        _enforceLimits();
        _debug((existed ? "updated" : "received") + " id=" + notificationId + " app=" + record.appName + " popupVisible=" + metadata.popupVisible + " inHistory=" + metadata.inHistory + " timeout=" + record.expireTimeout + " lastGeneration=" + record.lastGeneration);
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
        metadata.closeReason = reasonName;
        metadata.sourceAlive = sourceAlive;

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
            ids.push(activeListModel.get(i).id);
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

    function _normalizeNotification(notification, receivedAt) {
        return {
            id: _safeNumber(notification.id, 0),
            appName: _safeString(notification.appName),
            appIcon: _safeString(notification.appIcon),
            summary: _safeString(notification.summary),
            body: _safeString(notification.body),
            image: _safeString(notification.image),
            urgency: _urgencyToString(notification.urgency),
            actions: _normalizeActions(notification),
            resident: _safeBool(notification.resident, false),
            transient: _safeBool(notification.transient, false),
            expireTimeout: _safeNumber(notification.expireTimeout, 0),
            receivedAt: _safeNumber(receivedAt, Date.now()),
            timeLabel: NotificationTime.shortRelativeLabel(receivedAt, Date.now()),
            isPopup: true,
            inHistory: false,
            lastGeneration: _safeBool(notification.lastGeneration, false),
            desktopEntry: _safeString(notification.desktopEntry),
            hints: notification.hints !== undefined ? notification.hints : ({})
        };
    }

    function _normalizeActions(notification) {
        var normalized = [];
        var sourceActions = notification && notification.actions ? notification.actions : [];
        var count = sourceActions && sourceActions.length ? sourceActions.length : 0;
        var i = 0;

        for (i = 0; i < count; i++) {
            var action = sourceActions[i];
            if (!action) {
                continue;
            }

            normalized.push({
                id: _safeString(action.identifier),
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
        var count = sourceActions && sourceActions.length ? sourceActions.length : 0;
        var i = 0;

        for (i = 0; i < count; i++) {
            var action = sourceActions[i];
            if (!action) {
                continue;
            }

            if (_safeString(action.identifier) === expected) {
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
            activeListModel.remove(0);

            var idKey = _idKey(row.id);
            if (_hasOwn(_metadataById, idKey)) {
                _metadataById[idKey].popupVisible = false;
                _metadataById[idKey].expiresAt = -1;
                _metadataById[idKey].closeReason = "DroppedActiveLimit";
                _upsertHistoryRow(idKey);
                _dropStateIfUnreferenced(idKey);
            }

            _debug("dropped popup id=" + row.id + " due maxActive=" + maxActive);
        }
    }

    function _enforceHistoryLimit() {
        while (historyListModel.count > Math.max(0, maxHistory)) {
            var row = historyListModel.get(0);
            historyListModel.remove(0);

            var idKey = _idKey(row.id);
            if (_hasOwn(_metadataById, idKey)) {
                _metadataById[idKey].inHistory = false;
                _dropStateIfUnreferenced(idKey);
            }

            _debug("dropped history id=" + row.id + " due maxHistory=" + maxHistory);
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

        _upsertModelRow(activeListModel, _toModelRow(record, metadata, true));
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

        _upsertModelRow(historyListModel, _toModelRow(record, metadata, false));
    }

    function _toModelRow(record, metadata, popupRow) {
        return {
            id: record.id,
            appName: record.appName,
            appIcon: record.appIcon,
            summary: record.summary,
            body: record.body,
            image: record.image,
            urgency: record.urgency,
            actions: _copyActions(record.actions),
            resident: record.resident,
            transient: record.transient,
            expireTimeout: record.expireTimeout,
            receivedAt: metadata.receivedAt,
            timeLabel: NotificationTime.shortRelativeLabel(metadata.receivedAt, Date.now()),
            isPopup: popupRow && metadata.popupVisible,
            inHistory: metadata.inHistory,
            lastGeneration: record.lastGeneration,
            desktopEntry: record.desktopEntry,
            hints: record.hints
        };
    }

    function _copyActions(sourceActions) {
        var copied = [];
        var actions = sourceActions || [];
        var i = 0;

        for (i = 0; i < actions.length; i++) {
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

    function _upsertModelRow(model, row) {
        var index = _findModelIndexById(model, row.id);
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
            if (_safeNumber(model.get(i).id, -1) === _safeNumber(id, -2)) {
                return i;
            }
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

    function _computeExpiresAt(expireTimeoutSeconds, receivedAt, resident) {
        // Resident notifications stay until explicitly dismissed by the source or user.
        if (resident) {
            return -1;
        }

        var timeoutSeconds = _safeNumber(expireTimeoutSeconds, 0);
        if (timeoutSeconds <= 0) {
            return -1;
        }

        return _safeNumber(receivedAt, Date.now()) + Math.round(timeoutSeconds * 1000);
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
}
