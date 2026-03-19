pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell.Services.Pipewire

QtObject {
    id: root

    property bool micBackendActive: false
    property bool cameraBackendActive: false
    property bool systemAudioRecordingBackendActive: false
    property bool screenShareBackendActive: false
    property bool locationBackendActive: false
    property var activeAppsBackend: []

    property bool debugOverridesEnabled: false
    property bool debugMicActive: false
    property bool debugCameraActive: false
    property bool debugSystemAudioRecordingActive: false
    property bool debugScreenShareActive: false
    property bool debugLocationActive: false
    property var debugActiveApps: []

    property bool recomputePending: false

    readonly property bool micActive: debugOverridesEnabled ? debugMicActive : micBackendActive
    readonly property bool cameraActive: debugOverridesEnabled ? debugCameraActive : cameraBackendActive
    readonly property bool systemAudioRecordingActive: debugOverridesEnabled ? debugSystemAudioRecordingActive : systemAudioRecordingBackendActive
    readonly property bool screenShareActive: debugOverridesEnabled ? debugScreenShareActive : screenShareBackendActive
    readonly property bool locationActive: debugOverridesEnabled ? debugLocationActive : locationBackendActive
    readonly property var activeApps: debugOverridesEnabled ? _normalizedApps(debugActiveApps) : _normalizedApps(activeAppsBackend)

    readonly property var state: ({
            micActive: root.micActive,
            cameraActive: root.cameraActive,
            systemAudioRecordingActive: root.systemAudioRecordingActive,
            screenShareActive: root.screenShareActive,
            locationActive: root.locationActive,
            activeApps: root.activeApps
        })

    readonly property bool purpleIndicatorActive: root.systemAudioRecordingActive || root.screenShareActive
    readonly property string activePrimaryKind: root.purpleIndicatorActive ? "systemAudio" : (root.micActive ? "mic" : (root.cameraActive ? "camera" : (root.locationActive ? "location" : "none")))
    readonly property string activeDotKind: root.activePrimaryKind === "location" ? "none" : root.activePrimaryKind
    readonly property bool anyActive: root.activePrimaryKind !== "none"

    function _safeString(value) {
        if (value === undefined || value === null) {
            return "";
        }

        return String(value);
    }

    function _trimmedString(value) {
        return _safeString(value).trim();
    }

    function _hasPrefix(value, prefix) {
        var text = _safeString(value);
        return text.length >= prefix.length && text.slice(0, prefix.length) === prefix;
    }

    function _isTruthy(value) {
        if (value === true || value === 1) {
            return true;
        }

        var text = _safeString(value).trim().toLowerCase();
        return text === "true" || text === "yes" || text === "1";
    }

    function _nodeProperties(node) {
        if (!node || !node.ready) {
            return ({})
        }

        return node.properties || ({})
    }

    function _nodeMediaClass(node) {
        return _safeString(_nodeProperties(node)["media.class"]);
    }

    function _nodeMediaRole(node) {
        return _safeString(_nodeProperties(node)["media.role"]);
    }

    function _looksSyntheticNodeName(value) {
        var name = _trimmedString(value);
        if (name.length === 0) {
            return true;
        }

        if (name.indexOf(":") >= 0) {
            return true;
        }

        return false;
    }

    function _canonicalAppName(value) {
        var raw = _trimmedString(value);
        if (raw.length === 0) {
            return "";
        }

        var lower = raw.toLowerCase();
        if (lower === "obs" || lower === "obs-studio" || lower === "obs studio") {
            return "OBS Studio";
        }

        return raw;
    }

    function _streamAppName(node) {
        var props = _nodeProperties(node);

        var appName = _canonicalAppName(props["application.name"]);
        if (appName.length > 0) {
            return appName;
        }

        var mediaName = _canonicalAppName(props["media.name"]);
        if (mediaName.length > 0) {
            return mediaName;
        }

        var processName = _canonicalAppName(props["application.process.binary"]);
        if (processName.length > 0) {
            return processName;
        }

        var nodeName = _canonicalAppName(node ? node.name : "");
        if (!_looksSyntheticNodeName(nodeName)) {
            return nodeName;
        }

        return "";
    }

    function _normalizedApps(values) {
        if (!Array.isArray(values)) {
            return [];
        }

        var normalized = [];
        var seen = ({})

        for (var i = 0; i < values.length; i++) {
            var text = _trimmedString(values[i]);
            if (text.length === 0) {
                continue;
            }

            var key = text.toLowerCase();
            if (seen[key]) {
                continue;
            }

            seen[key] = true;
            normalized.push(text);
        }

        return normalized;
    }

    function _activeIncomingSourcesByTargetId(nodes, links) {
        var byTarget = ({})

        for (var i = 0; i < links.length; i++) {
            var link = links[i];
            if (!link || link.state !== PwLinkState.Active) {
                continue;
            }

            var source = link.source;
            var target = link.target;
            if (!source || !target || !source.ready || !target.ready) {
                continue;
            }

            var key = String(target.id);
            if (!Array.isArray(byTarget[key])) {
                byTarget[key] = [];
            }

            byTarget[key].push(source);
        }

        return byTarget;
    }

    function _recomputeBackendState() {
        if (!Pipewire.ready) {
            root.micBackendActive = false;
            root.cameraBackendActive = false;
            root.systemAudioRecordingBackendActive = false;
            root.screenShareBackendActive = false;
            root.locationBackendActive = false;
            root.activeAppsBackend = [];
            return;
        }

        var nodes = nodeTracker.objects || [];
        var links = linkTracker.objects || [];
        var incomingByTarget = _activeIncomingSourcesByTargetId(nodes, links);

        var micActive = false;
        var cameraActive = false;
        var systemAudioActive = false;
        var screenShareActive = false;
        var apps = [];

        function addApp(name) {
            apps.push(name);
        }

        for (var i = 0; i < nodes.length; i++) {
            var node = nodes[i];
            if (!node || !node.ready) {
                continue;
            }

            var props = _nodeProperties(node);
            var mediaClass = _safeString(props["media.class"]);

            if (mediaClass === "Stream/Input/Audio") {
                var sourceNodes = incomingByTarget[String(node.id)] || [];
                var hasAudioSourceInput = false;
                var hasAudioSinkInput = false;

                for (var ai = 0; ai < sourceNodes.length; ai++) {
                    var sourceNode = sourceNodes[ai];
                    var sourceClass = _nodeMediaClass(sourceNode);
                    if (_hasPrefix(sourceClass, "Audio/Source")) {
                        hasAudioSourceInput = true;
                    }
                    if (_hasPrefix(sourceClass, "Audio/Sink")) {
                        hasAudioSinkInput = true;
                    }
                }

                var capturesSink = _isTruthy(props["stream.capture.sink"]);
                if (capturesSink || hasAudioSinkInput) {
                    systemAudioActive = true;
                    addApp(_streamAppName(node));
                } else if (hasAudioSourceInput) {
                    micActive = true;
                    addApp(_streamAppName(node));
                }

                continue;
            }

            if (mediaClass !== "Stream/Input/Video") {
                continue;
            }

            var videoSourceNodes = incomingByTarget[String(node.id)] || [];
            if (!Array.isArray(videoSourceNodes) || videoSourceNodes.length === 0) {
                continue;
            }

            var streamRole = _safeString(props["media.role"]);
            var streamTarget = _safeString(props["target.object"]);
            if (streamTarget.length === 0) {
                streamTarget = _safeString(props["node.target"]);
            }

            var videoKind = "";
            if (streamRole === "Screen") {
                videoKind = "screen";
            } else if (streamRole === "Camera") {
                videoKind = "camera";
            }

            for (var vi = 0; vi < videoSourceNodes.length && videoKind.length === 0; vi++) {
                var videoSourceNode = videoSourceNodes[vi];
                var sourceRole = _nodeMediaRole(videoSourceNode);
                var sourceName = _safeString(videoSourceNode ? videoSourceNode.name : "");
                var sourceMediaName = _safeString(_nodeProperties(videoSourceNode)["media.name"]);

                if (sourceRole === "Screen") {
                    videoKind = "screen";
                    break;
                }
                if (sourceRole === "Camera") {
                    videoKind = "camera";
                    break;
                }
                if (sourceName.indexOf("xdg-desktop-portal") >= 0 || sourceMediaName.indexOf("xdph-streaming") >= 0) {
                    videoKind = "screen";
                    break;
                }
            }

            if (videoKind.length === 0) {
                if (streamTarget.indexOf("xdg-desktop-portal") >= 0 || streamTarget.indexOf("xdph-streaming") >= 0) {
                    videoKind = "screen";
                } else {
                    videoKind = "camera";
                }
            }

            if (videoKind === "screen") {
                screenShareActive = true;
                addApp(_streamAppName(node));
            } else if (videoKind === "camera") {
                cameraActive = true;
                addApp(_streamAppName(node));
            }
        }

        root.micBackendActive = micActive;
        root.cameraBackendActive = cameraActive;
        root.systemAudioRecordingBackendActive = systemAudioActive;
        root.screenShareBackendActive = screenShareActive;
        root.locationBackendActive = false;
        root.activeAppsBackend = _normalizedApps(apps);
    }

    function _scheduleRecompute() {
        if (root.recomputePending) {
            return;
        }

        root.recomputePending = true;
        recomputeDebounce.restart();
    }


    property Timer recomputeDebounce: Timer {
        id: recomputeDebounce
        interval: 80
        repeat: false
        onTriggered: {
            root.recomputePending = false;
            root._recomputeBackendState();
        }
    }

    property Timer periodicRecomputeTimer: Timer {
        interval: 2000
        repeat: true
        running: true
        onTriggered: root._scheduleRecompute()
    }


    property Connections pipewireReadyConnection: Connections {
        target: Pipewire
        function onReadyChanged() {
            root._scheduleRecompute();
        }
    }

    property Connections pipewireNodesConnection: Connections {
        target: Pipewire.nodes
        function onValuesChanged() {
            root._scheduleRecompute();
        }
    }

    property Connections pipewireLinksConnection: Connections {
        target: Pipewire.links
        function onValuesChanged() {
            root._scheduleRecompute();
        }
    }

    property PwObjectTracker nodeTracker: PwObjectTracker {
        id: nodeTracker
        objects: Pipewire.nodes.values
    }

    property PwObjectTracker linkTracker: PwObjectTracker {
        id: linkTracker
        objects: Pipewire.links.values
    }

    property Instantiator nodeSignalTracker: Instantiator {
        model: nodeTracker.objects
        delegate: QtObject {
            id: nodeDelegate
            required property var modelData
            property var trackedNode: modelData

            property Connections nodeConnections: Connections {
                target: nodeDelegate.trackedNode
                function onReadyChanged() {
                    root._scheduleRecompute();
                }
                function onPropertiesChanged() {
                    root._scheduleRecompute();
                }
            }
        }
    }

    property Instantiator linkSignalTracker: Instantiator {
        model: linkTracker.objects
        delegate: QtObject {
            id: linkDelegate
            required property var modelData
            property var trackedLink: modelData

            property Connections linkConnections: Connections {
                target: linkDelegate.trackedLink
                function onStateChanged() {
                    root._scheduleRecompute();
                }
            }
        }
    }

    Component.onCompleted: root._scheduleRecompute()
}
