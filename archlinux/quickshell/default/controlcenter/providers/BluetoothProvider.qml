import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool available: false
    property bool enabled: false
    property bool monitorEnabled: true
    property bool backendAvailable: true

    property bool _sawController: false
    property bool _sawPowerLine: false

    readonly property var showCommand: ["bluetoothctl", "show"]
    readonly property var powerOnCommand: ["bluetoothctl", "power", "on"]
    readonly property var powerOffCommand: ["bluetoothctl", "power", "off"]

    function _clearState() {
        root.available = false;
        root.enabled = false;
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
        pollTimer.stop();
    }

    function _parseShowLine(data) {
        var line = data === undefined || data === null ? "" : String(data).trim();
        if (line.length === 0) {
            return;
        }

        if (_looksLikeMissingCommand(line)) {
            _setBackendUnavailable();
            return;
        }

        if (line.indexOf("Controller ") === 0) {
            root._sawController = true;
            return;
        }

        if (line.indexOf("Powered:") === 0) {
            root._sawPowerLine = true;
            root.enabled = String(line.slice("Powered:".length)).trim().toLowerCase() === "yes";
        }
    }

    function refresh() {
        if (!root.monitorEnabled || !root.backendAvailable || showProcess.running) {
            return;
        }

        root._sawController = false;
        root._sawPowerLine = false;
        showProcess.exec(root.showCommand);
    }

    function setEnabled(nextEnabled) {
        if (!root.backendAvailable || setPowerProcess.running) {
            return;
        }

        setPowerProcess.exec(nextEnabled ? root.powerOnCommand : root.powerOffCommand);
    }

    onMonitorEnabledChanged: {
        if (!monitorEnabled) {
            pollTimer.stop();
            _clearState();
            return;
        }

        refresh();
        pollTimer.start();
    }

    Component.onCompleted: {
        refresh();
        pollTimer.start();
    }

    property Process showProcess: Process {
        id: showProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root._parseShowLine(data);
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                var line = data === undefined || data === null ? "" : String(data).trim().toLowerCase();
                if (line.indexOf("no default controller available") >= 0) {
                    root.available = false;
                    root.enabled = false;
                    return;
                }

                if (root._looksLikeMissingCommand(line)) {
                    root._setBackendUnavailable();
                }
            }
        }

        onRunningChanged: {
            if (running) {
                return;
            }

            if (!root._sawController) {
                root.available = false;
                root.enabled = false;
                return;
            }

            root.available = true;
            if (!root._sawPowerLine) {
                root.enabled = false;
            }
        }
    }

    property Process setPowerProcess: Process {
        id: setPowerProcess
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

    property Timer pollTimer: Timer {
        id: pollTimer
        interval: 2500
        repeat: true
        running: root.monitorEnabled && root.backendAvailable
        onTriggered: root.refresh()
    }
}
