pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

QtObject {
    id: root

    property bool monitorEnabled: true
    property bool previewMode: false
    property int previewStepMs: 1200
    property bool backendAvailable: false
    property bool hasBattery: false
    property int percentage: 100
    property bool onAdapter: true
    property string statusText: "Fully Charged"
    property string powerSourceText: "Power Adapter"
    property bool showPercentage: false

    property bool powerProfilesChecked: false
    property bool powerProfilesAvailable: false

    readonly property int powerProfile: powerProfilesAvailable ? PowerProfiles.profile : PowerProfile.Balanced
    readonly property string powerProfileText: root._powerProfileLabel(root.powerProfile)
    readonly property string powerProfileDegradationReason: root._degradationReasonLabel(PowerProfiles.degradationReason)
    readonly property var powerProfileChoices: root._powerProfileChoices()

    readonly property bool visible: previewMode || hasBattery
    readonly property string iconGlyph: root._iconGlyphForState(percentage, onAdapter)
    readonly property string stateFilePath: Quickshell.cachePath("battery-indicator-state.json")
    readonly property var displayDevice: UPower.displayDevice

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

    function _statusFromState(state) {
        if (state === UPowerDeviceState.Charging || state === UPowerDeviceState.PendingCharge) {
            return "Charging";
        }
        if (state === UPowerDeviceState.Discharging || state === UPowerDeviceState.PendingDischarge) {
            return "On Battery";
        }
        if (state === UPowerDeviceState.FullyCharged) {
            return "Fully Charged";
        }
        if (state === UPowerDeviceState.Empty) {
            return "Empty";
        }

        return "Unknown";
    }

    function _onAdapterFromState(state) {
        return state === UPowerDeviceState.Charging || state === UPowerDeviceState.FullyCharged || state === UPowerDeviceState.PendingCharge;
    }

    function _powerProfileLabel(profile) {
        if (profile === PowerProfile.PowerSaver) {
            return "Power Saver";
        }
        if (profile === PowerProfile.Performance) {
            return "Performance";
        }

        return "Balanced";
    }

    function _degradationReasonLabel(reason) {
        if (reason === PerformanceDegradationReason.LapDetected) {
            return "Performance limited: lap detected";
        }
        if (reason === PerformanceDegradationReason.HighTemperature) {
            return "Performance limited: high temperature";
        }

        return "";
    }

    function _powerProfileChoices() {
        if (!root.powerProfilesAvailable) {
            return [];
        }

        var choices = [
            {
                profile: PowerProfile.PowerSaver,
                label: "Power Saver"
            },
            {
                profile: PowerProfile.Balanced,
                label: "Balanced"
            }
        ];

        if (PowerProfiles.hasPerformanceProfile) {
            choices.push({
                profile: PowerProfile.Performance,
                label: "Performance"
            });
        }

        return choices;
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

    function _syncLiveState() {
        if (!root.monitorEnabled || root.previewMode) {
            return;
        }

        var device = root.displayDevice;
        var ready = !!device && device.ready;
        root.backendAvailable = ready;
        root.hasBattery = ready && device.isPresent && device.isLaptopBattery;

        if (!root.hasBattery) {
            root._setState(100, !UPower.onBattery, ready ? "Unknown" : "Unavailable", UPower.onBattery ? "Battery" : "Power Adapter");
            return;
        }

        root._setState(device.percentage, root._onAdapterFromState(device.state), root._statusFromState(device.state), UPower.onBattery ? "Battery" : "Power Adapter");
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

    function refresh() {
        if (root.previewMode) {
            return;
        }

        root._syncLiveState();
    }

    function setPowerProfile(nextProfile) {
        if (!root.powerProfilesAvailable) {
            return;
        }

        var targetProfile = Number(nextProfile);
        if (!isFinite(targetProfile)) {
            return;
        }

        if (targetProfile === PowerProfile.Performance && !PowerProfiles.hasPerformanceProfile) {
            return;
        }

        PowerProfiles.profile = targetProfile;
    }

    function _probePowerProfiles() {
        if (powerProfilesProbe.running) {
            return;
        }

        powerProfilesProbe.exec(["powerprofilesctl", "list"]);
    }

    onShowPercentageChanged: {
        if (root._stateLoaded) {
            root._saveState();
        }
    }

    onMonitorEnabledChanged: {
        if (!monitorEnabled) {
            previewTimer.stop();
            powerProfilesPollTimer.stop();
            return;
        }

        powerProfilesPollTimer.start();
        root._probePowerProfiles();

        if (previewMode) {
            previewTimer.start();
            return;
        }

        root.refresh();
    }

    onPreviewModeChanged: {
        if (previewMode) {
            root._previewStageIndex = 0;
            root._applyPreviewStage();
            previewTimer.start();
            return;
        }

        previewTimer.stop();
        root.refresh();
    }

    onPreviewStepMsChanged: previewTimer.interval = Math.max(200, previewStepMs)

    Component.onCompleted: {
        root._loadState();
        root._probePowerProfiles();
        powerProfilesPollTimer.start();

        if (root.previewMode) {
            root._previewStageIndex = 0;
            root._applyPreviewStage();
            previewTimer.start();
            return;
        }

        root.refresh();
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

    property Process powerProfilesProbe: Process {
        id: powerProfilesProbe

        stdout: StdioCollector {
            id: powerProfilesStdout
            waitForEnd: true
        }

        stderr: StdioCollector {
            id: powerProfilesStderr
            waitForEnd: true
        }

        onRunningChanged: {
            if (running) {
                return;
            }

            var stdoutText = String(powerProfilesStdout.text || "").trim();
            var stderrText = String(powerProfilesStderr.text || "").trim();

            root.powerProfilesChecked = true;
            root.powerProfilesAvailable = stdoutText.length > 0 && stderrText.length === 0;
        }
    }

    property Timer powerProfilesPollTimer: Timer {
        id: powerProfilesPollTimer
        interval: 60000
        repeat: true
        running: root.monitorEnabled
        onTriggered: root._probePowerProfiles()
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

    property Connections upowerConnections: Connections {
        target: UPower

        function onOnBatteryChanged() {
            root._syncLiveState();
        }
    }

    property Connections displayDeviceConnections: Connections {
        target: root.displayDevice
        ignoreUnknownSignals: true

        function onReadyChanged() {
            root._syncLiveState();
        }

        function onPercentageChanged() {
            root._syncLiveState();
        }

        function onStateChanged() {
            root._syncLiveState();
        }

        function onIsPresentChanged() {
            root._syncLiveState();
        }

        function onIsLaptopBatteryChanged() {
            root._syncLiveState();
        }
    }
}
