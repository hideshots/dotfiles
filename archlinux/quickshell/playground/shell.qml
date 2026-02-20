pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "widgets" as Widgets

ShellRoot {
    id: shell

    property string weatherLocation: "Krasnodar"
    property string weatherDisplayLocation: "Richmond"
    property string weatherUnits: "u"
    property string weatherVariant: "small"

    PanelWindow {
        id: weatherPanel

        anchors.top: true
        anchors.left: true
        margins.top: 50
        margins.left: 10
        exclusionMode: ExclusionMode.Ignore

        color: "transparent"
        surfaceFormat.opaque: false
        focusable: false
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        WlrLayershell.namespace: "quickshell:weather"
        HyprlandWindow.visibleMask: weatherMask

        implicitWidth: weatherWidget.implicitWidth
        implicitHeight: weatherWidget.implicitHeight

        Region {
            id: weatherMask
            item: weatherWidget
        }

        Widgets.WeatherWidget {
            id: weatherWidget
            anchors.fill: parent
            location: shell.weatherLocation
            displayLocation: shell.weatherDisplayLocation
            units: shell.weatherUnits
            variant: shell.weatherVariant
        }
    }
}
