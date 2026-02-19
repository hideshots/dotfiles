import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Hyprland

Row {
    id: root
    spacing: 0

    required property var screen
    readonly property string screenName: screen?.name ?? ""
    property var highlightState: null

    property int refreshCounter: 0

    property var classLabelOverrides: ({
        "org.gnome.Nautilus": "Files",
        "com.obsproject.Studio": "OBS Studio",
        "org.prismlauncher.PrismLauncher": "Prism Launcher",
        "Vmware": "VMware Workstation Pro",
        "obsidian": "Obsidian",
        "org.gnome.Loupe": "Preview",
        "kitty": "Terminal",
        "spotify": "Spotify"

    })

    property bool refreshQueued: false
    property bool needWorkspaceRefresh: false

    property string pulseWorkspaceName: ""
    property bool pulseActive: false
    property var lastFocusedAddrByMonitor: ({})
    readonly property bool macosMode: Theme.workspaceWindowsMode === "macos"

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
            w.monitor && w.monitor.name === root.screenName && w.active
        )
        return ws?.name ?? ws?.lastIpcObject?.name ?? ""
    }

    function workspaceNumericId(ws) {
        const id = ws?.id ?? ws?.lastIpcObject?.id
        const num = Number(id)
        return Number.isNaN(num) ? -1 : num
    }

    function isNormalWorkspaceOnThisMonitor(ws) {
        return ws?.monitor && ws.monitor.name === root.screenName && workspaceNumericId(ws) >= 0
    }

    function isNonEmptyWorkspace(ws) {
        return !!(ws?.toplevels?.values && ws.toplevels.values.length > 0)
    }

    function activeWorkspaceOnThisMonitor() {
        return Hyprland.workspaces.values.find(w => isNormalWorkspaceOnThisMonitor(w) && w.active) ?? null
    }

    function normalizeAddr(a) {
        if (!a) return ""
        let s = String(a)
        const idx = s.indexOf(">>")
        if (idx >= 0) s = s.slice(idx + 2)
        s = s.trim()
        if (s.startsWith("0x") || s.startsWith("0X")) s = s.slice(2)
        return s.toLowerCase()
    }

    function toplevelAddr(t) {
        const a = t?.address ?? ""
        return normalizeAddr(a)
    }

    function updateMap(obj, key, value) {
        const next = Object.assign({}, obj)
        next[key] = value
        return next
    }

    function activeWsForThisScreen() {
        const mon = Hyprland.monitorFor(root.screen)
        if (mon?.activeWorkspace)
            return mon.activeWorkspace
        return root.activeWorkspaceOnThisMonitor()
    }

    function focusedAddrForThisScreen() {
        return root.lastFocusedAddrByMonitor[root.screenName] ?? ""
    }

    function focusedToplevelOnThisScreen() {
        const ws = root.activeWsForThisScreen()
        if (!ws?.toplevels?.values || ws.toplevels.values.length === 0) return null

        const addr = normalizeAddr(root.focusedAddrForThisScreen())
        if (addr) {
            for (let i = 0; i < ws.toplevels.values.length; i++) {
                const t = ws.toplevels.values[i]
                if (toplevelAddr(t) === addr) return t
            }
        }

        return root.getLargestWindow(ws)
    }

    function mostRecentWindowInWorkspace(ws) {
        if (!ws?.toplevels?.values || ws.toplevels.values.length === 0) return null

        let best = null
        let bestFocusHistory = Number.NEGATIVE_INFINITY
        let foundFocusHistory = false

        for (let i = 0; i < ws.toplevels.values.length; i++) {
            const t = ws.toplevels.values[i]
            const ipc = t?.lastIpcObject ?? null
            const raw = ipc?.focusHistoryID ?? ipc?.focusHistoryId
            if (raw === undefined || raw === null) continue

            const focusHistory = Number(raw)
            if (Number.isNaN(focusHistory)) continue

            foundFocusHistory = true
            if (focusHistory > bestFocusHistory) {
                bestFocusHistory = focusHistory
                best = t
            }
        }

        if (foundFocusHistory)
            return best
        return root.getLargestWindow(ws)
    }

    function macosWorkspaceModel() {
        root.refreshCounter
        const activeWs = root.activeWorkspaceOnThisMonitor()
        const activeId = workspaceNumericId(activeWs)

        const candidates = Hyprland.workspaces.values.filter(ws =>
            isNormalWorkspaceOnThisMonitor(ws) &&
            isNonEmptyWorkspace(ws) &&
            workspaceNumericId(ws) !== activeId
        ).sort((a, b) => workspaceNumericId(a) - workspaceNumericId(b))

        if (activeId < 0)
            return candidates

        const lower = candidates.filter(ws => workspaceNumericId(ws) < activeId)
        const higher = candidates.filter(ws => workspaceNumericId(ws) > activeId)
        return lower.concat(higher)
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
            const data = event.data === undefined || event.data === null ? "" : String(event.data)

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

            if (n === "activewindowv2") {
                const addr = root.normalizeAddr(data)
                const monName = Hyprland.focusedMonitor?.name ?? ""
                if (monName && addr) {
                    root.lastFocusedAddrByMonitor = root.updateMap(root.lastFocusedAddrByMonitor, monName, addr)
                }
                root.queueRefresh(false)
                return
            }

            if (pulseEvents.includes(n)) {
                root.pulseWorkspaceByName(root.activeWorkspaceNameOnThisMonitor())
                root.queueRefresh(workspaceRefreshEvents.includes(n))
                return
            }

            if (
                n === "activewindow" ||
                n === "windowtitle" ||
                n === "windowtitlev2"
            ) {
                root.queueRefresh(false)
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

    Rectangle {
        id: currentFocusedWindowRoot

        property var currentWorkspace: {
            return root.activeWsForThisScreen()
        }
        property var currentFocusedWindow: {
            const _addr = root.lastFocusedAddrByMonitor[root.screenName]
            return root.focusedToplevelOnThisScreen()
        }
        property string currentFocusedLabel: {
            const _addr = root.lastFocusedAddrByMonitor[root.screenName]
            const t = currentFocusedWindowRoot.currentFocusedWindow
            return root.displayText(t)
        }
        property bool pulsing: {
            const currentWorkspaceName = currentWorkspace?.name ?? currentWorkspace?.lastIpcObject?.name ?? ""
            return root.macosMode && root.pulseActive && currentWorkspaceName === root.pulseWorkspaceName
        }

        visible: root.macosMode
            && currentFocusedWindowRoot.currentFocusedWindow !== null
            && currentFocusedWindowRoot.currentFocusedLabel !== ""
        height: root.height
        width: currentWidthCalculator.width + (Theme.itemPadding * 2)

        color: "transparent"
        radius: Theme.borderRadius

        onPulsingChanged: {
            if (!root.highlightState) return
            if (pulsing) {
                root.highlightState.pulseTarget = currentFocusedWindowRoot
            } else if (root.highlightState.pulseTarget === currentFocusedWindowRoot) {
                root.highlightState.pulseTarget = null
            }
        }
        Component.onCompleted: {
            if (!root.highlightState) return
            if (pulsing)
                root.highlightState.pulseTarget = currentFocusedWindowRoot
        }
        Component.onDestruction: {
            if (!root.highlightState) return
            if (root.highlightState.activeTarget === currentFocusedWindowRoot)
                root.highlightState.activeTarget = null
            if (root.highlightState.pulseTarget === currentFocusedWindowRoot)
                root.highlightState.pulseTarget = null
        }

        Text {
            id: currentWidthCalculator
            visible: false
            text: currentFocusedWindowRoot.currentFocusedLabel
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.Bold
        }

        Text {
            id: currentWindowText
            anchors.centerIn: parent
            text: currentFocusedWindowRoot.currentFocusedLabel
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            renderType: Text.NativeRendering
            font.weight: Font.Bold
            color: Theme.textPrimary
        }

        DropShadow {
            anchors.fill: currentWindowText
            source: currentWindowText
            visible: Theme.isDark
            horizontalOffset: Theme.shadowHorizontalOffset
            verticalOffset: Theme.shadowVerticalOffset
            radius: Theme.shadowRadius
            samples: 16
            spread: 0
            color: Theme.shadowColor
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                if (currentFocusedWindowRoot.currentWorkspace) {
                    currentFocusedWindowRoot.currentWorkspace.activate()
                }
            }
        }
    }

    Repeater {
        model: root.macosMode
            ? root.macosWorkspaceModel()
            : Hyprland.workspaces.values.filter(ws => root.isNormalWorkspaceOnThisMonitor(ws))

        delegate: Rectangle {
            id: delegateRoot
            required property var modelData

            property var largestWindow: {
                root.refreshCounter
                return root.getLargestWindow(modelData)
            }

            property bool pulsing: root.pulseActive && !root.macosMode && (modelData.name === root.pulseWorkspaceName)

            visible: largestWindow !== null && windowText.text !== ""
            height: root.height
            width: widthCalculator.width + (Theme.itemPadding * 2)

            color: "transparent"

            radius: Theme.borderRadius
            onPulsingChanged: {
                if (!root.highlightState) return
                if (pulsing) {
                    root.highlightState.pulseTarget = delegateRoot
                } else if (root.highlightState.pulseTarget === delegateRoot) {
                    root.highlightState.pulseTarget = null
                }
            }
            Component.onCompleted: {
                if (!root.highlightState) return
                if (pulsing)
                    root.highlightState.pulseTarget = delegateRoot
            }
            Component.onDestruction: {
                if (!root.highlightState) return
                if (root.highlightState.activeTarget === delegateRoot)
                    root.highlightState.activeTarget = null
                if (root.highlightState.pulseTarget === delegateRoot)
                    root.highlightState.pulseTarget = null
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
                font.weight: root.macosMode ? Font.Medium : (modelData.active ? Font.Bold : Font.Medium)
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
