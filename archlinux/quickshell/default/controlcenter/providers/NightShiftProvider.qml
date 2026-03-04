import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool monitorEnabled: true
    property bool backendAvailable: true

    property bool enabled: false
    property int minTemperature: 1000
    property int maxTemperature: 6500
    property int defaultOnTemperature: 4500
    property int temperature: 4500

    readonly property var getTemperatureCommand: ["hyprctl", "hyprsunset", "temperature"]

    readonly property real normalizedValue: {
        var span = root.maxTemperature - root.minTemperature;
        if (span <= 0) {
            return 0;
        }

        return Math.max(0, Math.min(1, (root.temperature - root.minTemperature) / span));
    }

    property var _pendingCommands: []

    function _clampTemperature(nextTemp) {
        var parsed = Math.round(Number(nextTemp));
        if (!isFinite(parsed)) {
            parsed = root.defaultOnTemperature;
        }

        var lower = Math.min(root.minTemperature, root.maxTemperature);
        var upper = Math.max(root.minTemperature, root.maxTemperature);
        return Math.max(lower, Math.min(upper, parsed));
    }

    function _looksLikeMissingCommand(text) {
        if (text === undefined || text === null) {
            return false;
        }

        var line = String(text).toLowerCase();
        return line.indexOf("not found") >= 0 || line.indexOf("no such file") >= 0;
    }

    function _setBackendUnavailable() {
        root.backendAvailable = false;
        if (refreshStateProcess.running) {
            refreshStateProcess.signal(15);
        }
        applyDebounce.stop();
        root._pendingCommands = [];
    }

    function _temperatureCommand(temp) {
        return ["hyprctl", "hyprsunset", "temperature", String(root._clampTemperature(temp))];
    }

    function _identityCommand() {
        return ["hyprctl", "hyprsunset", "identity"];
    }

    function _enqueueOrRun(command) {
        if (!root.backendAvailable || !root.monitorEnabled || !command) {
            return;
        }

        if (applyProcess.running) {
            root._pendingCommands.push(command);
            return;
        }

        applyProcess.exec(command);
    }

    function _applyTemperatureNow() {
        root._enqueueOrRun(root._temperatureCommand(root.temperature));
    }

    function _applyIdentityNow() {
        root._enqueueOrRun(root._identityCommand());
    }

    function _applyDisableNow() {
        root._enqueueOrRun(root._temperatureCommand(root.maxTemperature));
        root._enqueueOrRun(root._identityCommand());
    }

    function _applyReadTemperatureOutput(data) {
        var line = data === undefined || data === null ? "" : String(data).trim();
        if (line.length === 0) {
            return;
        }

        if (_looksLikeMissingCommand(line)) {
            _setBackendUnavailable();
            return;
        }

        var parsed = Number(line);
        if (!isFinite(parsed)) {
            return;
        }

        var clampedTemperature = root._clampTemperature(parsed);
        root.temperature = clampedTemperature;
        root.enabled = clampedTemperature < root.maxTemperature;
    }

    function refreshFromBackend() {
        if (!root.monitorEnabled || !root.backendAvailable || refreshStateProcess.running) {
            return;
        }

        refreshStateProcess.exec(root.getTemperatureCommand);
    }

    function setEnabled(nextEnabled) {
        if (!root.backendAvailable) {
            return;
        }

        var enabledNext = !!nextEnabled;
        if (root.enabled === enabledNext) {
            return;
        }

        root.enabled = enabledNext;

        if (root.enabled) {
            applyDebounce.stop();
            if (root.temperature >= root.maxTemperature) {
                root.temperature = root._clampTemperature(root.defaultOnTemperature);
            }
            root._applyTemperatureNow();
            return;
        }

        applyDebounce.stop();
        root._applyDisableNow();
    }

    function setNormalizedValue(nextValue) {
        var normalized = Math.max(0, Math.min(1, Number(nextValue)));
        if (!isFinite(normalized)) {
            return;
        }

        var span = root.maxTemperature - root.minTemperature;
        var mappedTemperature = root.minTemperature + (span * normalized);
        var clampedTemperature = root._clampTemperature(mappedTemperature);

        if (root.temperature === clampedTemperature) {
            return;
        }

        root.temperature = clampedTemperature;

        if (root.enabled) {
            applyDebounce.restart();
        }
    }

    onDefaultOnTemperatureChanged: {
        root.defaultOnTemperature = root._clampTemperature(root.defaultOnTemperature);
    }

    onMinTemperatureChanged: {
        root.temperature = root._clampTemperature(root.temperature);
        root.defaultOnTemperature = root._clampTemperature(root.defaultOnTemperature);
    }

    onMaxTemperatureChanged: {
        root.temperature = root._clampTemperature(root.temperature);
        root.defaultOnTemperature = root._clampTemperature(root.defaultOnTemperature);
    }

    onMonitorEnabledChanged: {
        if (!monitorEnabled) {
            applyDebounce.stop();
            root._pendingCommands = [];
            if (applyProcess.running) {
                applyProcess.signal(15);
            }
            if (refreshStateProcess.running) {
                refreshStateProcess.signal(15);
            }
            return;
        }

        refreshFromBackend();
    }

    Component.onCompleted: {
        root.temperature = root._clampTemperature(root.defaultOnTemperature);
        root.defaultOnTemperature = root._clampTemperature(root.defaultOnTemperature);
        refreshFromBackend();
    }

    property Process refreshStateProcess: Process {
        id: refreshStateProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root._applyReadTemperatureOutput(data);
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                if (root._looksLikeMissingCommand(data)) {
                    root._setBackendUnavailable();
                }
            }
        }
    }

    property Process applyProcess: Process {
        id: applyProcess

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                if (root._looksLikeMissingCommand(data)) {
                    root._setBackendUnavailable();
                }
            }
        }

        onRunningChanged: {
            if (running || !root.monitorEnabled || !root.backendAvailable) {
                return;
            }

            if (!Array.isArray(root._pendingCommands) || root._pendingCommands.length === 0) {
                return;
            }

            var queued = root._pendingCommands.shift();
            applyProcess.exec(queued);
        }
    }

    property Timer applyDebounce: Timer {
        id: applyDebounce
        interval: 90
        repeat: false
        onTriggered: {
            if (!root.enabled) {
                return;
            }

            root._applyTemperatureNow();
        }
    }
}
