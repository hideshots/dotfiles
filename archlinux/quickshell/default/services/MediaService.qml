pragma Singleton

import QtQuick
import Quickshell.Services.Mpris

QtObject {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var activePlayer: root._resolveActivePlayer()
    readonly property bool available: !!activePlayer
    readonly property bool playing: !!activePlayer && activePlayer.playbackState === MprisPlaybackState.Playing
    readonly property string artist: root.available ? String(root.activePlayer.trackArtist || "") : ""
    readonly property string title: root.available ? String(root.activePlayer.trackTitle || "") : ""
    readonly property string artUrl: root.available ? String(root.activePlayer.trackArtUrl || "") : ""
    readonly property string currentPlayer: root._playerName(root.activePlayer)

    function _playersArray() {
        var values = Mpris.players.values;
        if (!values || values.length === undefined || values.length === null) {
            return [];
        }

        return values;
    }

    function _playerName(player) {
        if (!player) {
            return "";
        }

        var identity = String(player.identity || "").trim();
        if (identity.length > 0) {
            return identity;
        }

        var desktopEntry = String(player.desktopEntry || "").trim();
        if (desktopEntry.length > 0) {
            return desktopEntry;
        }

        return String(player.dbusName || "").trim();
    }

    function _hasTrackMetadata(player) {
        if (!player) {
            return false;
        }

        return String(player.trackTitle || "").trim().length > 0 || String(player.trackArtist || "").trim().length > 0;
    }

    function _resolveActivePlayer() {
        var players = root._playersArray();
        var firstPaused = null;
        var firstWithMetadata = null;

        for (var i = 0; i < players.length; i++) {
            var player = players[i];
            if (!player) {
                continue;
            }

            if (player.playbackState === MprisPlaybackState.Playing) {
                return player;
            }

            if (player.playbackState === MprisPlaybackState.Paused && firstPaused === null) {
                firstPaused = player;
            }

            if (firstWithMetadata === null && root._hasTrackMetadata(player)) {
                firstWithMetadata = player;
            }
        }

        return firstPaused || firstWithMetadata || null;
    }

    function playPause() {
        if (root.activePlayer && root.activePlayer.canTogglePlaying) {
            root.activePlayer.togglePlaying();
        }
    }

    function next() {
        if (root.activePlayer && root.activePlayer.canGoNext) {
            root.activePlayer.next();
        }
    }

    function previous() {
        if (root.activePlayer && root.activePlayer.canGoPrevious) {
            root.activePlayer.previous();
        }
    }
}
