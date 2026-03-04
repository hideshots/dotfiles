import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool monitorEnabled: true
    property bool backendAvailable: true

    property bool animationsEnabled: true
    readonly property bool reduceMotionEnabled: !root.animationsEnabled

    property bool blurEnabled: true
    property int blurSize: 0
    property int blurPasses: 1
    property real blurBrightness: 1.0
    property real blurContrast: 1.0
    readonly property bool reduceTransparencyEnabled: root.blurBrightness <= 0.0001

    property bool hasBlurSnapshot: false
    property bool _snapshotBlurEnabled: true
    property int _snapshotBlurSize: 0
    property int _snapshotBlurPasses: 1
    property real _snapshotBlurBrightness: 1.0
    property real _snapshotBlurContrast: 1.0

    readonly property var getAnimationsCommand: ["hyprctl", "getoption", "animations:enabled", "-j"]
    readonly property var getBlurEnabledCommand: ["hyprctl", "getoption", "decoration:blur:enabled", "-j"]
    readonly property var getBlurSizeCommand: ["hyprctl", "getoption", "decoration:blur:size", "-j"]
    readonly property var getBlurPassesCommand: ["hyprctl", "getoption", "decoration:blur:passes", "-j"]
    readonly property var getBlurBrightnessCommand: ["hyprctl", "getoption", "decoration:blur:brightness", "-j"]
    readonly property var getBlurContrastCommand: ["hyprctl", "getoption", "decoration:blur:contrast", "-j"]

    readonly property var setAnimationsOnCommand: ["hyprctl", "keyword", "animations:enabled", "0"]
    readonly property var setAnimationsOffCommand: ["hyprctl", "keyword", "animations:enabled", "1"]
    readonly property var setReducedTransparencyCommand: [
        "hyprctl",
        "--batch",
        "keyword decoration:blur:enabled 1; keyword decoration:blur:size 0; keyword decoration:blur:passes 1; keyword decoration:blur:brightness 0; keyword decoration:blur:contrast 1.5"
    ]
    readonly property var reloadCommand: ["hyprctl", "reload"]

    function _looksLikeMissingCommand(text) {
        if (text === undefined || text === null) {
            return false;
        }

        var line = String(text).toLowerCase();
        return line.indexOf("not found") >= 0 || line.indexOf("no such file") >= 0;
    }

    function _looksLikeBackendFailure(text) {
        if (text === undefined || text === null) {
            return false;
        }

        var line = String(text).toLowerCase();
        return line.indexOf("couldn't set socket timeout") >= 0
            || line.indexOf("instance signature not set") >= 0
            || line.indexOf("hyprland") >= 0
            || line.indexOf("error") >= 0;
    }

    function _setBackendUnavailable() {
        root.backendAvailable = false;
        pollTimer.stop();
    }

    function _numberFromOptionObject(obj) {
        if (!obj || typeof obj !== "object") {
            return NaN;
        }

        if (obj.int !== undefined && obj.int !== null) {
            var asInt = Number(obj.int);
            if (isFinite(asInt)) {
                return asInt;
            }
        }

        if (obj.float !== undefined && obj.float !== null) {
            var asFloat = Number(obj.float);
            if (isFinite(asFloat)) {
                return asFloat;
            }
        }

        if (obj.custom !== undefined && obj.custom !== null) {
            var asCustom = Number(obj.custom);
            if (isFinite(asCustom)) {
                return asCustom;
            }
        }

        return NaN;
    }

    function _parseOptionNumber(data) {
        var line = data === undefined || data === null ? "" : String(data).trim();
        if (line.length === 0) {
            return NaN;
        }

        if (_looksLikeMissingCommand(line) || _looksLikeBackendFailure(line)) {
            _setBackendUnavailable();
            return NaN;
        }

        try {
            var parsed = JSON.parse(line);
            return _numberFromOptionObject(parsed);
        } catch (error) {
            return NaN;
        }
    }

    function _captureBlurSnapshot() {
        root._snapshotBlurEnabled = root.blurEnabled;
        root._snapshotBlurSize = root.blurSize;
        root._snapshotBlurPasses = root.blurPasses;
        root._snapshotBlurBrightness = root.blurBrightness;
        root._snapshotBlurContrast = root.blurContrast;
        root.hasBlurSnapshot = true;
    }

    function _restoreBlurBatchCommand() {
        var enabledNumber = root._snapshotBlurEnabled ? 1 : 0;
        var sizeNumber = Math.max(0, Math.round(root._snapshotBlurSize));
        var passesNumber = Math.max(1, Math.round(root._snapshotBlurPasses));
        var brightnessNumber = Number(root._snapshotBlurBrightness);
        if (!isFinite(brightnessNumber)) {
            brightnessNumber = 1.0;
        }
        var contrastNumber = Number(root._snapshotBlurContrast);
        if (!isFinite(contrastNumber)) {
            contrastNumber = 1.0;
        }

        var batch = "keyword decoration:blur:enabled " + enabledNumber
            + "; keyword decoration:blur:size " + sizeNumber
            + "; keyword decoration:blur:passes " + passesNumber
            + "; keyword decoration:blur:brightness " + brightnessNumber
            + "; keyword decoration:blur:contrast " + contrastNumber;
        return ["hyprctl", "--batch", batch];
    }

    function refresh() {
        if (!root.monitorEnabled || !root.backendAvailable) {
            return;
        }

        if (!getAnimationsProcess.running) {
            getAnimationsProcess.exec(root.getAnimationsCommand);
        }
        if (!getBlurEnabledProcess.running) {
            getBlurEnabledProcess.exec(root.getBlurEnabledCommand);
        }
        if (!getBlurSizeProcess.running) {
            getBlurSizeProcess.exec(root.getBlurSizeCommand);
        }
        if (!getBlurPassesProcess.running) {
            getBlurPassesProcess.exec(root.getBlurPassesCommand);
        }
        if (!getBlurBrightnessProcess.running) {
            getBlurBrightnessProcess.exec(root.getBlurBrightnessCommand);
        }
        if (!getBlurContrastProcess.running) {
            getBlurContrastProcess.exec(root.getBlurContrastCommand);
        }
    }

    function setReduceMotionEnabled(nextEnabled) {
        if (!root.backendAvailable || setMotionProcess.running) {
            return;
        }

        setMotionProcess.exec(nextEnabled ? root.setAnimationsOnCommand : root.setAnimationsOffCommand);
    }

    function setReduceTransparencyEnabled(nextEnabled) {
        if (!root.backendAvailable || setTransparencyProcess.running) {
            return;
        }

        if (nextEnabled) {
            if (!root.hasBlurSnapshot) {
                root._captureBlurSnapshot();
            }
            setTransparencyProcess.exec(root.setReducedTransparencyCommand);
            return;
        }

        if (root.hasBlurSnapshot) {
            setTransparencyProcess.exec(root._restoreBlurBatchCommand());
            return;
        }

        setTransparencyProcess.exec(root.reloadCommand);
    }

    onMonitorEnabledChanged: {
        if (!monitorEnabled) {
            pollTimer.stop();
            return;
        }

        refresh();
        pollTimer.start();
    }

    Component.onCompleted: {
        refresh();
        pollTimer.start();
    }

    property Process getAnimationsProcess: Process {
        id: getAnimationsProcess
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                var value = root._parseOptionNumber(data);
                if (isFinite(value)) {
                    root.animationsEnabled = value > 0;
                }
            }
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                if (root._looksLikeMissingCommand(data) || root._looksLikeBackendFailure(data)) {
                    root._setBackendUnavailable();
                }
            }
        }
    }

    property Process getBlurEnabledProcess: Process {
        id: getBlurEnabledProcess
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                var value = root._parseOptionNumber(data);
                if (isFinite(value)) {
                    root.blurEnabled = value > 0;
                }
            }
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                if (root._looksLikeMissingCommand(data) || root._looksLikeBackendFailure(data)) {
                    root._setBackendUnavailable();
                }
            }
        }
    }

    property Process getBlurSizeProcess: Process {
        id: getBlurSizeProcess
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                var value = root._parseOptionNumber(data);
                if (isFinite(value)) {
                    root.blurSize = Math.max(0, Math.round(value));
                }
            }
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                if (root._looksLikeMissingCommand(data) || root._looksLikeBackendFailure(data)) {
                    root._setBackendUnavailable();
                }
            }
        }
    }

    property Process getBlurPassesProcess: Process {
        id: getBlurPassesProcess
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                var value = root._parseOptionNumber(data);
                if (isFinite(value)) {
                    root.blurPasses = Math.max(1, Math.round(value));
                }
            }
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                if (root._looksLikeMissingCommand(data) || root._looksLikeBackendFailure(data)) {
                    root._setBackendUnavailable();
                }
            }
        }
    }

    property Process getBlurBrightnessProcess: Process {
        id: getBlurBrightnessProcess
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                var value = root._parseOptionNumber(data);
                if (isFinite(value)) {
                    root.blurBrightness = value;
                }
            }
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                if (root._looksLikeMissingCommand(data) || root._looksLikeBackendFailure(data)) {
                    root._setBackendUnavailable();
                }
            }
        }
    }

    property Process getBlurContrastProcess: Process {
        id: getBlurContrastProcess
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                var value = root._parseOptionNumber(data);
                if (isFinite(value)) {
                    root.blurContrast = value;
                }
            }
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                if (root._looksLikeMissingCommand(data) || root._looksLikeBackendFailure(data)) {
                    root._setBackendUnavailable();
                }
            }
        }
    }

    property Process setMotionProcess: Process {
        id: setMotionProcess
        onRunningChanged: {
            if (!running && root.monitorEnabled && root.backendAvailable) {
                root.refresh();
            }
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                if (root._looksLikeMissingCommand(data) || root._looksLikeBackendFailure(data)) {
                    root._setBackendUnavailable();
                }
            }
        }
    }

    property Process setTransparencyProcess: Process {
        id: setTransparencyProcess
        onRunningChanged: {
            if (!running && root.monitorEnabled && root.backendAvailable) {
                root.refresh();
            }
        }
        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                if (root._looksLikeMissingCommand(data) || root._looksLikeBackendFailure(data)) {
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
