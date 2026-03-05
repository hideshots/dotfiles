pragma Singleton

import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool monitorEnabled: true
    property bool backendAvailable: true
    property bool gpuPollingEnabled: true
    property int refreshIntervalMs: 3000
    property string memMode: "available"

    property int cpuPercent: 0
    property int gpuPercent: 0
    property int memPercent: 0

    property bool cpuAvailable: true
    property bool gpuAvailable: false
    property bool memAvailable: true

    readonly property string cpuStatFilePath: "/proc/stat"
    readonly property string memInfoFilePath: "/proc/meminfo"
    readonly property var gpuUtilCommand: ["nvidia-smi", "--query-gpu=utilization.gpu", "--format=csv,noheader,nounits"]

    property real _lastCpuTotal: 0
    property real _lastCpuIdle: 0
    property bool _cpuBaselineValid: false

    function _clampPercent(value) {
        var numeric = Number(value);
        if (!isFinite(numeric)) {
            return 0;
        }

        return Math.max(0, Math.min(100, Math.round(numeric)));
    }

    function _safeNumber(value) {
        var numeric = Number(value);
        if (!isFinite(numeric)) {
            return NaN;
        }

        return numeric;
    }

    function _looksLikeMissingCommand(text) {
        if (text === undefined || text === null) {
            return false;
        }

        var line = String(text).toLowerCase();
        return line.indexOf("not found") >= 0 || line.indexOf("no such file") >= 0;
    }

    function _parseCpuStats(text) {
        var lines = String(text || "").split("\n");
        if (lines.length === 0) {
            root.cpuAvailable = false;
            root.cpuPercent = 0;
            root._cpuBaselineValid = false;
            return;
        }

        var cpuLine = "";
        for (var i = 0; i < lines.length; i++) {
            var line = String(lines[i]).trim();
            if (line.indexOf("cpu ") === 0) {
                cpuLine = line;
                break;
            }
        }

        if (cpuLine.length === 0) {
            root.cpuAvailable = false;
            root.cpuPercent = 0;
            root._cpuBaselineValid = false;
            return;
        }

        var fields = cpuLine.split(/\s+/);
        if (fields.length < 6) {
            root.cpuAvailable = false;
            root.cpuPercent = 0;
            root._cpuBaselineValid = false;
            return;
        }

        var total = 0;
        for (var col = 1; col < fields.length; col++) {
            var part = root._safeNumber(fields[col]);
            if (isNaN(part)) {
                continue;
            }
            total += part;
        }

        var idle = root._safeNumber(fields[4]);
        var iowait = root._safeNumber(fields[5]);
        if (isNaN(idle)) {
            idle = 0;
        }
        if (isNaN(iowait)) {
            iowait = 0;
        }

        var idleTotal = idle + iowait;
        if (!root._cpuBaselineValid) {
            root._lastCpuTotal = total;
            root._lastCpuIdle = idleTotal;
            root._cpuBaselineValid = true;
            root.cpuPercent = 0;
            root.cpuAvailable = true;
            return;
        }

        var deltaTotal = total - root._lastCpuTotal;
        var deltaIdle = idleTotal - root._lastCpuIdle;
        root._lastCpuTotal = total;
        root._lastCpuIdle = idleTotal;

        if (deltaTotal <= 0 || deltaIdle < 0) {
            root.cpuPercent = 0;
            root.cpuAvailable = true;
            return;
        }

        var usage = ((deltaTotal - deltaIdle) * 100) / deltaTotal;
        root.cpuPercent = root._clampPercent(usage);
        root.cpuAvailable = true;
    }

    function _memValueFromLine(line) {
        var match = String(line || "").match(/:\s*([0-9]+)/);
        if (!match) {
            return NaN;
        }
        return root._safeNumber(match[1]);
    }

    function _parseMemInfo(text) {
        var lines = String(text || "").split("\n");
        var memTotal = NaN;
        var memFree = NaN;
        var memAvailable = NaN;

        for (var i = 0; i < lines.length; i++) {
            var line = String(lines[i]);
            if (line.indexOf("MemTotal:") === 0) {
                memTotal = root._memValueFromLine(line);
            } else if (line.indexOf("MemFree:") === 0) {
                memFree = root._memValueFromLine(line);
            } else if (line.indexOf("MemAvailable:") === 0) {
                memAvailable = root._memValueFromLine(line);
            }
        }

        if (isNaN(memTotal) || memTotal <= 0) {
            root.memAvailable = false;
            root.memPercent = 0;
            return;
        }

        var mode = String(root.memMode || "free").toLowerCase();
        var memUsed = NaN;
        if (mode === "available") {
            if (!isNaN(memAvailable)) {
                memUsed = memTotal - memAvailable;
            }
        } else {
            if (!isNaN(memFree)) {
                memUsed = memTotal - memFree;
            }
        }

        if (isNaN(memUsed)) {
            root.memAvailable = false;
            root.memPercent = 0;
            return;
        }

        root.memPercent = root._clampPercent((memUsed * 100) / memTotal);
        root.memAvailable = true;
    }

    function _parseGpuUtilOutput(text) {
        var lines = String(text || "").split("\n");
        var maxUtil = NaN;

        for (var i = 0; i < lines.length; i++) {
            var raw = String(lines[i]).trim();
            if (raw.length === 0) {
                continue;
            }

            var parsed = root._safeNumber(raw);
            if (isNaN(parsed)) {
                continue;
            }

            if (isNaN(maxUtil) || parsed > maxUtil) {
                maxUtil = parsed;
            }
        }

        if (isNaN(maxUtil)) {
            root.gpuAvailable = false;
            root.gpuPercent = 0;
            return;
        }

        root.gpuPercent = root._clampPercent(maxUtil);
        root.gpuAvailable = true;
    }

    function refresh() {
        if (!root.monitorEnabled || !root.backendAvailable) {
            return;
        }

        cpuStatFile.reload();
        memInfoFile.reload();

        if (!root.gpuPollingEnabled) {
            root.gpuAvailable = false;
            root.gpuPercent = 0;
            return;
        }

        if (!gpuProcess.running) {
            gpuProcess.exec(root.gpuUtilCommand);
        }
    }

    function _setBackendUnavailable() {
        root.backendAvailable = false;
        root.cpuAvailable = false;
        root.memAvailable = false;
        root.gpuAvailable = false;
        root.cpuPercent = 0;
        root.memPercent = 0;
        root.gpuPercent = 0;
        refreshTimer.stop();
    }

    onMonitorEnabledChanged: {
        if (!monitorEnabled) {
            refreshTimer.stop();
            return;
        }

        if (root.backendAvailable) {
            refreshTimer.start();
            root.refresh();
        }
    }

    onMemModeChanged: root.refresh()
    onGpuPollingEnabledChanged: root.refresh()
    onRefreshIntervalMsChanged: {
        refreshTimer.interval = Math.max(1000, root.refreshIntervalMs);
    }

    Component.onCompleted: {
        refreshTimer.interval = Math.max(1000, root.refreshIntervalMs);
        if (!root.monitorEnabled || !root.backendAvailable) {
            return;
        }
        refreshTimer.start();
        root.refresh();
    }

    property FileView cpuStatFile: FileView {
        id: cpuStatFile
        path: root.cpuStatFilePath
        preload: true
        watchChanges: false
        printErrors: false
        onLoaded: root._parseCpuStats(cpuStatFile.text())
        onLoadFailed: root._setBackendUnavailable()
    }

    property FileView memInfoFile: FileView {
        id: memInfoFile
        path: root.memInfoFilePath
        preload: true
        watchChanges: false
        printErrors: false
        onLoaded: root._parseMemInfo(memInfoFile.text())
        onLoadFailed: root._setBackendUnavailable()
    }

    property Process gpuProcess: Process {
        id: gpuProcess

        stdout: StdioCollector {
            id: gpuStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: gpuStderr
            waitForEnd: true
        }

        onRunningChanged: {
            if (running) {
                return;
            }

            var errText = String(gpuStderr.text || "");
            if (root._looksLikeMissingCommand(errText)) {
                root.gpuAvailable = false;
                root.gpuPercent = 0;
                return;
            }

            if (errText.trim().length > 0 && String(gpuStdout.text || "").trim().length === 0) {
                root.gpuAvailable = false;
                root.gpuPercent = 0;
                return;
            }

            root._parseGpuUtilOutput(gpuStdout.text);
        }
    }

    property Timer refreshTimer: Timer {
        id: refreshTimer
        interval: Math.max(1000, root.refreshIntervalMs)
        repeat: true
        running: root.monitorEnabled && root.backendAvailable
        onTriggered: root.refresh()
    }
}
