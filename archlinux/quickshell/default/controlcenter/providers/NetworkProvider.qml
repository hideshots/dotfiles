import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool available: false
    property bool enabled: false
    property bool connected: false
    property string ssid: ""
    property bool monitorEnabled: true
    property bool backendAvailable: true

    property bool _activeWifiFound: false

    readonly property var wifiStatusCommand: ["nmcli", "-t", "-f", "WIFI", "general", "status"]
    readonly property var activeConnectionCommand: ["nmcli", "-t", "-f", "TYPE,NAME", "connection", "show", "--active"]
    readonly property var monitorCommand: ["nmcli", "monitor"]
    readonly property var setWifiOnCommand: ["nmcli", "radio", "wifi", "on"]
    readonly property var setWifiOffCommand: ["nmcli", "radio", "wifi", "off"]

    function _clearState() {
        root.available = false;
        root.enabled = false;
        root.connected = false;
        root.ssid = "";
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
        root._clearState();
        refreshDebounce.stop();
        restartTimer.stop();
    }

    function _applyWifiStatusLine(data) {
        var line = data === undefined || data === null ? "" : String(data).trim().toLowerCase();
        if (line.length === 0) {
            return;
        }

        if (_looksLikeMissingCommand(line)) {
            _setBackendUnavailable();
            return;
        }

        if (line === "enabled") {
            root.available = true;
            root.enabled = true;
            return;
        }

        if (line === "disabled") {
            root.available = true;
            root.enabled = false;
            root.connected = false;
            root.ssid = "";
        }
    }

    function _applyActiveConnectionLine(data) {
        var line = data === undefined || data === null ? "" : String(data).trim();
        if (line.length === 0) {
            return;
        }

        if (_looksLikeMissingCommand(line)) {
            _setBackendUnavailable();
            return;
        }

        var parts = line.split(":");
        if (parts.length < 2) {
            return;
        }

        var type = String(parts[0]).trim().toLowerCase();
        if (type !== "wifi" && type !== "802-11-wireless") {
            return;
        }

        var name = parts.slice(1).join(":").trim();
        root._activeWifiFound = true;
        root.connected = true;
        root.ssid = name;
    }

    function refresh() {
        if (!root.monitorEnabled || !root.backendAvailable) {
            return;
        }

        if (!statusProcess.running) {
            statusProcess.exec(root.wifiStatusCommand);
        }

        if (!activeConnectionProcess.running) {
            root._activeWifiFound = false;
            root.connected = false;
            root.ssid = "";
            activeConnectionProcess.exec(root.activeConnectionCommand);
        }
    }

    function setEnabled(nextEnabled) {
        if (!root.backendAvailable || setWifiProcess.running) {
            return;
        }

        setWifiProcess.exec(nextEnabled ? root.setWifiOnCommand : root.setWifiOffCommand);
    }

    function _startMonitor() {
        if (!root.monitorEnabled || !root.backendAvailable || monitorProcess.running) {
            return;
        }

        monitorProcess.exec(root.monitorCommand);
    }

    onMonitorEnabledChanged: {
        if (!monitorEnabled) {
            refreshDebounce.stop();
            restartTimer.stop();
            _clearState();
            if (monitorProcess.running) {
                monitorProcess.signal(15);
            }
            return;
        }

        refresh();
        _startMonitor();
    }

    Component.onCompleted: {
        refresh();
        _startMonitor();
    }

    property Process statusProcess: Process {
        id: statusProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root._applyWifiStatusLine(data);
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

    property Process activeConnectionProcess: Process {
        id: activeConnectionProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root._applyActiveConnectionLine(data);
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

    property Process setWifiProcess: Process {
        id: setWifiProcess
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

    property Process monitorProcess: Process {
        id: monitorProcess

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
        onTriggered: root._startMonitor()
    }
}
