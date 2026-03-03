import QtQuick

import "providers" as Providers
import "tiles" as Tiles

Item {
    id: root

    property bool showStateGallery: false
    property bool floorLampChecked: false
    property bool focusChecked: false
    property bool cameraChecked: false
    property real displayValue: 0.68

    implicitWidth: 825
    implicitHeight: 293
    width: implicitWidth
    height: implicitHeight

    Providers.NowPlayingProvider {
        id: nowPlayingProvider
    }

    Tiles.NowPlayingTile140 {
        x: 0
        y: 1
        provider: nowPlayingProvider
    }

    Tiles.ToggleTile140 {
        x: 152
        y: 1
        symbol: "􀛮"
        title: "Floor Lamp"
        detail: checked ? "On" : "Off"
        checked: root.floorLampChecked
        onToggled: function (nextChecked) {
            root.floorLampChecked = nextChecked;
        }
    }

    Tiles.ToggleTile140x64 {
        x: 304
        y: 0
        symbol: "􀆺"
        title: "Focus"
        detail: checked ? "On" : "Off"
        checked: root.focusChecked
        onToggled: function (nextChecked) {
            root.focusChecked = nextChecked;
        }
    }

    Tiles.RoundAction64 {
        x: 456
        y: 0
        symbol: "􀌟"
        checked: root.cameraChecked
        onToggled: function (nextChecked) {
            root.cameraChecked = nextChecked;
        }
    }

    Tiles.SliderTile292x64 {
        x: 532
        y: 0
        title: "Display"
        value: root.displayValue
        onValueChangedByUser: function (nextValue) {
            root.displayValue = nextValue;
        }
    }

    Item {
        visible: root.showStateGallery

        Tiles.ToggleTile140 {
            x: 152
            y: 76
            symbol: "􀛮"
            title: "Floor Lamp"
            detail: "On"
            checked: true
        }

        Tiles.ToggleTile140x64 {
            x: 304
            y: 76
            symbol: "􀆺"
            title: "Focus"
            detail: "On"
            checked: true
        }

        Tiles.RoundAction64 {
            x: 456
            y: 76
            symbol: "􀌟"
            checked: true
        }

        Tiles.SliderTile292x64 {
            x: 532
            y: 76
            title: "Display"
            value: 0.36
        }

        Tiles.NowPlayingTile140 {
            x: 0
            y: 153
        }

        Tiles.ToggleTile140 {
            x: 152
            y: 153
            symbol: "􀛮"
            title: "Floor Lamp"
            detail: "Off"
            checked: false
        }

        Tiles.ToggleTile140x64 {
            x: 304
            y: 153
            symbol: "􀆺"
            title: "Focus"
            detail: "Off"
            checked: false
        }

        Tiles.RoundAction64 {
            x: 456
            y: 153
            symbol: "􀌟"
            checked: false
        }

        Tiles.SliderTile292x64 {
            x: 532
            y: 153
            title: "Display"
            value: 0.74
        }
    }
}
