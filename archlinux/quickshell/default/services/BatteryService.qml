pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool monitorEnabled: true
    property bool previewMode: false
    property int previewStepMs: 1200
    property bool backendAvailable: true
    property bool hasBattery: false
    property int percentage: 100
    property bool onAdapter: true
    property string statusText: "Fully Charged"
    property string powerSourceText: "Power Adapter"
    property bool showPercentage: false

    readonly property bool visible: previewMode || hasBattery
    readonly property string iconGlyph: root._iconGlyphForState(percentage, onAdapter)
    readonly property string stateFilePath: Quickshell.cachePath("battery-indicator-state.json")
    readonly property var listDevicesCommand: ["upower", "-e"]

    property string _batteryDevicePath: ""
    property int _previewStageIndex: 0
    property bool _stateLoaded: false

    readonly property var _previewStages: [
        {
            percentage: 100,
            onAdapter: true,
            statusText: "Fully Charged",
            powerSourceText: "Power Adapter"
        },
        {
            percentage: 100,
            onAdapter: false,
            statusText: "Fully Charged",
            powerSourceText: "Battery"
        },
        {
            percentage: 75,
            onAdapter: false,
            statusText: "On Battery",
            powerSourceText: "Battery"
        },
        {
            percentage: 50,
            onAdapter: false,
            statusText: "On Battery",
            powerSourceText: "Battery"
        },
        {
            percentage: 25,
            onAdapter: false,
            statusText: "On Battery",
            powerSourceText: "Battery"
        },
        {
            percentage: 0,
            onAdapter: false,
            statusText: "Empty",
            powerSourceText: "Battery"
        }
    ]

    function _clampPercentage(value) {
        var numeric = Number(value);
        if (!isFinite(numeric)) {
            return 100;
        }

        return Math.max(0, Math.min(100, Math.round(numeric)));
    }

    function _looksLikeMissingCommand(text) {
        if (text === undefined || text === null) {
            return false;
        }

        var line = String(text).toLowerCase();
        return line.indexOf("not found") >= 0 || line.indexOf("no such file") >= 0;
    }

    function _setState(nextPercentage, nextOnAdapter, nextStatusText, nextPowerSourceText) {
        root.percentage = _clampPercentage(nextPercentage);
        root.onAdapter = !!nextOnAdapter;
        root.statusText = String(nextStatusText || "Unknown");
        root.powerSourceText = String(nextPowerSourceText || (root.onAdapter ? "Power Adapter" : "Battery"));
    }

    function _iconGlyphForState(nextPercentage, nextOnAdapter) {
        if (nextOnAdapter) {
            return "􀢋";
        }

        var pct = _clampPercentage(nextPercentage);
        if (pct <= 5) {
            return "􀛪";
        }
        if (pct <= 37) {
            return "􀛩";
        }
        if (pct <= 62) {
            return "􀺶";
        }
        if (pct <= 87) {
            return "􀺸";
        }

        return "􀛨";
    }

    function _statusFromRaw(rawState) {
        var state = String(rawState || "").trim().toLowerCase();
        if (state === "charging" || state === "pending-charge") {
            return "Charging";
        }
        if (state === "discharging" || state === "pending-discharge") {
            return "On Battery";
        }
        if (state === "fully-charged") {
            return "Fully Charged";
        }
        if (state === "empty") {
            return "Empty";
        }
        if (state === "unknown" || state.length === 0) {
            return "Unknown";
        }
        return state.charAt(0).toUpperCase() + state.slice(1);
    }

    function _onAdapterFromRaw(rawState) {
        var state = String(rawState || "").trim().toLowerCase();
        return state === "charging" || state === "fully-charged" || state === "pending-charge";
    }

    function _applyPreviewStage() {
        if (root._previewStages.length === 0) {
            root._setState(100, true, "Fully Charged", "Power Adapter");
            return;
        }

        var index = root._previewStageIndex % root._previewStages.length;
        if (index < 0) {
            index = 0;
        }
        var stage = root._previewStages[index];
        root._setState(stage.percentage, stage.onAdapter, stage.statusText, stage.powerSourceText);
    }

    function _findBatteryDevicePath(text) {
        var lines = String(text || "").split("\n");
        for (var i = 0; i < lines.length; i++) {
            var line = String(lines[i]).trim();
            if (line.length === 0) {
                continue;
            }
            if (line.toLowerCase().indexOf("/battery_") >= 0 || line.toLowerCase().indexOf("/battery") >= 0) {
                return line;
            }
        }
        return "";
    }

    function _parseBatteryInfo(text) {
        var lines = String(text || "").split("\n");
        var rawState = "";
        var pct = root.percentage;

        for (var i = 0; i < lines.length; i++) {
            var line = String(lines[i]).trim();
            if (line.toLowerCase().indexOf("state:") === 0) {
                rawState = String(line.slice("state:".length)).trim();
                continue;
            }

            var pctMatch = line.match(/^percentage:\s*([0-9]+(?:\.[0-9]+)?)%/i);
            if (pctMatch) {
                pct = Number(pctMatch[1]);
            }
        }

        var computedOnAdapter = root._onAdapterFromRaw(rawState);
        var computedStatus = root._statusFromRaw(rawState);
        root._setState(pct, computedOnAdapter, computedStatus, computedOnAdapter ? "Power Adapter" : "Battery");
    }

    function _loadState() {
        var savedText = String(stateFile.text() || "").trim();
        if (savedText.length === 0) {
            root._stateLoaded = true;
            return;
        }

        try {
            var parsed = JSON.parse(savedText);
            root.showPercentage = parsed && parsed.showPercentage === true;
        } catch (exception) {
            console.warn("Battery state read failed:", exception);
        }

        root._stateLoaded = true;
    }

    function _saveState() {
        stateFile.setText(JSON.stringify({
            showPercentage: root.showPercentage
        }));
    }

    function _setBackendUnavailable() {
        root.backendAvailable = false;
        root.hasBattery = false;
        root._batteryDevicePath = "";
        refreshTimer.stop();
    }

    function refresh() {
        if (!root.monitorEnabled || root.previewMode || !root.backendAvailable || listDevicesProcess.running || batteryInfoProcess.running) {
            return;
        }

        listDevicesProcess.exec(root.listDevicesCommand);
    }

    onShowPercentageChanged: {
        if (root._stateLoaded) {
            root._saveState();
        }
    }

    onMonitorEnabledChanged: {
        if (!monitorEnabled) {
            refreshTimer.stop();
            return;
        }

        if (previewMode) {
            previewTimer.start();
            return;
        }

        refresh();
        refreshTimer.start();
    }

    onPreviewModeChanged: {
        if (previewMode) {
            refreshTimer.stop();
            root._previewStageIndex = 0;
            root._applyPreviewStage();
            previewTimer.start();
            return;
        }

        previewTimer.stop();
        refresh();
        refreshTimer.start();
    }

    onPreviewStepMsChanged: {
        previewTimer.interval = Math.max(200, previewStepMs);
    }

    Component.onCompleted: {
        root._loadState();
        if (root.previewMode) {
            root._previewStageIndex = 0;
            root._applyPreviewStage();
            previewTimer.start();
            return;
        }

        refresh();
        refreshTimer.start();
    }

    property FileView stateFile: FileView {
        id: stateFile
        path: root.stateFilePath
        preload: true
        watchChanges: false
        blockLoading: true
        printErrors: false
        onSaveFailed: console.warn("Battery state write failed.")
    }

    property Process listDevicesProcess: Process {
        id: listDevicesProcess
        stdout: StdioCollector {
            id: listDevicesStdout
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: listDevicesStderr
            waitForEnd: true
        }

        onRunningChanged: {
            if (running) {
                return;
            }

            var stderrText = String(listDevicesStderr.text || "");
            if (root._looksLikeMissingCommand(stderrText)) {
                root._setBackendUnavailable();
                return;
            }

            var devicePath = root._findBatteryDevicePath(listDevicesStdout.text);
            root._batteryDevicePath = devicePath;
            root.hasBattery = devicePath.length > 0;
            if (!root.hasBattery) {
                return;
            }

            batteryInfoProcess.exec(["upower", "-i", devicePath]);
        }
    }

    property Process batteryInfoProcess: Process {
        id: batteryInfoProcess
        stdout: StdioCollector {
            id: batteryInfoStdout
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: batteryInfoStderr
            waitForEnd: true
        }

        onRunningChanged: {
            if (running) {
                return;
            }

            var stderrText = String(batteryInfoStderr.text || "");
            if (root._looksLikeMissingCommand(stderrText)) {
                root._setBackendUnavailable();
                return;
            }

            if (root.hasBattery) {
                root._parseBatteryInfo(batteryInfoStdout.text);
            }
        }
    }

    property Timer refreshTimer: Timer {
        id: refreshTimer
        interval: 15000
        repeat: true
        running: root.monitorEnabled && !root.previewMode && root.backendAvailable
        onTriggered: root.refresh()
    }

    property Timer previewTimer: Timer {
        id: previewTimer
        interval: Math.max(200, root.previewStepMs)
        repeat: true
        running: root.monitorEnabled && root.previewMode
        onTriggered: {
            root._previewStageIndex = (root._previewStageIndex + 1) % root._previewStages.length;
            root._applyPreviewStage();
        }
    }
}
