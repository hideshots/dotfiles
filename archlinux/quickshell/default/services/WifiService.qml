pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool available: false
    property bool enabled: false
    property bool connected: false
    property string ssid: ""
    property int signalPercent: 0
    property int signalLevel: 0
    property bool hasWifiDevice: false
    property bool ethernetConnected: false
    property bool monitorEnabled: true
    property bool backendAvailable: true
    property bool _pendingHasWifiDevice: false
    property bool _pendingEthernetConnected: false

    readonly property string statusText: !enabled ? "Off" : (connected ? "Connected" : "Not Connected")
    readonly property string iconGlyph: !enabled ? "􀙈" : (connected ? "􀙇" : "􀙥")
    readonly property string iconSvgName: !enabled ? "wifi.slash" : (connected ? ("wifi." + String(signalLevel)) : "wifi.exclamationmark")
    readonly property bool visible: backendAvailable && available && hasWifiDevice && !ethernetConnected

    property bool _activeWifiFound: false

    readonly property var wifiStatusCommand: ["nmcli", "-t", "-f", "WIFI", "general", "status"]
    readonly property var activeConnectionCommand: ["nmcli", "-t", "-f", "TYPE,NAME", "connection", "show", "--active"]
    readonly property var signalCommand: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "dev", "wifi", "list", "--rescan", "no"]
    readonly property var deviceStatusCommand: ["nmcli", "-t", "-f", "TYPE,STATE", "device", "status"]
    readonly property var monitorCommand: ["nmcli", "monitor"]
    readonly property var setWifiOnCommand: ["nmcli", "radio", "wifi", "on"]
    readonly property var setWifiOffCommand: ["nmcli", "radio", "wifi", "off"]

    function _clearState() {
        root.available = false;
        root.enabled = false;
        root.connected = false;
        root.ssid = "";
        root.signalPercent = 0;
        root.signalLevel = 0;
        root.hasWifiDevice = false;
        root.ethernetConnected = false;
        root._pendingHasWifiDevice = false;
        root._pendingEthernetConnected = false;
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

    function _clampPercent(value) {
        var numeric = Number(value);
        if (!isFinite(numeric)) {
            return 0;
        }
        return Math.max(0, Math.min(100, Math.round(numeric)));
    }

    function _signalLevelFromPercent(nextPercent) {
        var pct = _clampPercent(nextPercent);
        if (pct < 25) {
            return 0;
        }
        if (pct < 50) {
            return 1;
        }
        if (pct < 75) {
            return 2;
        }
        return 3;
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
            root.signalPercent = 0;
            root.signalLevel = 0;
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

    function _applySignalLine(data) {
        var line = data === undefined || data === null ? "" : String(data).trim();
        if (line.length === 0) {
            return;
        }

        if (_looksLikeMissingCommand(line)) {
            _setBackendUnavailable();
            return;
        }

        if (line.indexOf("*:") !== 0) {
            return;
        }

        var parts = line.split(":");
        if (parts.length < 2) {
            return;
        }

        var pct = _clampPercent(parts[1]);
        root.signalPercent = pct;
        root.signalLevel = _signalLevelFromPercent(pct);
    }

    function _applyDeviceStatusLine(data) {
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
        var state = String(parts.slice(1).join(":")).trim().toLowerCase();

        if (type === "wifi" || type === "802-11-wireless") {
            root._pendingHasWifiDevice = true;
            return;
        }

        if (type === "ethernet" && state.indexOf("connected") === 0) {
            root._pendingEthernetConnected = true;
        }
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

        if (!signalProcess.running) {
            root.signalPercent = 0;
            root.signalLevel = 0;
            signalProcess.exec(root.signalCommand);
        }

        if (!deviceStatusProcess.running) {
            root._pendingHasWifiDevice = false;
            root._pendingEthernetConnected = false;
            deviceStatusProcess.exec(root.deviceStatusCommand);
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

    property Process signalProcess: Process {
        id: signalProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root._applySignalLine(data);
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

    property Process deviceStatusProcess: Process {
        id: deviceStatusProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root._applyDeviceStatusLine(data);
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
            if (running) {
                return;
            }
            root.hasWifiDevice = root._pendingHasWifiDevice;
            root.ethernetConnected = root._pendingEthernetConnected;
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
