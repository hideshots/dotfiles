import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool available: false
    property bool muted: false
    property real value: 0.0
    property bool monitorEnabled: true
    property bool backendAvailable: true

    readonly property var getVolumeCommand: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    readonly property var subscribeCommand: ["wpctl", "subscribe"]

    function _clamp(nextValue) {
        return Math.max(0, Math.min(1, Number(nextValue)));
    }

    function _clearState() {
        root.available = false;
        root.muted = false;
        root.value = 0.0;
    }

    function _setBackendUnavailable() {
        root.backendAvailable = false;
        root._clearState();
        restartTimer.stop();
        refreshDebounce.stop();
    }

    function _looksLikeMissingCommand(text) {
        if (text === undefined || text === null) {
            return false;
        }
        var line = String(text).toLowerCase();
        return line.indexOf("not found") >= 0 || line.indexOf("no such file") >= 0;
    }

    function _applyGetVolumeOutput(data) {
        var line = data === undefined || data === null ? "" : String(data).trim();
        if (line.length === 0) {
            root._clearState();
            return;
        }

        if (_looksLikeMissingCommand(line)) {
            _setBackendUnavailable();
            return;
        }

        var volumeMatch = line.match(/Volume:\s*([0-9]*\.?[0-9]+)/i);
        if (!volumeMatch) {
            if (line.toLowerCase().indexOf("no default sink") >= 0) {
                root._clearState();
            }
            return;
        }

        var parsedValue = Number(volumeMatch[1]);
        if (!isFinite(parsedValue)) {
            return;
        }

        root.available = true;
        root.value = _clamp(parsedValue);
        root.muted = line.indexOf("[MUTED]") >= 0;
    }

    function refresh() {
        if (!root.monitorEnabled || !root.backendAvailable || getVolumeProcess.running) {
            return;
        }

        getVolumeProcess.exec(root.getVolumeCommand);
    }

    function setVolume(nextValue) {
        if (!root.backendAvailable || setVolumeProcess.running) {
            return;
        }

        var clamped = _clamp(nextValue);
        setVolumeProcess.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", clamped.toFixed(4)]);
    }

    function _startSubscribe() {
        if (!root.monitorEnabled || !root.backendAvailable || subscribeProcess.running) {
            return;
        }

        subscribeProcess.exec(root.subscribeCommand);
    }

    onMonitorEnabledChanged: {
        if (!monitorEnabled) {
            restartTimer.stop();
            refreshDebounce.stop();
            _clearState();
            if (subscribeProcess.running) {
                subscribeProcess.signal(15);
            }
            return;
        }

        refresh();
        _startSubscribe();
    }

    Component.onCompleted: {
        refresh();
        _startSubscribe();
    }

    property Process getVolumeProcess: Process {
        id: getVolumeProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root._applyGetVolumeOutput(data);
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

    property Process setVolumeProcess: Process {
        id: setVolumeProcess
        onRunningChanged: {
            if (!running && root.monitorEnabled && root.backendAvailable) {
                root.refresh();
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

    property Process subscribeProcess: Process {
        id: subscribeProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                var line = data === undefined || data === null ? "" : String(data).trim();
                if (line.length === 0) {
                    return;
                }
                refreshDebounce.restart();
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

        onRunningChanged: {
            if (!running && root.monitorEnabled && root.backendAvailable) {
                restartTimer.restart();
            }
        }
    }

    property Timer refreshDebounce: Timer {
        id: refreshDebounce
        interval: 120
        repeat: false
        onTriggered: root.refresh()
    }

    property Timer restartTimer: Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: root._startSubscribe()
    }
}
