import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import Qt5Compat.GraphicalEffects

import "menu" as Menu
import "widgets" as Widgets

ShellRoot {
    id: shell
    // Notifications { }
    property bool weatherEnabled: true
    property string weatherLocation: "Krasnodar"
    property string weatherDisplayLocation: "Richmond"
    property string weatherUnits: "u"
    property string weatherVariant: "medium"

    PanelWindow {
        id: weatherPanel
        visible: shell.weatherEnabled

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
            onRequestContextMenu: function(x, y) {
                weatherSizeMenu.anchorPointX = x + 4;
                weatherSizeMenu.anchorPointY = y + 8;
                weatherSizeMenu.anchor.updateAnchor();
                if (weatherSizeMenu.visible) {
                    weatherSizeMenu.close();
                }
                weatherSizeMenu.open();
            }
        }

        Menu.MenuPopup {
            id: weatherSizeMenu
            anchorItem: weatherWidget
            yOffset: 8
            adaptiveWidth: true
            model: [
                {
                    type: "action",
                    label: "Small",
                    reserveCheckmark: true,
                    checked: shell.weatherVariant === "small",
                    action: function() { shell.weatherVariant = "small"; }
                },
                {
                    type: "action",
                    label: "Medium",
                    reserveCheckmark: true,
                    checked: shell.weatherVariant === "medium",
                    action: function() { shell.weatherVariant = "medium"; }
                }
            ]
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
          WlrLayershell.namespace: "qsbar"
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 72
            color: "transparent"

            exclusiveZone: 36

            mask: Region { item: barHitbox }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 72
                color: "transparent"

                gradient: Gradient {
                  GradientStop { position: 0.00; color: Theme.isDark ? Qt.rgba(0,0,0,0.18) : Qt.rgba(1,1,1,0.12) }
                  GradientStop { position: 0.25; color: Theme.isDark ? Qt.rgba(0,0,0,0.10) : Qt.rgba(1,1,1,0.07) }
                  GradientStop { position: 0.60; color: Theme.isDark ? Qt.rgba(0,0,0,0.04) : Qt.rgba(1,1,1,0.01) }
                  GradientStop { position: 1.00; color: "transparent" }
                }
            }

            Item {
                id: barHitbox
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 36

                Rectangle {
                    anchors.fill: parent
                    color: Theme.background

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        anchors.topMargin: 5
                        anchors.bottomMargin: 5
                        spacing: 0

Item {
    id: leftSection
    height: parent.height
    width: leftRow.implicitWidth

    QtObject {
        id: leftHi
        property Item activeTarget: null
        property Item pulseTarget: null
        property bool pressed: false
    }

    // The macOS-like hover/pulse background ("pill")
    Rectangle {
        id: leftPill
        z: 0
        radius: Theme.borderRadius

        property Item target: leftHi.activeTarget ?? leftHi.pulseTarget

        x: target ? target.mapToItem(leftSection, 0, 0).x - Theme.hoverOverlap : 0
        y: 0
        width: target ? target.width + (Theme.hoverOverlap * 2) : 0
        height: parent.height

        color: leftHi.activeTarget
            ? Qt.rgba(1, 1, 1, 0.10)
            : (leftHi.pulseTarget
                ? Qt.rgba(Theme.menuHighlight.r, Theme.menuHighlight.g, Theme.menuHighlight.b, 0.70)
                : "transparent")

        opacity: target ? 1 : 0
    }

    Row {
        id: leftRow
        z: 1
        spacing: 0
        height: parent.height

        // Apple logo (remove per-item hover bg; let leftPill handle it)
        Rectangle {
            id: logoRect
            width: 35
            height: parent.height
            color: "transparent"
            radius: Theme.borderRadius

            Text {
                id: logoText
                anchors.centerIn: parent
                text: "􀆿"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.iconSize
                renderType: Text.NativeRendering
                color: Theme.textPrimary
            }

            DropShadow {
                anchors.fill: logoText
                source: logoText
                visible: Theme.isDark
                horizontalOffset: Theme.shadowHorizontalOffset
                verticalOffset: Theme.shadowVerticalOffset
                radius: Theme.shadowRadius
                samples: 16
                spread: 0
                color: Theme.shadowColor
            }

            MouseArea {
                id: logoMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onPressed: leftHi.pressed = true
                onReleased: leftHi.pressed = false

                onClicked: logoMenu.toggle()
            }
        }

        // Workspace windows (pass the state object down)
        WorkspaceWindows {
            height: parent.height
            screen: modelData
            highlightState: leftHi
        }
    }
}

                        // Logo Menu - positioned as a popup window
                        Menu.MenuPopup {
                            id: logoMenu
                            anchorItem: logoRect
                            yOffset: 8

                            model: [
                                { type: "action", icon: "􀙗", label: "About This Mac" },
                                { type: "separator" },
                                { type: "action", icon: "􀈎", label: "System Settings...", shortcut: ["􀆔", ","] },
                                { type: "action", icon: "􁣡", label: "App Store..." },
                                { type: "separator" },
                                { type: "action", label: "Applications", submenu: [
                                    { type: "action", label: "Finder" },
                                    { type: "action", label: "Safari" },
                                    { type: "action", label: "Terminal" }
                                ]},
                                { type: "action", label: "Documents", submenu: [
                                    { type: "action", label: "Downloads" },
                                    { type: "action", label: "Pictures" },
                                    { type: "action", label: "Music" }
                                ] },
                                { type: "separator" },
                                { type: "action", icon: "􀜗", label: "Force Quit...", shortcut: ["􀆕", "􀆔", "Q"] },
                                { type: "separator" },
                                { type: "action", icon: "􀎥", label: "Sleep" },
                                { type: "action", icon: "􀆨", label: "Restart..." },
                                { type: "action", icon: "􀷃", label: "Shut Down..." },
                                { type: "separator" },
                                { type: "action", icon: "􀙧", label: "Lock Screen", shortcut: ["􀆔", "Q"] },
                                { type: "action", icon: "􀉩", label: "Log Out", shortcut: ["􀆝", "􀆔", "Q"] }
                            ]

                            onItemClicked: function(item, index) {
                                console.log("Menu item clicked:", item.label)
                            }
                        }
                        Connections {
                            target: logoMenu
                            function onVisibleChanged() {
                                leftHi.activeTarget = logoMenu.visible ? logoRect : null
                            }
                        }

                        // Spacer to push right section to the end
                        Item {
                            width: parent.width - leftSection.width - rightSection.width
                            height: parent.height
                        }

                        // Right section - System controls
                        Item {
                            id: rightSection
                            height: parent.height
                            width: rightRow.implicitWidth

                            QtObject {
                                id: rightHi
                                property Item activeTarget: null
                                property Item pulseTarget: null
                            }

                            Rectangle {
                                id: rightPill
                                z: 0
                                radius: Theme.borderRadius

                                property Item target: rightHi.activeTarget ?? rightHi.pulseTarget

                                x: target ? target.mapToItem(rightSection, 0, 0).x - Theme.hoverOverlap : 0
                                y: 0
                                width: target ? target.width + (Theme.hoverOverlap * 2) : 0
                                height: parent.height

                                color: rightHi.activeTarget
                                    ? Qt.rgba(1, 1, 1, 0.10)
                                    : (rightHi.pulseTarget
                                        ? Qt.rgba(Theme.menuHighlight.r, Theme.menuHighlight.g, Theme.menuHighlight.b, 0.70)
                                        : "transparent")

                                opacity: target ? 1 : 0
                            }

                            Row {
                                id: rightRow
                                z: 1
                                spacing: 0
                                height: parent.height

                                // IconButton { icon: "􀙇"; highlightState: rightHi; onClicked: {} }
                                // IconButton { icon: "􀊫"; highlightState: rightHi; onClicked: {} }
                                // IconButton { icon: "􀉭"; highlightState: rightHi; onClicked: {} }
                                IconButton { icon: "􀜊"; highlightState: rightHi; onClicked: {} }

                                TimeDisplay { height: parent.height; highlightState: rightHi }
                            }
                        }
                    }
                }
            }
        }
    }
}
