pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool available: false
    property bool muted: false
    property real value: 0.0
    property bool monitorEnabled: true
    property bool backendAvailable: true

    readonly property int percent: Math.round(root.value * 100)
    readonly property int iconLevel: _iconLevelFromValue(root.value)
    readonly property bool sliderEnabled: backendAvailable && available
    readonly property bool visible: true
    readonly property string iconGlyph: (!backendAvailable || !available || muted) ? "􀊣" : "􀊩"
    readonly property string iconSvgName: (!backendAvailable || !available || muted) ? "speaker.slash.fill" : ("speaker.wave.3.fill." + String(iconLevel))

    readonly property var getVolumeCommand: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    readonly property var subscribeCommand: ["wpctl", "subscribe"]
    readonly property var setMuteOnCommand: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "1"]
    readonly property var setMuteOffCommand: ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"]

    function _clamp(nextValue) {
        var numeric = Number(nextValue);
        if (!isFinite(numeric)) {
            return 0;
        }
        return Math.max(0, Math.min(1, numeric));
    }

    function _iconLevelFromValue(nextValue) {
        var pct = Math.round(_clamp(nextValue) * 100);
        if (pct <= 0) {
            return 0;
        }
        if (pct <= 33) {
            return 1;
        }
        if (pct <= 66) {
            return 2;
        }
        return 3;
    }

    function _clearState() {
        root.available = false;
        root.muted = true;
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

    function setMuted(nextMuted) {
        if (!root.backendAvailable || setMuteProcess.running) {
            return;
        }

        setMuteProcess.exec(nextMuted ? root.setMuteOnCommand : root.setMuteOffCommand);
    }

    function setVolume(nextValue) {
        if (!root.backendAvailable || setVolumeProcess.running) {
            return;
        }

        var clamped = _clamp(nextValue);
        setVolumeProcess.exec(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", clamped.toFixed(4)]);

        if (root.muted && clamped > 0) {
            root.setMuted(false);
        }
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

    property Process setMuteProcess: Process {
        id: setMuteProcess
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
