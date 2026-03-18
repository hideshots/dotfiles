import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: root

    property var screenStates: ({})
    property var screenRefs: ({})
    property var queuedInternalRefreshKeys: []
    property var pendingWriteOrder: []
    property var pendingWrites: ({})

    property var ddcBusByConnectorOverride: ({})
    property bool ddcAutoDetectEnabled: true
    property int ddcAutoDetectDelayMs: 1800

    property var cachedDdcBusByConnector: ({})
    property var cachedBrightnessByConnector: ({})
    property bool cacheLoaded: false
    property bool ddcBackendAvailable: true

    property string cacheHomePath: Quickshell.cacheDir
    readonly property string cacheFilePath: Quickshell.cachePath("control-center-ddc.json")

    property string activeDetectFingerprint: ""
    property string lastDetectFingerprint: ""
    property string pendingDetectFingerprint: ""

    property string activeBacklightResolveKey: ""
    property string activeBacklightReadKey: ""
    property string activeWriteKey: ""

    property string activeWriteBackend: "none"
    property real activeWriteValue: 0.0
    property bool activeWriteFailed: false
    property string activeWriteErrorText: ""
    property int activeBacklightCurrent: -1
    property int activeBacklightMax: -1

    property var ddcDetectOutputLines: []
    property var backlightResolveOutputLines: []
    property var backlightReadCurrentOutputLines: []
    property var backlightReadMaxOutputLines: []
    readonly property string watchedBacklightDevice: root._resolvedWatchedBacklightDevice()
    readonly property string watchedBacklightPath: root.watchedBacklightDevice.length > 0 ? "/sys/class/backlight/" + root.watchedBacklightDevice + "/brightness" : ""

    function _defaultState() {
        return {
            available: false,
            value: 0.5,
            backend: "none",
            detailText: "",
            busy: false,
            maxValue: 100,
            ddcBus: -1,
            backlightDevice: "",
            trackingMode: "none",
            mappingSource: "none"
        };
    }

    function _screenKey(screen) {
        if (!screen || screen.name === undefined || screen.name === null) {
            return "";
        }

        return String(screen.name);
    }

    function _registerScreen(screen) {
        var key = _screenKey(screen);
        if (key.length === 0) {
            return "";
        }

        var nextRefs = Object.assign({}, root.screenRefs);
        nextRefs[key] = screen;
        root.screenRefs = nextRefs;
        return key;
    }

    function _stateForKey(key) {
        if (key.length === 0) {
            return root._defaultState();
        }

        var existing = root.screenStates[key];
        if (!existing || typeof existing !== "object") {
            return root._defaultState();
        }

        return existing;
    }

    function _replaceState(key, nextState) {
        if (key.length === 0) {
            return;
        }

        var nextStates = Object.assign({}, root.screenStates);
        nextStates[key] = nextState;
        root.screenStates = nextStates;
    }

    function _patchState(key, patch) {
        if (key.length === 0) {
            return;
        }

        var nextState = Object.assign({}, root._stateForKey(key), patch);
        root._replaceState(key, nextState);
    }

    function _clearBusy(key) {
        root._patchState(key, {
            busy: false
        });
    }

    function _setUnavailable(key) {
        var current = root._stateForKey(key);
        root._replaceState(key, {
            available: false,
            value: current.value,
            backend: "none",
            detailText: "",
            busy: false,
            maxValue: 100,
            ddcBus: -1,
            backlightDevice: "",
            trackingMode: "none",
            mappingSource: "none"
        });
    }

    function _screenName(screen) {
        if (!screen || screen.name === undefined || screen.name === null) {
            return "";
        }

        return String(screen.name);
    }

    function _screenModel(screen) {
        if (!screen || screen.model === undefined || screen.model === null) {
            return "";
        }

        return String(screen.model).trim();
    }

    function _screenSerial(screen) {
        if (!screen || screen.serialNumber === undefined || screen.serialNumber === null) {
            return "";
        }

        return String(screen.serialNumber).trim();
    }

    function _hyprDescription(screen) {
        var monitor = Hyprland.monitorFor(screen);
        if (!monitor || monitor.description === undefined || monitor.description === null) {
            return "";
        }

        return String(monitor.description).trim();
    }

    function _normalizeText(value) {
        if (value === undefined || value === null) {
            return "";
        }

        return String(value).trim().toLowerCase();
    }

    function _normalizeConnector(value) {
        var normalized = root._normalizeText(value);
        normalized = normalized.replace(/^desc:/, "");
        return normalized.replace(/^card\d+-/, "");
    }

    function _isInternalScreen(screen) {
        var screenName = root._screenName(screen).toUpperCase();
        return screenName.indexOf("EDP") === 0 || screenName.indexOf("LVDS") === 0;
    }

    function _mapKeyForConnector(mapObject, connectorName) {
        if (!mapObject || typeof mapObject !== "object") {
            return "";
        }

        var target = root._normalizeConnector(connectorName);
        for (var key in mapObject) {
            if (root._normalizeConnector(key) === target) {
                return key;
            }
        }

        return "";
    }

    function _validBusValue(value) {
        var numeric = Number(value);
        return isFinite(numeric) && numeric >= 0 ? Math.round(numeric) : -1;
    }

    function _hasOverrideForConnector(connectorName) {
        return root._mapKeyForConnector(root.ddcBusByConnectorOverride, connectorName).length > 0;
    }

    function _overrideBusForConnector(connectorName) {
        var key = root._mapKeyForConnector(root.ddcBusByConnectorOverride, connectorName);
        return key.length > 0 ? root._validBusValue(root.ddcBusByConnectorOverride[key]) : -1;
    }

    function _cachedBusForConnector(connectorName) {
        var key = root._mapKeyForConnector(root.cachedDdcBusByConnector, connectorName);
        return key.length > 0 ? root._validBusValue(root.cachedDdcBusByConnector[key]) : -1;
    }

    function _resolvedDdcMappingForConnector(connectorName) {
        if (!root.ddcBackendAvailable) {
            return {
                available: false,
                bus: -1,
                source: "none"
            };
        }

        var overrideBus = root._overrideBusForConnector(connectorName);
        if (overrideBus >= 0) {
            return {
                available: true,
                bus: overrideBus,
                source: "override"
            };
        }

        var cachedBus = root._cachedBusForConnector(connectorName);
        if (cachedBus >= 0) {
            return {
                available: true,
                bus: cachedBus,
                source: "cache"
            };
        }

        return {
            available: false,
            bus: -1,
            source: "none"
        };
    }

    function _cachedBrightnessForConnector(connectorName) {
        var key = root._mapKeyForConnector(root.cachedBrightnessByConnector, connectorName);
        var cached = key.length > 0 ? Number(root.cachedBrightnessByConnector[key]) : 0.5;
        if (!isFinite(cached)) {
            return 0.5;
        }

        return Math.max(0, Math.min(1, cached));
    }

    function _setCachedBrightnessForConnector(connectorName, value) {
        if (connectorName.length === 0) {
            return;
        }

        var clamped = Math.max(0, Math.min(1, Number(value)));
        if (!isFinite(clamped)) {
            return;
        }

        var nextValues = Object.assign({}, root.cachedBrightnessByConnector);
        nextValues[connectorName] = clamped;
        root.cachedBrightnessByConnector = nextValues;
        cacheSaveDebounce.restart();
    }

    function _setCachedBusForConnector(connectorName, bus) {
        if (connectorName.length === 0) {
            return;
        }

        var numericBus = root._validBusValue(bus);
        if (numericBus < 0) {
            return;
        }

        var nextBuses = Object.assign({}, root.cachedDdcBusByConnector);
        nextBuses[connectorName] = numericBus;
        root.cachedDdcBusByConnector = nextBuses;
        cacheSaveDebounce.restart();
    }

    function _removeCachedBusForConnector(connectorName) {
        var existingKey = root._mapKeyForConnector(root.cachedDdcBusByConnector, connectorName);
        if (existingKey.length === 0) {
            return;
        }

        var nextBuses = Object.assign({}, root.cachedDdcBusByConnector);
        delete nextBuses[existingKey];
        root.cachedDdcBusByConnector = nextBuses;
        cacheSaveDebounce.restart();
    }

    function _saveCache() {
        var connectors = ({});
        var key = "";

        for (key in root.cachedBrightnessByConnector) {
            connectors[key] = {
                value: root._cachedBrightnessForConnector(key)
            };
        }

        for (key in root.cachedDdcBusByConnector) {
            var numericBus = root._validBusValue(root.cachedDdcBusByConnector[key]);
            if (numericBus < 0) {
                continue;
            }

            var existing = connectors[key];
            if (!existing || typeof existing !== "object") {
                existing = ({});
            }
            existing.bus = numericBus;
            connectors[key] = existing;
        }

        cacheFile.setText(JSON.stringify({
            version: 1,
            connectors: connectors
        }));
    }

    function _loadCache() {
        var cachedText = String(cacheFile.text() || "").trim();
        if (cachedText.length === 0) {
            root.cachedDdcBusByConnector = ({});
            root.cachedBrightnessByConnector = ({});
            root.cacheLoaded = true;
            return;
        }

        try {
            var parsed = JSON.parse(cachedText);
            var parsedConnectors = parsed && parsed.connectors && typeof parsed.connectors === "object" ? parsed.connectors : ({});
            var nextBuses = ({});
            var nextValues = ({});

            for (var key in parsedConnectors) {
                var entry = parsedConnectors[key];
                if (!entry || typeof entry !== "object") {
                    continue;
                }

                var bus = root._validBusValue(entry.bus);
                if (bus >= 0) {
                    nextBuses[key] = bus;
                }

                var value = Number(entry.value);
                if (isFinite(value)) {
                    nextValues[key] = Math.max(0, Math.min(1, value));
                }
            }

            root.cachedDdcBusByConnector = nextBuses;
            root.cachedBrightnessByConnector = nextValues;
        } catch (exception) {
            console.warn("Brightness cache read failed:", exception);
            root.cachedDdcBusByConnector = ({});
            root.cachedBrightnessByConnector = ({});
        }

        root.cacheLoaded = true;
    }

    function _joinLines(lines) {
        if (!Array.isArray(lines) || lines.length === 0) {
            return "";
        }

        return lines.join("\n").trim();
    }

    function _ddcutilContext(args) {
        return {
            command: ["ddcutil"].concat(args),
            environment: {
                "XDG_CACHE_HOME": root.cacheHomePath
            }
        };
    }

    function _looksLikeMissingCommand(text) {
        if (text === undefined || text === null) {
            return false;
        }

        var line = String(text).toLowerCase();
        return line.indexOf("not found") >= 0 || line.indexOf("no such file") >= 0;
    }

    function _looksLikePermissionError(text) {
        if (text === undefined || text === null) {
            return false;
        }

        var line = String(text).toLowerCase();
        return line.indexOf("permission denied") >= 0 || line.indexOf("operation not permitted") >= 0;
    }

    function _looksLikeNoDisplayError(text) {
        if (text === undefined || text === null) {
            return false;
        }

        var line = String(text).toLowerCase();
        return line.indexOf("no displays found") >= 0 || line.indexOf("no monitor detected") >= 0 || line.indexOf("display not found") >= 0 || line.indexOf("ddc communication failed") >= 0;
    }

    function _screenByNormalizedConnector() {
        var byConnector = ({});
        var screens = Quickshell.screens;
        if (!screens || screens.length === undefined) {
            return byConnector;
        }

        for (var i = 0; i < screens.length; i++) {
            var screen = screens[i];
            var connector = root._screenName(screen);
            if (connector.length === 0) {
                continue;
            }

            byConnector[root._normalizeConnector(connector)] = screen;
        }

        return byConnector;
    }

    function _currentExternalFingerprint() {
        var connectors = [];
        var screens = Quickshell.screens;
        if (!screens || screens.length === undefined) {
            return "";
        }

        for (var i = 0; i < screens.length; i++) {
            var screen = screens[i];
            if (root._isInternalScreen(screen)) {
                continue;
            }

            var connector = root._normalizeConnector(root._screenName(screen));
            if (connector.length > 0) {
                connectors.push(connector);
            }
        }

        connectors.sort();
        return connectors.join("|");
    }

    function _hasUnresolvedExternalScreens() {
        var screens = Quickshell.screens;
        if (!screens || screens.length === undefined) {
            return false;
        }

        for (var i = 0; i < screens.length; i++) {
            var screen = screens[i];
            if (root._isInternalScreen(screen)) {
                continue;
            }

            var mapping = root._resolvedDdcMappingForConnector(root._screenName(screen));
            if (!mapping.available) {
                return true;
            }
        }

        return false;
    }

    function _syncExternalStateForScreen(key, screen) {
        var connectorName = root._screenName(screen);
        var mapping = root._resolvedDdcMappingForConnector(connectorName);
        var cachedValue = root._cachedBrightnessForConnector(connectorName);

        if (!mapping.available) {
            root._replaceState(key, {
                available: false,
                value: cachedValue,
                backend: "none",
                detailText: "",
                busy: false,
                maxValue: 100,
                ddcBus: -1,
                backlightDevice: "",
                trackingMode: "none",
                mappingSource: "none"
            });
            return;
        }

        root._replaceState(key, {
            available: true,
            value: cachedValue,
            backend: "ddc",
            detailText: "DDC/CI",
            busy: false,
            maxValue: 100,
            ddcBus: mapping.bus,
            backlightDevice: "",
            trackingMode: "cached",
            mappingSource: mapping.source
        });
    }

    function _syncAllScreens() {
        if (!root.cacheLoaded) {
            return;
        }

        var screens = Quickshell.screens;
        if (!screens || screens.length === undefined) {
            return;
        }

        for (var i = 0; i < screens.length; i++) {
            var screen = screens[i];
            var key = root._registerScreen(screen);
            if (key.length === 0) {
                continue;
            }

            if (root._isInternalScreen(screen)) {
                root.refreshForScreen(screen);
            } else {
                root._syncExternalStateForScreen(key, screen);
            }
        }

        root._scheduleAutoDetectIfNeeded();
    }

    function _resolvedWatchedBacklightDevice() {
        var screens = Quickshell.screens;
        if (!screens || screens.length === undefined) {
            return "";
        }

        for (var i = 0; i < screens.length; i++) {
            var screen = screens[i];
            if (!screen || !root._isInternalScreen(screen)) {
                continue;
            }

            var state = root._stateForKey(root._screenKey(screen));
            if (state && state.backend === "backlight" && String(state.backlightDevice || "").length > 0) {
                return String(state.backlightDevice);
            }
        }

        return "";
    }

    function _applyWatchedBacklightValue(rawText) {
        var device = root.watchedBacklightDevice;
        var currentValue = Number(String(rawText || "").trim());
        var screens = Quickshell.screens;
        if (device.length === 0 || !isFinite(currentValue) || currentValue < 0 || !screens || screens.length === undefined) {
            return;
        }

        for (var i = 0; i < screens.length; i++) {
            var screen = screens[i];
            if (!screen || !root._isInternalScreen(screen)) {
                continue;
            }

            var key = root._screenKey(screen);
            var state = root._stateForKey(key);
            var maxValue = Number(state.maxValue);
            if (String(state.backlightDevice || "") !== device || !isFinite(maxValue) || maxValue <= 0) {
                continue;
            }

            root._replaceState(key, {
                available: true,
                value: Math.max(0, Math.min(1, currentValue / maxValue)),
                backend: "backlight",
                detailText: "Backlight",
                busy: state.busy,
                maxValue: maxValue,
                ddcBus: -1,
                backlightDevice: state.backlightDevice,
                trackingMode: "live",
                mappingSource: "backlight"
            });
        }
    }

    function _scheduleAutoDetectIfNeeded() {
        if (!root.cacheLoaded || !root.ddcAutoDetectEnabled || !root.ddcBackendAvailable) {
            return;
        }

        var fingerprint = root._currentExternalFingerprint();
        if (fingerprint.length === 0 || !root._hasUnresolvedExternalScreens()) {
            return;
        }

        if (ddcDetectProcess.running || detectDelayTimer.running) {
            root.pendingDetectFingerprint = fingerprint;
            return;
        }

        if (root.activeDetectFingerprint === fingerprint || root.lastDetectFingerprint === fingerprint) {
            return;
        }

        root.pendingDetectFingerprint = fingerprint;
        detectDelayTimer.restart();
    }

    function _parseDdcDetectOutput(output) {
        var displays = [];
        var lines = output.split(/\r?\n/);
        var current = null;

        for (var i = 0; i < lines.length; i++) {
            var line = String(lines[i]).trim();
            if (line.length === 0) {
                continue;
            }

            var displayMatch = line.match(/^Display\s+(\d+)/i);
            if (displayMatch) {
                current = {
                    displayNumber: Number(displayMatch[1]),
                    bus: -1,
                    connector: "",
                    mfg: "",
                    model: "",
                    serial: ""
                };
                displays.push(current);
                continue;
            }

            if (/^Invalid display$/i.test(line)) {
                current = null;
                continue;
            }

            if (!current) {
                continue;
            }

            var busMatch = line.match(/^I2C bus:\s*\/dev\/i2c-(\d+)/i);
            if (busMatch) {
                current.bus = Number(busMatch[1]);
                continue;
            }

            var connectorMatch = line.match(/^DRM connector:\s*(.+)$/i);
            if (connectorMatch) {
                current.connector = String(connectorMatch[1]).trim();
                continue;
            }

            var monitorMatch = line.match(/^Monitor:\s*(.*)$/i);
            if (monitorMatch) {
                var monitorInfo = String(monitorMatch[1]).trim();
                var taggedMatch = monitorInfo.match(/^([A-Za-z0-9_-]+):([^:]*)(?::(.*))?$/);
                if (taggedMatch) {
                    current.mfg = String(taggedMatch[1]).trim();
                    current.model = String(taggedMatch[2]).trim();
                    current.serial = taggedMatch[3] === undefined ? "" : String(taggedMatch[3]).trim();
                } else {
                    current.model = monitorInfo;
                }
            }
        }

        return displays.filter(function (display) {
            return display && isFinite(display.bus) && display.bus >= 0;
        });
    }

    function _matchDdcDisplayForScreen(screen, displays) {
        if (!screen || !Array.isArray(displays) || displays.length === 0) {
            return null;
        }

        var screenName = root._normalizeConnector(root._screenName(screen));
        var screenModel = root._normalizeText(root._screenModel(screen));
        var screenSerial = root._normalizeText(root._screenSerial(screen));
        var hyprDescription = root._normalizeText(root._hyprDescription(screen));
        var matches = [];
        var i = 0;

        for (i = 0; i < displays.length; i++) {
            var connector = root._normalizeConnector(displays[i].connector);
            if (connector.length > 0 && connector === screenName) {
                return displays[i];
            }
        }

        if (screenSerial.length > 0) {
            for (i = 0; i < displays.length; i++) {
                if (root._normalizeText(displays[i].serial) === screenSerial) {
                    return displays[i];
                }
            }
        }

        if (screenModel.length > 0) {
            for (i = 0; i < displays.length; i++) {
                var displayModel = root._normalizeText(displays[i].model);
                if (displayModel.length === 0 || displayModel !== screenModel) {
                    continue;
                }

                if (hyprDescription.indexOf(displayModel) >= 0) {
                    return displays[i];
                }

                matches.push(displays[i]);
            }
        }

        if (matches.length === 1) {
            return matches[0];
        }

        return null;
    }

    function _startAutoDetect() {
        if (!root.cacheLoaded || !root.ddcAutoDetectEnabled || !root.ddcBackendAvailable) {
            return;
        }

        var fingerprint = root.pendingDetectFingerprint.length > 0 ? root.pendingDetectFingerprint : root._currentExternalFingerprint();
        if (fingerprint.length === 0) {
            return;
        }

        if (!root._hasUnresolvedExternalScreens()) {
            return;
        }

        root.pendingDetectFingerprint = "";
        root.lastDetectFingerprint = fingerprint;
        root.activeDetectFingerprint = fingerprint;
        root.ddcDetectOutputLines = [];
        ddcDetectProcess.exec(root._ddcutilContext(["detect", "--brief"]));
    }

    function _enqueueInternalRefresh(key) {
        if (root.queuedInternalRefreshKeys.indexOf(key) < 0) {
            var nextKeys = root.queuedInternalRefreshKeys.slice();
            nextKeys.push(key);
            root.queuedInternalRefreshKeys = nextKeys;
        }

        if (!backlightResolveProcess.running) {
            root._startNextInternalRefresh();
        }
    }

    function _startNextInternalRefresh() {
        if (backlightResolveProcess.running || root.queuedInternalRefreshKeys.length === 0) {
            return;
        }

        var nextKey = root.queuedInternalRefreshKeys[0];
        root.activeBacklightResolveKey = nextKey;
        root.backlightResolveOutputLines = [];
        backlightResolveProcess.exec(["brightnessctl", "-l", "-m"]);
    }

    function _finishInternalRefreshQueue() {
        if (root.queuedInternalRefreshKeys.length === 0) {
            root.activeBacklightResolveKey = "";
            return;
        }

        var remaining = root.queuedInternalRefreshKeys.slice(1);
        root.queuedInternalRefreshKeys = remaining;
        root.activeBacklightResolveKey = "";

        if (remaining.length > 0) {
            root._startNextInternalRefresh();
        }
    }

    function _parseBacklightResolveOutput(output) {
        var lines = output.split(/\r?\n/);

        for (var i = 0; i < lines.length; i++) {
            var line = String(lines[i]).trim();
            if (line.length === 0) {
                continue;
            }

            var parts = line.split(",");
            if (parts.length < 2) {
                continue;
            }

            var device = String(parts[0]).trim();
            var deviceClass = root._normalizeText(parts[1]);
            if (root._normalizeText(device) === "backlight") {
                device = String(parts[1]).trim();
                deviceClass = "backlight";
            }
            if (device.length > 0 && deviceClass === "backlight") {
                return device;
            }
        }

        return "";
    }

    function _startBacklightRead(key, device) {
        root.activeBacklightReadKey = key;
        root.activeBacklightCurrent = -1;
        root.activeBacklightMax = -1;
        root.backlightReadCurrentOutputLines = [];
        root.backlightReadMaxOutputLines = [];
        backlightReadCurrentProcess.exec(["brightnessctl", "-d", device, "get"]);
    }

    function _maybeFinishBacklightRead() {
        if (root.activeBacklightReadKey.length === 0) {
            return;
        }

        if (backlightReadCurrentProcess.running || backlightReadMaxProcess.running) {
            return;
        }

        var key = root.activeBacklightReadKey;
        var currentState = root._stateForKey(key);

        if (!isFinite(root.activeBacklightCurrent) || !isFinite(root.activeBacklightMax) || root.activeBacklightMax <= 0) {
            root._setUnavailable(key);
            root.activeBacklightReadKey = "";
            root.activeBacklightCurrent = -1;
            root.activeBacklightMax = -1;
            return;
        }

        root._replaceState(key, {
            available: true,
            value: Math.max(0, Math.min(1, root.activeBacklightCurrent / root.activeBacklightMax)),
            backend: "backlight",
            detailText: "Backlight",
            busy: false,
            maxValue: root.activeBacklightMax,
            ddcBus: -1,
            backlightDevice: currentState.backlightDevice,
            trackingMode: "live",
            mappingSource: "backlight"
        });

        root.activeBacklightReadKey = "";
        root.activeBacklightCurrent = -1;
        root.activeBacklightMax = -1;
    }

    function _dequeuePendingWrite() {
        if (root.pendingWriteOrder.length === 0) {
            return null;
        }

        var nextOrder = root.pendingWriteOrder.slice();
        var key = nextOrder.shift();
        root.pendingWriteOrder = nextOrder;

        var pending = root.pendingWrites[key];
        var nextWrites = Object.assign({}, root.pendingWrites);
        delete nextWrites[key];
        root.pendingWrites = nextWrites;

        if (!pending || typeof pending !== "object") {
            return null;
        }

        pending.key = key;
        return pending;
    }

    function _recordWriteError(data) {
        var text = String(data || "").trim();
        if (text.length === 0) {
            return;
        }

        root.activeWriteFailed = true;
        root.activeWriteErrorText = text;

        if (root.activeWriteBackend === "ddc" && (root._looksLikeMissingCommand(text) || root._looksLikePermissionError(text))) {
            root.ddcBackendAvailable = false;
        }
    }

    function _startNextPendingWrite() {
        if (writeProcess.running) {
            return;
        }

        var nextPending = root._dequeuePendingWrite();
        if (!nextPending) {
            return;
        }

        var key = String(nextPending.key);
        var state = root._stateForKey(key);
        var clamped = Math.max(0, Math.min(1, Number(nextPending.value)));

        if (!isFinite(clamped) || !state.available) {
            root._clearBusy(key);
            root._startNextPendingWrite();
            return;
        }

        root.activeWriteKey = key;
        root.activeWriteBackend = String(nextPending.backend);
        root.activeWriteValue = clamped;
        root.activeWriteFailed = false;
        root.activeWriteErrorText = "";

        if (root.activeWriteBackend === "ddc") {
            var bus = Number(state.ddcBus);
            if (!isFinite(bus) || bus < 0) {
                root._setUnavailable(key);
                root.activeWriteKey = "";
                root.activeWriteBackend = "none";
                root.activeWriteValue = 0.0;
                root.activeWriteFailed = false;
                root.activeWriteErrorText = "";
                root._startNextPendingWrite();
                return;
            }

            var absoluteValue = Math.round(clamped * 100);
            writeProcess.exec(root._ddcutilContext(["--bus", String(bus), "--noverify", "setvcp", "10", String(Math.max(0, absoluteValue))]));
            return;
        }

        if (root.activeWriteBackend === "backlight") {
            var device = state.backlightDevice;
            if (device.length === 0) {
                root._setUnavailable(key);
                root.activeWriteKey = "";
                root.activeWriteBackend = "none";
                root.activeWriteValue = 0.0;
                root.activeWriteFailed = false;
                root.activeWriteErrorText = "";
                root._startNextPendingWrite();
                return;
            }

            writeProcess.exec(["brightnessctl", "-d", device, "set", Math.round(clamped * 100) + "%"]);
            return;
        }

        root._clearBusy(key);
        root.activeWriteKey = "";
        root.activeWriteBackend = "none";
        root.activeWriteValue = 0.0;
        root.activeWriteFailed = false;
        root.activeWriteErrorText = "";
        root._startNextPendingWrite();
    }

    function stateForScreen(screen) {
        var key = root._screenKey(screen);
        return root._stateForKey(key);
    }

    function shouldRefreshOnOpenForScreen(screen) {
        return root._isInternalScreen(screen);
    }

    function refreshForScreen(screen) {
        var key = root._registerScreen(screen);
        if (key.length === 0) {
            return;
        }

        if (root._isInternalScreen(screen)) {
            root._patchState(key, {
                busy: true
            });
            root._enqueueInternalRefresh(key);
            return;
        }

        root._syncExternalStateForScreen(key, screen);
        root._scheduleAutoDetectIfNeeded();
    }

    function setNormalizedValueForScreen(screen, nextValue) {
        var key = root._registerScreen(screen);
        if (key.length === 0) {
            return;
        }

        var current = root._stateForKey(key);
        if (!current.available) {
            return;
        }

        var clamped = Math.max(0, Math.min(1, Number(nextValue)));
        if (!isFinite(clamped)) {
            return;
        }

        root._patchState(key, {
            value: clamped,
            busy: true
        });

        var nextPending = Object.assign({}, root.pendingWrites);
        nextPending[key] = {
            backend: current.backend,
            value: clamped
        };
        root.pendingWrites = nextPending;

        if (root.pendingWriteOrder.indexOf(key) < 0) {
            var nextOrder = root.pendingWriteOrder.slice();
            nextOrder.push(key);
            root.pendingWriteOrder = nextOrder;
        }

        writeDebounce.interval = current.backend === "ddc" ? 260 : 90;
        writeDebounce.restart();
    }

    onDdcBusByConnectorOverrideChanged: {
        if (root.cacheLoaded) {
            root._syncAllScreens();
        }
    }
    onWatchedBacklightPathChanged: {
        if (root.watchedBacklightPath.length > 0) {
            watchedBacklightFile.reload();
        }
    }

    Component.onCompleted: {
        root._loadCache();
        root._syncAllScreens();
    }

    property Connections quickshellConnections: Connections {
        target: Quickshell
        ignoreUnknownSignals: true

        function onScreensChanged() {
            if (root.cacheLoaded) {
                root._syncAllScreens();
            }
        }
    }

    property FileView cacheFile: FileView {
        id: cacheFile
        path: root.cacheFilePath
        preload: true
        watchChanges: false
        blockLoading: true
        printErrors: false
        onSaveFailed: console.warn("Brightness cache write failed.")
    }

    property FileView watchedBacklightFile: FileView {
        id: watchedBacklightFile
        path: root.watchedBacklightPath
        preload: root.watchedBacklightPath.length > 0
        watchChanges: root.watchedBacklightPath.length > 0
        printErrors: false
        onLoaded: root._applyWatchedBacklightValue(watchedBacklightFile.text())
        onFileChanged: watchedBacklightFile.reload()
    }

    property Timer detectDelayTimer: Timer {
        id: detectDelayTimer
        interval: Math.max(0, root.ddcAutoDetectDelayMs)
        repeat: false
        onTriggered: root._startAutoDetect()
    }

    property Timer cacheSaveDebounce: Timer {
        id: cacheSaveDebounce
        interval: 250
        repeat: false
        onTriggered: root._saveCache()
    }

    property Process ddcDetectProcess: Process {
        id: ddcDetectProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root.ddcDetectOutputLines = root.ddcDetectOutputLines.concat([String(data)]);
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root.ddcDetectOutputLines = root.ddcDetectOutputLines.concat([String(data)]);
            }
        }

        onRunningChanged: {
            if (running) {
                return;
            }

            var output = root._joinLines(root.ddcDetectOutputLines);
            var activeFingerprint = root.activeDetectFingerprint;
            root.activeDetectFingerprint = "";

            if (root._looksLikeMissingCommand(output) || root._looksLikePermissionError(output)) {
                root.ddcBackendAvailable = false;
                root._syncAllScreens();
                return;
            }

            root.ddcBackendAvailable = true;
            var displays = root._parseDdcDetectOutput(output);
            var screens = Quickshell.screens;
            if (screens && screens.length !== undefined) {
                for (var i = 0; i < screens.length; i++) {
                    var screen = screens[i];
                    if (root._isInternalScreen(screen) || root._hasOverrideForConnector(root._screenName(screen))) {
                        continue;
                    }

                    var matchedDisplay = root._matchDdcDisplayForScreen(screen, displays);
                    if (!matchedDisplay) {
                        continue;
                    }

                    root._setCachedBusForConnector(root._screenName(screen), matchedDisplay.bus);
                }
            }

            if (activeFingerprint.length > 0) {
                root.lastDetectFingerprint = activeFingerprint;
            }

            root._syncAllScreens();
        }
    }

    property Process backlightResolveProcess: Process {
        id: backlightResolveProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root.backlightResolveOutputLines = root.backlightResolveOutputLines.concat([String(data)]);
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root.backlightResolveOutputLines = root.backlightResolveOutputLines.concat([String(data)]);
            }
        }

        onRunningChanged: {
            if (running) {
                return;
            }

            var key = root.activeBacklightResolveKey;
            var output = root._joinLines(root.backlightResolveOutputLines);
            var device = root._parseBacklightResolveOutput(output);

            if (key.length === 0) {
                root._finishInternalRefreshQueue();
                return;
            }

            if (root._looksLikeMissingCommand(output) || root._looksLikePermissionError(output)) {
                root._setUnavailable(key);
                root._finishInternalRefreshQueue();
                return;
            }

            if (device.length === 0) {
                root._setUnavailable(key);
                root._finishInternalRefreshQueue();
                return;
            }

            root._patchState(key, {
                backend: "backlight",
                detailText: "Backlight",
                backlightDevice: device,
                ddcBus: -1,
                trackingMode: "none",
                mappingSource: "backlight"
            });

            root._startBacklightRead(key, device);
            root._finishInternalRefreshQueue();
        }
    }

    property Process backlightReadCurrentProcess: Process {
        id: backlightReadCurrentProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root.backlightReadCurrentOutputLines = root.backlightReadCurrentOutputLines.concat([String(data)]);
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root.backlightReadCurrentOutputLines = root.backlightReadCurrentOutputLines.concat([String(data)]);
            }
        }

        onRunningChanged: {
            if (running) {
                return;
            }

            var key = root.activeBacklightReadKey;
            var output = root._joinLines(root.backlightReadCurrentOutputLines);
            if (key.length > 0 && (root._looksLikeMissingCommand(output) || root._looksLikePermissionError(output))) {
                root.activeBacklightReadKey = "";
                root.activeBacklightCurrent = -1;
                root.activeBacklightMax = -1;
                root._setUnavailable(key);
                return;
            }

            var parsed = Number(output);
            root.activeBacklightCurrent = isFinite(parsed) ? parsed : -1;

            if (key.length > 0) {
                var currentState = root._stateForKey(key);
                if (currentState.backlightDevice.length > 0) {
                    backlightReadMaxProcess.exec(["brightnessctl", "-d", currentState.backlightDevice, "max"]);
                    return;
                }
            }

            root._maybeFinishBacklightRead();
        }
    }

    property Process backlightReadMaxProcess: Process {
        id: backlightReadMaxProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root.backlightReadMaxOutputLines = root.backlightReadMaxOutputLines.concat([String(data)]);
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root.backlightReadMaxOutputLines = root.backlightReadMaxOutputLines.concat([String(data)]);
            }
        }

        onRunningChanged: {
            if (running) {
                return;
            }

            var key = root.activeBacklightReadKey;
            var output = root._joinLines(root.backlightReadMaxOutputLines);
            if (key.length > 0 && (root._looksLikeMissingCommand(output) || root._looksLikePermissionError(output))) {
                root.activeBacklightReadKey = "";
                root.activeBacklightCurrent = -1;
                root.activeBacklightMax = -1;
                root._setUnavailable(key);
                return;
            }

            var parsed = Number(output);
            root.activeBacklightMax = isFinite(parsed) ? parsed : -1;
            root._maybeFinishBacklightRead();
        }
    }

    property Process writeProcess: Process {
        id: writeProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root._recordWriteError(data);
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root._recordWriteError(data);
            }
        }

        onRunningChanged: {
            if (running) {
                return;
            }

            var key = root.activeWriteKey;
            var backend = root.activeWriteBackend;
            var writtenValue = root.activeWriteValue;
            var writeFailed = root.activeWriteFailed;
            var errorText = root.activeWriteErrorText;
            var screen = root.screenRefs[key];
            var hasQueuedReplacement = root.pendingWrites[key] !== undefined;

            root.activeWriteKey = "";
            root.activeWriteBackend = "none";
            root.activeWriteValue = 0.0;
            root.activeWriteFailed = false;
            root.activeWriteErrorText = "";

            if (key.length > 0) {
                if (!writeFailed) {
                    if (backend === "ddc") {
                        root._setCachedBrightnessForConnector(key, writtenValue);
                        if (screen) {
                            root._syncExternalStateForScreen(key, screen);
                        } else {
                            root._clearBusy(key);
                        }
                    } else if (screen) {
                        root.refreshForScreen(screen);
                    } else {
                        root._clearBusy(key);
                    }
                } else {
                    if (backend === "ddc") {
                        if (root._looksLikeNoDisplayError(errorText) && !root._hasOverrideForConnector(key)) {
                            root._removeCachedBusForConnector(key);
                        }

                        if (screen) {
                            root._syncExternalStateForScreen(key, screen);
                        } else {
                            root._setUnavailable(key);
                        }
                    } else {
                        root._setUnavailable(key);
                    }
                }

                if (hasQueuedReplacement) {
                    root._patchState(key, {
                        busy: true
                    });
                }
            }

            if (root.pendingWriteOrder.length > 0) {
                writeDebounce.restart();
            }
        }
    }

    property Timer writeDebounce: Timer {
        id: writeDebounce
        interval: 90
        repeat: false
        onTriggered: root._startNextPendingWrite()
    }
}
