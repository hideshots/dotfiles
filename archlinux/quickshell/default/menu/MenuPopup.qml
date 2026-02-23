import Quickshell
import Quickshell.Hyprland
import QtQuick
import Qt5Compat.GraphicalEffects

PopupWindow {
    id: root

    // Public API
    property var model: []
    property Item anchorItem: null
    property real anchorPointX: NaN
    property real anchorPointY: NaN
    property int yOffset: 6
    property string placement: "bottom" // bottom or right
    property bool adaptiveWidth: false

    // Signals
    signal itemClicked(var item, int index)

    property var topMenu: root
    readonly property bool isTopMenu: topMenu === root

    // Debug
    property bool debugGrabs: false
    property bool debugMenuPerf: false

    // Hover and submenu behavior
    property bool mouseInsideMenu: menuHoverHandler.hovered
    readonly property bool mouseInsideSubmenu: submenuTreeContainsMouse()
    readonly property bool treeContainsMouse: mouseInsideMenu || mouseInsideSubmenu

    property int submenuOpenDelayMs: 180
    property int submenuSwitchDelayMs: 80
    property int submenuCloseDelayMs: 180

    // Focus grab state
    property bool grabRequested: false
    property string grabSig: ""
    property int grabUpdateAssignments: 0

    // Submenu state
    property int activeSubmenuIndex: -1
    property var activeSubmenuModelRef: null
    property Item activeSubmenuAnchorRef: null

    property int pendingSubmenuIndex: -1
    property var pendingSubmenuModel: null
    property Item pendingSubmenuAnchor: null

    // Internal state
    property int hoveredIndex: -1
    property int selectedIndex: -1

    surfaceFormat.opaque: false
    color: "transparent"

    visible: false
    implicitWidth: adaptiveWidth ? menuContent.implicitWidth + 24 : Theme.menuWidth
    implicitHeight: menuContent.height + 10

    onVisibleChanged: {
        if (!visible && root.isTopMenu) {
            root.grabRequested = false
            focusGrab.active = false
            focusGrab.windows = []
            root.grabSig = ""
            MenuState.clearIfCurrent(root)
            root.logGrab("top menu hidden; focus grab deactivated")
        }
    }

    onWindowConnected: {
        if (root.isTopMenu && root.visible) {
            root.logGrab("windowConnected")
            root.updateFocusGrab()
            root.activateFocusGrabIfReady()
        }
    }

    onBackingWindowVisibleChanged: {
        if (root.isTopMenu && root.visible && root.backingWindowVisible) {
            root.logGrab("backingWindowVisible=true")
            root.updateFocusGrab()
            root.activateFocusGrabIfReady()
        }
    }

    onTreeContainsMouseChanged: {
        if (treeContainsMouse) {
            submenuCloseTimer.stop()
        }
    }

    anchor.item: anchorItem
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.rect.x: {
        if (!anchorItem) return 0
        if (!isNaN(anchorPointX) && !isNaN(anchorPointY)) return anchorPointX
        if (placement === "right") return anchorItem.width + 4
        return 0
    }
    anchor.rect.y: {
        if (!anchorItem) return 0
        if (!isNaN(anchorPointX) && !isNaN(anchorPointY)) return anchorPointY
        if (placement === "right") return -4
        return anchorItem.height + yOffset
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: false
        windows: []

        onActiveChanged: {
            if (!root.isTopMenu) return
            root.logGrab("focusGrab.active=" + focusGrab.active)
        }

        onCleared: {
            root.logGrab("focusGrab.cleared fired")
            root.closeTopMenu()
        }
    }

    Timer {
        id: grabActivationCheck
        interval: 300
        repeat: false

        onTriggered: {
            if (root.isTopMenu && root.visible && root.grabRequested && !focusGrab.active) {
                console.warn("[MenuPopup] HyprlandFocusGrab did not activate. Outside-click dismissal may be unavailable on this compositor/protocol.")
            }
        }
    }

    Timer {
        id: submenuOpenTimer
        interval: root.submenuOpenDelayMs
        repeat: false

        onTriggered: {
            if (root.pendingSubmenuIndex < 0 || !root.pendingSubmenuModel || !root.pendingSubmenuAnchor) return
            root.logPerf("submenuOpenTimer fired index=" + root.pendingSubmenuIndex)
            root.actuallyOpenSubmenu(root.pendingSubmenuIndex, root.pendingSubmenuAnchor, root.pendingSubmenuModel)
        }
    }

    Timer {
        id: submenuCloseTimer
        interval: root.submenuCloseDelayMs
        repeat: false

        onTriggered: {
            root.logPerf("submenuCloseTimer fired")
            if (!root.treeContainsMouse) {
                root.closeSubmenu()
            }
        }
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: true

        HoverHandler {
            id: menuHoverHandler
        }

        Keys.onUpPressed: root.navigateUp()
        Keys.onDownPressed: root.navigateDown()
        Keys.onReturnPressed: {
            if (root.hoveredIndex >= 0) root.activateItem(root.hoveredIndex)
        }
        Keys.onEscapePressed: root.closeTopMenu()

        Rectangle {
            id: glassBackground
            anchors.fill: parent
            radius: Theme.menuBorderRadius
            color: Theme.menuBackground

            layer.enabled: false
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 4
                radius: 25
                samples: 50
                color: "#40000000"
                spread: 0
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Theme.menuBorderRadius - 1
                color: "transparent"
                border.width: 1
                border.color: Theme.isDark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.4)
            }
        }

        Column {
            id: menuContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 5
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 0

            Repeater {
                model: root.model

                Loader {
                    width: Math.max(implicitWidth, parent.width)
                    property var itemData: modelData
                    property int itemIndex: index
                    property bool isHovered: root.hoveredIndex === index
                    property bool isSelected: root.selectedIndex === index

                    sourceComponent: {
                        if (itemData.type === "separator") return separatorComponent
                        if (itemData.type === "header") return headerComponent
                        return menuItemComponent
                    }
                }
            }
        }

        Loader {
            id: submenuLoader
            active: false
            source: "MenuPopup.qml"

            onLoaded: {
                if (!item) return

                item.topMenu = root.topMenu
                item.placement = "right"
                item.yOffset = 0
                item.adaptiveWidth = true
                item.debugGrabs = root.topMenu ? root.topMenu["debugGrabs"] : false
                item.debugMenuPerf = root.topMenu ? root.topMenu["debugMenuPerf"] : false

                var clickedSignal = item["itemClicked"]
                if (clickedSignal && clickedSignal.connect) {
                    clickedSignal.connect(function(clickedItem, index) {
                        root.itemClicked(clickedItem, index)
                        root.closeTopMenu()
                    })
                }

                if (root.activeSubmenuModelRef && root.activeSubmenuAnchorRef) {
                    item.model = root.activeSubmenuModelRef
                    item.anchorItem = root.activeSubmenuAnchorRef
                }

                if (item["open"]) {
                    item["open"]()
                }

                root.invokeTopMenuUpdateGrab()
            }
        }
    }

    // Functions
    function logGrab(message) {
        if (root.topMenu && root.topMenu["debugGrabs"]) {
            console.log("[MenuPopup] " + message)
        }
    }

    function logPerf(message) {
        if (root.topMenu && root.topMenu["debugMenuPerf"]) {
            console.log("[MenuPopupPerf] " + message)
        }
    }

    function closeTopMenu() {
        if (root.topMenu && root.topMenu["close"]) {
            root.topMenu["close"]()
        }
    }

    function invokeTopMenuUpdateGrab() {
        if (root.topMenu && root.topMenu["updateFocusGrab"]) {
            root.topMenu["updateFocusGrab"]()
        }
    }

    function submenuTreeContainsMouse() {
        if (!submenuLoader.active || !submenuLoader.item) return false
        return submenuLoader.item["treeContainsMouse"] === true
    }

    function computeWindowsChain() {
        var wins = [root]
        var submenu = submenuLoader.item
        if (submenuLoader.active && submenu && submenu["visible"] && submenu["computeWindowsChain"]) {
            wins = wins.concat(submenu["computeWindowsChain"]())
        }
        return wins
    }

    function computeGrabSig(wins) {
        var parts = []
        for (var i = 0; i < wins.length; i++) {
            parts.push(String(wins[i]))
        }
        return parts.join("|")
    }

    function updateFocusGrab() {
        if (!root.isTopMenu) {
            root.invokeTopMenuUpdateGrab()
            return
        }

        if (!root.visible || !root.grabRequested) {
            if (focusGrab.windows.length > 0 || root.grabSig !== "") {
                focusGrab.windows = []
                root.grabSig = ""
                root.grabUpdateAssignments++
                root.logPerf("updateFocusGrab clear assignments=" + root.grabUpdateAssignments)
            }
            return
        }

        var wins = root.computeWindowsChain()
        var sig = root.computeGrabSig(wins)

        if (sig === root.grabSig) {
            return
        }

        focusGrab.windows = wins
        root.grabSig = sig
        root.grabUpdateAssignments++

        root.logGrab("focus windows=" + wins.length + " sig=" + sig)
        root.logPerf("updateFocusGrab assign chainLen=" + wins.length + " assignments=" + root.grabUpdateAssignments)
    }

    function activateFocusGrabIfReady() {
        if (!root.isTopMenu) return
        if (!root.visible || !root.grabRequested || !root.backingWindowVisible) return
        if (focusGrab.active) return

        focusGrab.active = true
        root.logGrab("focus grab activation requested")
        grabActivationCheck.restart()
    }

    function cancelPendingSubmenuOpen() {
        if (root.pendingSubmenuIndex >= 0) {
            root.logPerf("cancel pending submenu index=" + root.pendingSubmenuIndex)
        }

        root.pendingSubmenuIndex = -1
        root.pendingSubmenuModel = null
        root.pendingSubmenuAnchor = null
        submenuOpenTimer.stop()
    }

    function scheduleSubmenuOpen(index, anchor, submenuModel, delayMs) {
        if (!submenuModel) {
            root.cancelPendingSubmenuOpen()
            root.closeSubmenu()
            return
        }

        if (root.activeSubmenuIndex === index
                && root.activeSubmenuModelRef === submenuModel
                && submenuLoader.active
                && submenuLoader.item) {
            root.activeSubmenuAnchorRef = anchor
            submenuLoader.item.anchorItem = anchor
            return
        }

        root.pendingSubmenuIndex = index
        root.pendingSubmenuAnchor = anchor
        root.pendingSubmenuModel = submenuModel

        submenuOpenTimer.interval = Math.max(0, delayMs)
        if (submenuOpenTimer.interval === 0) {
            root.logPerf("open submenu immediately index=" + index)
            root.actuallyOpenSubmenu(index, anchor, submenuModel)
        } else {
            submenuOpenTimer.restart()
            root.logPerf("schedule submenu index=" + index + " delay=" + submenuOpenTimer.interval)
        }
    }

    function actuallyOpenSubmenu(index, anchor, submenuModel) {
        if (!submenuModel || !anchor) return

        if (root.pendingSubmenuIndex === index
                && root.pendingSubmenuModel === submenuModel
                && root.pendingSubmenuAnchor === anchor) {
            root.cancelPendingSubmenuOpen()
        }

        if (root.activeSubmenuIndex === index
                && root.activeSubmenuModelRef === submenuModel
                && submenuLoader.active
                && submenuLoader.item) {
            root.activeSubmenuAnchorRef = anchor
            submenuLoader.item.anchorItem = anchor
            if (submenuLoader.item.anchor && submenuLoader.item.anchor.updateAnchor) {
                submenuLoader.item.anchor.updateAnchor()
            }
            return
        }

        root.activeSubmenuIndex = index
        root.activeSubmenuModelRef = submenuModel
        root.activeSubmenuAnchorRef = anchor
        submenuCloseTimer.stop()

        root.logPerf("open submenu index=" + index)

        if (submenuLoader.active && submenuLoader.item) {
            submenuLoader.item.anchorItem = anchor
            submenuLoader.item.model = submenuModel
            if (submenuLoader.item.anchor && submenuLoader.item.anchor.updateAnchor) {
                submenuLoader.item.anchor.updateAnchor()
            }
            if (!submenuLoader.item["visible"] && submenuLoader.item["open"]) {
                submenuLoader.item["open"]()
            }
            root.invokeTopMenuUpdateGrab()
            return
        }

        submenuLoader.active = true
    }

    function closeSubmenu() {
        root.cancelPendingSubmenuOpen()
        submenuCloseTimer.stop()

        var hadSubmenu = submenuLoader.active || (activeSubmenuIndex >= 0)

        if (submenuLoader.item && submenuLoader.item["close"]) {
            submenuLoader.item["close"]()
        }

        submenuLoader.active = false
        activeSubmenuIndex = -1
        activeSubmenuModelRef = null
        activeSubmenuAnchorRef = null

        if (hadSubmenu) {
            root.logPerf("close submenu")
            root.invokeTopMenuUpdateGrab()
        }
    }

    function open() {
        if (root.isTopMenu) {
            MenuState.requestOpen(root)
            root.logGrab("top menu open")
            root.grabRequested = true
        }

        if (root.anchor && root.anchor.updateAnchor) {
            root.anchor.updateAnchor()
        }

        root.visible = true
        focusScope.forceActiveFocus()

        hoveredIndex = root.isTopMenu ? findFirstSelectableIndex() : -1

        if (root.isTopMenu) {
            root.updateFocusGrab()
            root.activateFocusGrabIfReady()
        } else {
            root.invokeTopMenuUpdateGrab()
        }
    }

    function close() {
        root.cancelPendingSubmenuOpen()
        root.closeSubmenu()

        root.visible = false
        hoveredIndex = -1
        selectedIndex = -1

        if (root.isTopMenu) {
            root.logGrab("top menu close")
            root.grabRequested = false
            focusGrab.active = false
            focusGrab.windows = []
            root.grabSig = ""
            MenuState.clearIfCurrent(root)
        }
    }

    function toggle() {
        if (root.visible) root.closeTopMenu()
        else open()
    }

    function navigateUp() {
        var newIndex = hoveredIndex - 1
        while (newIndex >= 0) {
            var item = model[newIndex]
            if (item.type !== "separator" && item.type !== "header" && !isItemDisabled(item)) {
                hoveredIndex = newIndex
                return
            }
            newIndex--
        }
    }

    function navigateDown() {
        var newIndex = hoveredIndex + 1
        while (newIndex < model.length) {
            var item = model[newIndex]
            if (item.type !== "separator" && item.type !== "header" && !isItemDisabled(item)) {
                hoveredIndex = newIndex
                return
            }
            newIndex++
        }
    }

    function findFirstSelectableIndex() {
        for (var i = 0; i < model.length; i++) {
            var item = model[i]
            if (item.type !== "separator" && item.type !== "header" && !isItemDisabled(item)) {
                return i
            }
        }
        return -1
    }

    function activateItem(index) {
        var item = model[index]
        if (item && !isItemDisabled(item)) {
            selectedIndex = index
            itemClicked(item, index)
            if (item.action) item.action()
            root.closeTopMenu()
        }
    }

    function isItemDisabled(item) {
        return item && (item.disabled || item.enabled === false)
    }

    Component {
        id: menuItemComponent

        MenuItem {
            itemData: parent.itemData
            isHovered: parent.isHovered || mouseArea.containsMouse
            isSelected: parent.isSelected
            isSubmenuOpen: root.activeSubmenuIndex === parent.itemIndex

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: root.isItemDisabled(parent.itemData) ? Qt.ArrowCursor : Qt.PointingHandCursor

                onEntered: {
                    if (root.isItemDisabled(parent.itemData)) return

                    var index = parent.parent.itemIndex
                    root.hoveredIndex = index

                    if (parent.itemData.submenu) {
                        var delay = (root.activeSubmenuIndex >= 0 && root.activeSubmenuIndex !== index)
                            ? root.submenuSwitchDelayMs
                            : root.submenuOpenDelayMs
                        root.scheduleSubmenuOpen(index, parent, parent.itemData.submenu, delay)
                    } else {
                        root.cancelPendingSubmenuOpen()
                        root.closeSubmenu()
                    }
                }

                onExited: {
                    var index = parent.parent.itemIndex

                    if (root.hoveredIndex === index) {
                        root.hoveredIndex = -1
                    }
                }

                onClicked: {
                    if (!root.isItemDisabled(parent.itemData) && !parent.itemData.submenu) {
                        root.activateItem(parent.parent.itemIndex)
                    }
                }
            }
        }
    }

    Component {
        id: separatorComponent
        MenuSeparator {}
    }

    Component {
        id: headerComponent
        MenuHeader {
            text: parent.itemData.label || ""
        }
    }
}
