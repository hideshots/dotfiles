import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland

Row {
    id: root
    spacing: 0

    required property var screen
    readonly property string screenName: screen?.name ?? ""

    property int refreshCounter: 0

    property var classLabelOverrides: ({
        "org.gnome.Nautilus": "Files",
        "com.obsproject.Studio": "OBS Studio",
        "org.prismlauncher.PrismLauncher": "Prism Launcher",
        "Vmware": "VMware Workstation Pro",
        "spotify": "Spotify"

    })

    property bool refreshQueued: false
    property bool needWorkspaceRefresh: false

    property string pulseWorkspaceName: ""
    property bool pulseActive: false

    property int refreshDebounceMs: 120

    function windowClass(toplevel) {
        const ipc = toplevel?.lastIpcObject ?? null
        return ipc?.initialClass ?? ipc?.class ?? toplevel?.wayland?.appId ?? ""
    }

    function displayText(toplevel) {
        if (!toplevel) return ""
        const ipc = toplevel.lastIpcObject ?? null
        const cls = windowClass(toplevel)
        const override = classLabelOverrides[cls]
        if (override) return override
        return ipc?.initialTitle ?? toplevel.wayland?.appId ?? toplevel.title ?? ""
    }

    function activeWorkspaceNameOnThisMonitor() {
        const ws = Hyprland.workspaces.values.find(w =>
            w.monitor && w.monitor.name === root.screenName && w.focused
        )
        return ws?.name ?? ws?.lastIpcObject?.name ?? ""
    }

    function pulseWorkspaceByName(name) {
        if (!name) return
        root.pulseWorkspaceName = name
        root.pulseActive = true
        pulseTimer.restart()
    }

    Timer {
        id: pulseTimer
        interval: 180
        repeat: false
        onTriggered: root.pulseActive = false
    }

    function queueRefresh(refreshWorkspaces) {
        if (refreshWorkspaces)
            root.needWorkspaceRefresh = true
        if (root.refreshQueued)
            return
        root.refreshQueued = true
        refreshTimer.restart()
    }

    Timer {
        id: refreshTimer
        interval: root.refreshDebounceMs
        repeat: false
        onTriggered: {
            Hyprland.refreshToplevels()
            if (root.needWorkspaceRefresh)
                Hyprland.refreshWorkspaces()

            root.needWorkspaceRefresh = false
            Qt.callLater(() => {
                root.refreshCounter++
                root.refreshQueued = false
            })
        }
    }

    Component.onCompleted: {
        root.queueRefresh(true)
    }

    Connections {
        target: Hyprland.workspaces
        function onObjectInsertedPost() { root.queueRefresh(true) }
        function onObjectRemovedPost() { root.queueRefresh(true) }
    }

    Connections {
        target: Hyprland.toplevels
        function onObjectInsertedPost() { root.queueRefresh(true) }
        function onObjectRemovedPost() { root.queueRefresh(true) }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name

            const pulseEvents = [
                "movewindow",
                "changefloatingmode",
                "fullscreen",
                "urgent",
                "pin",
                "minimized",
                "configreloaded"
            ]

            const workspaceRefreshEvents = [
                "movewindow",
                "workspace",
                "workspacev2",
                "focusedmon",
                "focusedmonv2",
                "createworkspace",
                "createworkspacev2",
                "destroyworkspace",
                "destroyworkspacev2",
                "moveworkspace",
                "moveworkspacev2",
                "renameworkspace"
            ]

            if (pulseEvents.includes(n)) {
                root.pulseWorkspaceByName(root.activeWorkspaceNameOnThisMonitor())
                root.queueRefresh(workspaceRefreshEvents.includes(n))
                return
            }

            if (n === "custom") {
                root.pulseWorkspaceByName(root.activeWorkspaceNameOnThisMonitor())
                root.queueRefresh(false)
                return
            }
        }
    }

function getLargestWindow(workspace) {
    if (!workspace || !workspace.toplevels) return null

    const toplevels = workspace.toplevels.values
    if (!toplevels || toplevels.length === 0) return null

    let best = null
    let bestArea = -1
    let bestX = Number.POSITIVE_INFINITY

    for (let i = 0; i < toplevels.length; i++) {
        const t = toplevels[i]
        const ipc = t?.lastIpcObject
        if (!ipc) continue

        const size = ipc.size
        if (!size || size.length < 2) continue

        const area = size[0] * size[1]

        const at = ipc.at
        const x = (at && at.length >= 1) ? at[0] : Number.POSITIVE_INFINITY

        if (area > bestArea || (area === bestArea && x < bestX)) {
            bestArea = area
            bestX = x
            best = t
        }
    }

    return best
}

    Repeater {
        model: Hyprland.workspaces.values.filter(ws =>
            ws.monitor && ws.monitor.name === root.screenName
        )

        delegate: Rectangle {
            required property var modelData

            property var largestWindow: {
                root.refreshCounter
                return root.getLargestWindow(modelData)
            }

            property bool pulsing: root.pulseActive && (modelData.name === root.pulseWorkspaceName)

            visible: largestWindow !== null && windowText.text !== ""
            height: root.height
            width: widthCalculator.width + (Theme.itemPadding * 2)

            color: windowMouseArea.containsMouse
                ? Qt.rgba(1, 1, 1, 0.1)
                : (pulsing
                    ? Qt.rgba(Theme.menuHighlight.r, Theme.menuHighlight.g, Theme.menuHighlight.b, 0.7)
                    : "transparent")

            radius: Theme.borderRadius

            Behavior on color {
                ColorAnimation {
                    duration: Theme.animationDuration
                    easing.type: Theme.animationEasing
                }
            }

            Text {
                id: widthCalculator
                visible: false
                text: root.displayText(largestWindow)
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                font.weight: Font.Bold
            }

            Text {
                id: windowText
                anchors.centerIn: parent
                text: root.displayText(largestWindow)
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
