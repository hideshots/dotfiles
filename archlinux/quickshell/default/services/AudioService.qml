pragma Singleton

import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root

    property bool available: false
    property bool muted: false
    property real value: 0.0
    property bool monitorEnabled: true
    readonly property bool backendAvailable: Pipewire.ready
    readonly property bool osdSuppressed: osdSuppressTimer.running

    readonly property int percent: Math.round(root.value * 100)
    readonly property int iconLevel: _iconLevelFromValue(root.value)
    readonly property bool sliderEnabled: monitorEnabled && backendAvailable && available
    readonly property bool visible: true
    readonly property string iconGlyph: (!backendAvailable || !available || muted) ? "􀊣" : "􀊩"
    readonly property string iconSvgName: (!backendAvailable || !available || muted) ? "speaker.slash.fill" : ("speaker.wave.3.fill." + String(iconLevel))
    readonly property var trackedSink: Pipewire.ready ? Pipewire.defaultAudioSink : null
    readonly property var trackedAudio: root.trackedSink && root.trackedSink.ready && root.trackedSink.audio ? root.trackedSink.audio : null

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

    function _syncFromPipewire() {
        if (!root.monitorEnabled || !root.backendAvailable) {
            root._clearState();
            return;
        }

        if (!root.trackedSink || !root.trackedSink.ready || !root.trackedAudio) {
            root._clearState();
            return;
        }

        root.available = true;
        root.value = _clamp(root.trackedAudio.volume);
        root.muted = !!root.trackedAudio.muted;
    }

    function _scheduleSync() {
        syncDebounce.restart();
    }

    function refresh() {
        root._scheduleSync();
    }

    function suppressOsdFor(durationMs) {
        var intervalMs = Math.max(0, Math.round(Number(durationMs)));
        if (!isFinite(intervalMs) || intervalMs <= 0) {
            intervalMs = 450;
        }

        osdSuppressTimer.interval = intervalMs;
        osdSuppressTimer.restart();
    }

    function setMuted(nextMuted) {
        if (!root.sliderEnabled || !root.trackedAudio) {
            return;
        }

        root.available = true;
        root.muted = !!nextMuted;
        root.trackedAudio.muted = root.muted;
        root._scheduleSync();
    }

    function setVolume(nextValue) {
        if (!root.sliderEnabled || !root.trackedAudio) {
            return;
        }

        var clamped = _clamp(nextValue);
        if (root.trackedAudio.muted && clamped > 0) {
            root.muted = false;
            root.trackedAudio.muted = false;
        }

        root.available = true;
        root.value = clamped;
        root.trackedAudio.volume = clamped;
        root._scheduleSync();
    }

    onMonitorEnabledChanged: {
        if (!monitorEnabled) {
            syncDebounce.stop();
            _clearState();
            return;
        }

        refresh();
    }

    Component.onCompleted: root.refresh()

    property Timer osdSuppressTimer: Timer {
        id: osdSuppressTimer
        interval: 450
        repeat: false
    }

    property Timer syncDebounce: Timer {
        id: syncDebounce
        interval: 20
        repeat: false
        onTriggered: root._syncFromPipewire()
    }

    property PwObjectTracker sinkTracker: PwObjectTracker {
        id: sinkTracker
        objects: Pipewire.nodes.values
    }

    property Connections pipewireConnection: Connections {
        target: Pipewire
        ignoreUnknownSignals: true

        function onReadyChanged() {
            root._scheduleSync();
        }

        function onDefaultAudioSinkChanged() {
            root._scheduleSync();
        }
    }

    property Connections pipewireNodesConnection: Connections {
        target: Pipewire.nodes
        ignoreUnknownSignals: true

        function onValuesChanged() {
            root._scheduleSync();
        }
    }

    property Connections sinkConnection: Connections {
        target: root.trackedSink
        ignoreUnknownSignals: true

        function onReadyChanged() {
            root._scheduleSync();
        }

        function onAudioChanged() {
            root._scheduleSync();
        }
    }

    property Connections audioConnection: Connections {
        target: root.trackedAudio
        ignoreUnknownSignals: true

        function onVolumeChanged() {
            root._scheduleSync();
        }

        function onMutedChanged() {
            root._scheduleSync();
        }
    }
}
