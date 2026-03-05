pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool monitorEnabled: true
    property bool backendAvailable: true
    property bool enabled: true
    property int refreshIntervalMs: 30000
    property var configuredEntries: []
    property var displayEntries: []

    readonly property bool visible: enabled && backendAvailable && displayEntries.length > 0
    readonly property var dfCommand: ["df", "-P", "-T"]

    property var _normalizedConfiguredEntries: []
    property var _statsByMount: ({})

    function _looksLikeMissingCommand(text) {
        if (text === undefined || text === null) {
            return false;
        }

        var line = String(text).toLowerCase();
        return line.indexOf("not found") >= 0 || line.indexOf("no such file") >= 0;
    }

    function _clampPercent(value) {
        var numeric = Number(value);
        if (!isFinite(numeric)) {
            return 0;
        }

        return Math.max(0, Math.min(100, Math.round(numeric)));
    }

    function _defaultLabelForMount(mountPoint) {
        var mount = String(mountPoint || "").trim();
        if (mount === "/") {
            return "ROOT";
        }

        var parts = mount.split("/");
        var lastPart = "";
        for (var i = parts.length - 1; i >= 0; i--) {
            if (String(parts[i]).trim().length > 0) {
                lastPart = String(parts[i]).trim();
                break;
            }
        }

        if (lastPart.length === 0) {
            return "DISK";
        }

        return lastPart.toUpperCase();
    }

    function _normalizeConfiguredEntries(sourceEntries) {
        if (!Array.isArray(sourceEntries)) {
            return [];
        }

        var seenMounts = ({});
        var normalized = [];
        for (var i = 0; i < sourceEntries.length; i++) {
            var entry = sourceEntries[i];
            if (!entry) {
                continue;
            }

            var mountPoint = String(entry.mountPoint || "").trim();
            if (mountPoint.length === 0 || mountPoint.charAt(0) !== "/") {
                continue;
            }

            if (seenMounts[mountPoint]) {
                continue;
            }

            seenMounts[mountPoint] = true;
            var label = String(entry.label || "").trim();
            if (label.length === 0) {
                label = root._defaultLabelForMount(mountPoint);
            }

            normalized.push({
                label: label,
                mountPoint: mountPoint
            });
        }

        return normalized;
    }

    function _rebuildDisplayEntries() {
        var nextEntries = [];
        for (var i = 0; i < root._normalizedConfiguredEntries.length; i++) {
            var configured = root._normalizedConfiguredEntries[i];
            var stats = root._statsByMount[configured.mountPoint];
            if (!stats) {
                continue;
            }

            nextEntries.push({
                label: configured.label,
                mountPoint: configured.mountPoint,
                percent: root._clampPercent(stats.percent),
                source: String(stats.source || ""),
                fsType: String(stats.fsType || "")
            });
        }

        root.displayEntries = nextEntries;
    }

    function _parseDfOutput(text) {
        var lines = String(text || "").split("\n");
        var byMount = ({});

        for (var i = 1; i < lines.length; i++) {
            var line = String(lines[i]).trim();
            if (line.length === 0) {
                continue;
            }

            var fields = line.split(/\s+/);
            if (fields.length < 7) {
                continue;
            }

            var percentField = String(fields[5] || "").trim();
            var percentMatch = percentField.match(/^([0-9]+)%$/);
            if (!percentMatch) {
                continue;
            }

            var mountPoint = String(fields[6] || "").trim();
            if (mountPoint.length === 0) {
                continue;
            }

            byMount[mountPoint] = {
                percent: Number(percentMatch[1]),
                source: String(fields[0] || ""),
                fsType: String(fields[1] || "")
            };
        }

        root._statsByMount = byMount;
        root._rebuildDisplayEntries();
    }

    function _setBackendUnavailable() {
        root.backendAvailable = false;
        root.displayEntries = [];
        root._statsByMount = ({});
        refreshTimer.stop();
    }

    function refresh() {
        if (!root.enabled || !root.monitorEnabled || !root.backendAvailable || dfProcess.running) {
            return;
        }

        dfProcess.exec(root.dfCommand);
    }

    onConfiguredEntriesChanged: {
        root._normalizedConfiguredEntries = root._normalizeConfiguredEntries(root.configuredEntries);
        root._rebuildDisplayEntries();
        root.refresh();
    }

    onEnabledChanged: {
        if (!enabled) {
            refreshTimer.stop();
            root.displayEntries = [];
            return;
        }

        if (root.monitorEnabled && root.backendAvailable) {
            refreshTimer.start();
            root.refresh();
        }
    }

    onMonitorEnabledChanged: {
        if (!monitorEnabled) {
            refreshTimer.stop();
            return;
        }

        if (root.enabled && root.backendAvailable) {
            refreshTimer.start();
            root.refresh();
        }
    }

    onRefreshIntervalMsChanged: {
        refreshTimer.interval = Math.max(1000, root.refreshIntervalMs);
        if (refreshTimer.running) {
            refreshTimer.restart();
        }
    }

    Component.onCompleted: {
        root._normalizedConfiguredEntries = root._normalizeConfiguredEntries(root.configuredEntries);
        refreshTimer.interval = Math.max(1000, root.refreshIntervalMs);
        if (root.enabled && root.monitorEnabled && root.backendAvailable) {
            refreshTimer.start();
            root.refresh();
        }
    }

    property Process dfProcess: Process {
        id: dfProcess

        stdout: StdioCollector {
            id: dfStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: dfStderr
            waitForEnd: true
        }

        onRunningChanged: {
            if (running) {
                return;
            }

            var errText = String(dfStderr.text || "");
            if (root._looksLikeMissingCommand(errText)) {
                root._setBackendUnavailable();
                return;
            }

            root._parseDfOutput(dfStdout.text);
        }
    }

    property Timer refreshTimer: Timer {
        id: refreshTimer
        interval: Math.max(1000, root.refreshIntervalMs)
        repeat: true
        running: root.enabled && root.monitorEnabled && root.backendAvailable
        onTriggered: root.refresh()
    }
}
