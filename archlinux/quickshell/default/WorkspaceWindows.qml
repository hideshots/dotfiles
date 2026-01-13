import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland

Row {
    id: root
    spacing: 0

    // Counter to force re-evaluation of largestWindow
    property int refreshCounter: 0

    Component.onCompleted: {
        // Refresh toplevel data on startup to populate lastIpcObject
        Hyprland.refreshToplevels()
    }

    // Refresh when workspaces change
    Connections {
        target: Hyprland.workspaces
        function onObjectInsertedPost() {
            Hyprland.refreshToplevels()
            root.refreshCounter++
        }
        function onObjectRemovedPost() {
            Hyprland.refreshToplevels()
            root.refreshCounter++
        }
    }

    // Refresh when toplevels (windows) change
    Connections {
        target: Hyprland.toplevels
        function onObjectInsertedPost() {
            Hyprland.refreshToplevels()
            root.refreshCounter++
        }
        function onObjectRemovedPost() {
            Hyprland.refreshToplevels()
            root.refreshCounter++
        }
    }

    // Listen to all Hyprland events for window changes
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            // Events that affect window sizes or workspace contents
            const refreshEvents = [
                "movewindow",
                "resizewindow",
                "changefloatingmode",
                "fullscreen",
                "movetoworkspace",
                "movetoworkspacesilent",
                "workspacev2"
            ]

            if (refreshEvents.includes(event.name)) {
                Hyprland.refreshToplevels()
                root.refreshCounter++
            }
        }
    }

    // Function to find the largest window in a workspace
    function getLargestWindow(workspace) {
        if (!workspace || !workspace.toplevels) return null

        const toplevels = workspace.toplevels.values
        if (!toplevels || toplevels.length === 0) return null

        let largest = null
        let maxArea = 0

        for (let i = 0; i < toplevels.length; i++) {
            const toplevel = toplevels[i]
            if (!toplevel || !toplevel.lastIpcObject) continue

            const size = toplevel.lastIpcObject.size
            if (!size || size.length < 2) continue

            const area = size[0] * size[1]
            if (area > maxArea) {
                maxArea = area
                largest = toplevel
            }
        }

        return largest
    }

    Repeater {
        model: Hyprland.workspaces.values

        delegate: Rectangle {
            required property var modelData

            // Include refreshCounter in binding to force re-evaluation
            property var largestWindow: {
                root.refreshCounter // Force dependency
                return root.getLargestWindow(modelData)
            }

            visible: largestWindow !== null && windowText.text !== ""
            height: root.height
            width: widthCalculator.width + (Theme.itemPadding * 2)
            color: windowMouseArea.containsMouse ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
            radius: Theme.borderRadius

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationDuration
                    easing.type: Theme.animationEasing
                }
            }

            // Hidden text for width calculation (always bold)
            Text {
                id: widthCalculator
                visible: false
                text: largestWindow ? (largestWindow.wayland?.appId ?? largestWindow.title ?? "") : ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
            }

            Text {
                id: windowText
                anchors.centerIn: parent
                text: largestWindow ? (largestWindow.wayland?.appId ?? largestWindow.title ?? "") : ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                renderType: Text.NativeRendering
                font.weight: modelData.focused ? Font.Bold : Font.Medium
                color: Theme.textPrimary
            }

            DropShadow {
                anchors.fill: windowText
                source: windowText
                visible: Theme.isDark
                horizontalOffset: Theme.shadowHorizontalOffset
                verticalOffset: Theme.shadowVerticalOffset
                radius: Theme.shadowRadius
                samples: 16
                spread: 0
                color: Theme.shadowColor
            }

            MouseArea {
                id: windowMouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    if (largestWindow) {
                        modelData.activate()
                    }
                }
            }
        }
    }
}
