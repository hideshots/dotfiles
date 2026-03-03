import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property bool available: false
    property bool playing: false
    property string artist: ""
    property string title: ""
    property string artUrl: ""
    property string currentPlayer: ""
    property bool monitorEnabled: true

    readonly property var metadataCommand: [
        "playerctl",
        "--player",
        "spotify,mpd,%any",
        "metadata",
        "--follow",
        "--format",
        "{{status}}\t{{artist}}\t{{title}}\t{{mpris:artUrl}}\t{{playerName}}"
    ]

    function _clearState() {
        root.available = false;
        root.playing = false;
        root.artist = "";
        root.title = "";
        root.artUrl = "";
        root.currentPlayer = "";
    }

    function _field(parts, index) {
        if (!parts || index < 0 || index >= parts.length) {
            return "";
        }
        var value = parts[index];
        if (value === undefined || value === null) {
            return "";
        }
        return String(value).trim();
    }

    function _applyMetadataLine(data) {
        var line = data === undefined || data === null ? "" : String(data).trim();
        if (line.length === 0) {
            _clearState();
            return;
        }

        var parts = line.split("\t");
        var status = _field(parts, 0);
        if (status.length === 0 || status.toLowerCase().indexOf("no players") === 0) {
            _clearState();
            return;
        }

        root.available = true;
        root.playing = status === "Playing";
        root.artist = _field(parts, 1);
        root.title = _field(parts, 2);
        root.artUrl = _field(parts, 3);
        root.currentPlayer = _field(parts, 4);
    }

    function _startMonitor() {
        if (!root.monitorEnabled || metadataProcess.running) {
            return;
        }
        metadataProcess.exec(root.metadataCommand);
    }

    function _runAction(command) {
        if (actionProcess.running) {
            return;
        }
        actionProcess.exec(command);
    }

    function _actionCommand(action) {
        var player = root.currentPlayer ? String(root.currentPlayer).trim() : "";
        if (player.length > 0) {
            return ["playerctl", "--player", player, action];
        }
        return ["playerctl", "--player", "spotify,mpd,%any", action];
    }

    function playPause() {
        _runAction(_actionCommand("play-pause"));
    }

    function next() {
        _runAction(_actionCommand("next"));
    }

    function previous() {
        _runAction(_actionCommand("previous"));
    }

    onMonitorEnabledChanged: {
        if (!monitorEnabled) {
            restartTimer.stop();
            _clearState();
            if (metadataProcess.running) {
                metadataProcess.signal(15);
            }
            return;
        }
        _startMonitor();
    }

    Component.onCompleted: _startMonitor()

    property Process metadataProcess: Process {
        id: metadataProcess

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                root._applyMetadataLine(data);
            }
        }

        stderr: SplitParser {
            splitMarker: "\n"
            onRead: function (data) {
                var line = data === undefined || data === null ? "" : String(data).trim().toLowerCase();
                if (line.indexOf("no players") >= 0) {
                    root._clearState();
                }
            }
        }

        onRunningChanged: {
            if (!running && root.monitorEnabled) {
                restartTimer.restart();
            }
        }
    }

    property Process actionProcess: Process {
        id: actionProcess
    }

    property Timer restartTimer: Timer {
        id: restartTimer
        interval: 2000
        repeat: false
        onTriggered: root._startMonitor()
    }
}
