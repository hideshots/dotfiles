import Quickshell
import Quickshell.Hyprland
import QtQuick
import Qt5Compat.GraphicalEffects
import "menu"

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
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

                        Row {
                            id: leftSection
                            spacing: 0
                            height: parent.height

                            // Apple logo
                            Rectangle {
                                id: logoRect
                                width: 35
                                height: 26
                                color: logoMouseArea.containsMouse || logoMenu.visible
                                    ? Qt.rgba(255, 255, 255, 0.1)
                                    : (logoMouseArea.pressed ? Qt.rgba(255, 255, 255, 0.05) : "transparent")
                                radius: Theme.borderRadius

                                Behavior on color {
                                    ColorAnimation {
                                        duration: Theme.animationDuration
                                        easing.type: Theme.animationEasing
                                    }
                                }

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
                                    onClicked: logoMenu.toggle()
                                }
                            }

                            // Workspace windows (filtered per monitor)
                            WorkspaceWindows {
                                height: parent.height
                                screen: modelData
                            }
                        }

                        // Logo Menu - positioned as a popup window
                        MenuPopup {
                            id: logoMenu
                            anchorItem: logoRect
                            yOffset: 8

                            model: [
                                { type: "action", icon: "􀣺", label: "About This Mac" },
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

                        // Spacer to push right section to the end
                        Item {
                            width: parent.width - leftSection.width - rightSection.width
                            height: parent.height
                        }

                        // Right section - System controls
                        Row {
                            id: rightSection
                            spacing: 0
                            height: parent.height

                            IconButton { icon: "􀙇"; onClicked: {} }
                            IconButton { icon: "􀊫"; onClicked: {} }
                            IconButton { icon: "􀉭"; onClicked: {} }
                            IconButton { icon: "􀜊"; onClicked: {} }

                            TimeDisplay { height: parent.height }
                        }
                    }
                }
            }
        }
    }
}
