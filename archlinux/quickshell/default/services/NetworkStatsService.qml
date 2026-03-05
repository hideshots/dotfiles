pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool monitorEnabled: true
    property bool backendAvailable: true
    property string activeInterface: ""
    property real uploadBps: 0
    property real downloadBps: 0

    readonly property bool visible: true
    readonly property string uploadText: root._formatRate(root.uploadBps)
    readonly property string downloadText: root._formatRate(root.downloadBps)
    readonly property string routeFilePath: "/proc/net/route"
    readonly property string netDevFilePath: "/proc/net/dev"

    property real _lastRxBytes: 0
    property real _lastTxBytes: 0
    property double _lastSampleMs: 0
    property bool _baselineValid: false

    function _resetRates() {
        root.uploadBps = 0;
        root.downloadBps = 0;
    }

    function _resetBaseline() {
        root._baselineValid = false;
        root._lastSampleMs = 0;
        root._lastRxBytes = 0;
        root._lastTxBytes = 0;
        root._resetRates();
    }

    function _numericOr(value, fallback) {
        var parsed = Number(value);
        if (!isFinite(parsed)) {
            return fallback;
        }

        return parsed;
    }

    function _parseMetric(value) {
        var parsed = parseInt(String(value), 10);
        if (isNaN(parsed)) {
            return Number.MAX_SAFE_INTEGER;
        }

        return parsed;
    }

    function _formatRate(bytesPerSecond) {
        var bytes = _numericOr(bytesPerSecond, 0);
        if (bytes < 0) {
            bytes = 0;
        }

        if (bytes >= (1024 * 1024)) {
            return (bytes / (1024 * 1024)).toFixed(1) + " MB/s";
        }

        return String(Math.round(bytes / 1024)) + " KB/s";
    }

    function _updateActiveInterfaceFromRoute(text) {
        var lines = String(text || "").split("\n");
        var bestInterface = "";
        var bestMetric = Number.MAX_SAFE_INTEGER;

        for (var i = 1; i < lines.length; i++) {
            var line = String(lines[i]).trim();
            if (line.length === 0) {
                continue;
            }

            var fields = line.split(/\s+/);
            if (fields.length < 8) {
                continue;
            }

            var destination = String(fields[1]).trim().toUpperCase();
            if (destination !== "00000000") {
                continue;
            }

            var metric = root._parseMetric(fields[6]);
            if (metric < bestMetric) {
                bestMetric = metric;
                bestInterface = String(fields[0]).trim();
            }
        }

        if (bestInterface !== root.activeInterface) {
            root.activeInterface = bestInterface;
            root._resetBaseline();
        }
    }

    function _statsForInterface(text, interfaceName) {
        var result = {
            found: false,
            rxBytes: 0,
            txBytes: 0
        };
        var iface = String(interfaceName || "").trim();
        if (iface.length === 0) {
            return result;
        }

        var lines = String(text || "").split("\n");
        for (var i = 2; i < lines.length; i++) {
            var rawLine = String(lines[i]);
            if (rawLine.indexOf(":") < 0) {
                continue;
            }

            var parts = rawLine.split(":");
            if (parts.length < 2) {
                continue;
            }

            var candidate = String(parts[0]).trim();
            if (candidate !== iface) {
                continue;
            }

            var fields = String(parts[1]).trim().split(/\s+/);
            if (fields.length < 9) {
                return result;
            }

            var rx = root._numericOr(fields[0], NaN);
            var tx = root._numericOr(fields[8], NaN);
            if (!isFinite(rx) || !isFinite(tx)) {
                return result;
            }

            result.found = true;
            result.rxBytes = rx;
            result.txBytes = tx;
            return result;
        }

        return result;
    }

    function _sampleRates() {
        if (!root.monitorEnabled || !root.backendAvailable) {
            return;
        }

        var iface = String(root.activeInterface || "").trim();
        if (iface.length === 0) {
            root._resetBaseline();
            return;
        }

        var stats = root._statsForInterface(netDevFile.text(), iface);
        if (!stats.found) {
            root._resetBaseline();
            return;
        }

        var nowMs = Date.now();
        if (!root._baselineValid) {
            root._lastRxBytes = stats.rxBytes;
            root._lastTxBytes = stats.txBytes;
            root._lastSampleMs = nowMs;
            root._baselineValid = true;
            root._resetRates();
            return;
        }

        var elapsedMs = nowMs - root._lastSampleMs;
        if (elapsedMs <= 0) {
            root._lastRxBytes = stats.rxBytes;
            root._lastTxBytes = stats.txBytes;
            root._lastSampleMs = nowMs;
            root._resetRates();
            return;
        }

        var rxDelta = stats.rxBytes - root._lastRxBytes;
        var txDelta = stats.txBytes - root._lastTxBytes;
        if (rxDelta < 0 || txDelta < 0) {
            root._lastRxBytes = stats.rxBytes;
            root._lastTxBytes = stats.txBytes;
            root._lastSampleMs = nowMs;
            root._resetRates();
            return;
        }

        root.downloadBps = (rxDelta * 1000) / elapsedMs;
        root.uploadBps = (txDelta * 1000) / elapsedMs;
        root._lastRxBytes = stats.rxBytes;
        root._lastTxBytes = stats.txBytes;
        root._lastSampleMs = nowMs;
    }

    function refreshRoute() {
        if (!root.monitorEnabled || !root.backendAvailable) {
            return;
        }

        routeFile.reload();
    }

    function refreshStats() {
        if (!root.monitorEnabled || !root.backendAvailable) {
            return;
        }

        netDevFile.reload();
    }

    function _setBackendUnavailable() {
        root.backendAvailable = false;
        root.activeInterface = "";
        root._resetBaseline();
        routeRefreshTimer.stop();
        statsRefreshTimer.stop();
    }

    onMonitorEnabledChanged: {
        if (!monitorEnabled) {
            routeRefreshTimer.stop();
            statsRefreshTimer.stop();
            root._resetBaseline();
            return;
        }

        if (root.backendAvailable) {
            routeRefreshTimer.start();
            statsRefreshTimer.start();
            root.refreshRoute();
            root.refreshStats();
        }
    }

    Component.onCompleted: {
        if (!root.monitorEnabled || !root.backendAvailable) {
            return;
        }

        routeRefreshTimer.start();
        statsRefreshTimer.start();
        root.refreshRoute();
        root.refreshStats();
    }

    property FileView routeFile: FileView {
        id: routeFile
        path: root.routeFilePath
        preload: true
        watchChanges: false
        printErrors: false
        onLoaded: {
            root._updateActiveInterfaceFromRoute(routeFile.text());
        }
        onLoadFailed: root._setBackendUnavailable()
    }

    property FileView netDevFile: FileView {
        id: netDevFile
        path: root.netDevFilePath
        preload: true
        watchChanges: false
        printErrors: false
        onLoaded: {
            root._sampleRates();
        }
        onLoadFailed: root._setBackendUnavailable()
    }

    property Timer routeRefreshTimer: Timer {
        id: routeRefreshTimer
        interval: 5000
        repeat: true
        running: root.monitorEnabled && root.backendAvailable
        onTriggered: root.refreshRoute()
    }

    property Timer statsRefreshTimer: Timer {
        id: statsRefreshTimer
        interval: 3000
        repeat: true
        running: root.monitorEnabled && root.backendAvailable
        onTriggered: root.refreshStats()
    }
}
