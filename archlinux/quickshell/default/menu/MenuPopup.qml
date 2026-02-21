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

    property bool debugGrabs: false
    property bool mouseInThisMenu: menuHoverHandler.hovered
    readonly property bool mouseInSubmenu: submenuTreeContainsMouse()
    readonly property bool treeContainsMouse: mouseInThisMenu || mouseInSubmenu

    property bool grabRequested: false

    property var pendingSubmenuModel: null
    property Item pendingSubmenuAnchor: null

    // Internal state
    property int hoveredIndex: -1
    property int selectedIndex: -1
    property int activeSubmenuIndex: -1

    surfaceFormat.opaque: false
    color: "transparent"

    visible: false
    implicitWidth: adaptiveWidth ? menuContent.implicitWidth + 24 : Theme.menuWidth
    implicitHeight: menuContent.height + 10

    onVisibleChanged: {
        if (!visible) {
            if (root.isTopMenu) {
                root.updateFocusGrab(false)
                MenuState.clearIfCurrent(root)
            }
        }
    }

    onWindowConnected: {
        if (root.isTopMenu && root.visible) {
            root.logGrab("windowConnected: refresh focus grab")
            root.updateFocusGrab(true)
            if (root.backingWindowVisible) {
                root.activateFocusGrab()
            }
        }
    }

    onBackingWindowVisibleChanged: {
        if (root.isTopMenu && root.visible && root.backingWindowVisible) {
            root.logGrab("backingWindowVisible=true: activate focus grab")
            root.activateFocusGrab()
        }
    }

    onTreeContainsMouseChanged: {
        if (treeContainsMouse) {
            submenuBridgeTimer.stop()
        } else if (submenuLoader.active) {
            submenuBridgeTimer.restart()
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
        interval: 250
        repeat: false
        onTriggered: {
            if (root.isTopMenu && root.visible && root.grabRequested && !focusGrab.active) {
                console.warn("[MenuPopup] HyprlandFocusGrab inactive after activation attempt. Outside-click dismissal may be unavailable on this compositor/protocol.")
            }
        }
    }

    Timer {
        id: submenuBridgeTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (!root.treeContainsMouse) {
                root.closeSubmenu()
            }
        }
    }

    // Focus scope for keyboard handling
    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: true

        HoverHandler {
            id: menuHoverHandler
        }

        // Keyboard navigation
        Keys.onUpPressed: root.navigateUp()
        Keys.onDownPressed: root.navigateDown()
        Keys.onReturnPressed: {
            if (root.hoveredIndex >= 0) root.activateItem(root.hoveredIndex)
        }
        Keys.onEscapePressed: root.closeTopMenu()

        // Glass effect background
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

        // Submenu Loader
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
                var clickedSignal = item["itemClicked"]
                if (clickedSignal && clickedSignal.connect) {
                    clickedSignal.connect(function(clickedItem, index) {
                        root.itemClicked(clickedItem, index)
                        root.closeTopMenu()
                    })
                }

                item.model = root.pendingSubmenuModel || []
                item.anchorItem = root.pendingSubmenuAnchor
                if (item["open"]) {
                    item["open"]()
                }
                root.invokeTopMenuUpdateGrab(true)
            }

            onActiveChanged: {
                root.invokeTopMenuUpdateGrab(true)
            }
        }
    }

    // Functions
    function logGrab(message) {
        if (root.topMenu && root.topMenu["debugGrabs"]) {
            console.log("[MenuPopup] " + message)
        }
    }

    function closeTopMenu() {
        if (root.topMenu && root.topMenu["close"]) {
            root.topMenu["close"]()
        }
    }

    function invokeTopMenuUpdateGrab(forceRearm) {
        if (root.topMenu && root.topMenu["updateFocusGrab"]) {
            root.topMenu["updateFocusGrab"](forceRearm)
        }
    }

    function submenuTreeContainsMouse() {
        if (!submenuLoader.active || !submenuLoader.item) return false
        return submenuLoader.item["treeContainsMouse"] === true
    }

    function chainWindows() {
        var wins = [root]
        var submenu = submenuLoader.item
        if (submenuLoader.active && submenu && submenu["visible"] && submenu["chainWindows"]) {
            wins = wins.concat(submenu["chainWindows"]())
        }
        return wins
    }

    function updateFocusGrab(forceRearm) {
        if (!root.isTopMenu) {
            root.invokeTopMenuUpdateGrab(forceRearm)
            return
        }

        var wins = root.chainWindows()
        focusGrab.windows = wins
        root.logGrab("focus windows=" + wins.length + " objects=" + wins)

        if (!root.visible || !root.grabRequested) {
            if (focusGrab.active) {
                focusGrab.active = false
            }
            return
        }

        if (forceRearm && focusGrab.active) {
            focusGrab.active = false
            focusGrab.active = true
            root.logGrab("focus grab rearmed")
        } else if (root.backingWindowVisible && !focusGrab.active) {
            focusGrab.active = true
        }
    }

    function activateFocusGrab() {
        if (!root.isTopMenu) return

        root.grabRequested = true
        root.updateFocusGrab(false)

        focusGrab.active = false
        focusGrab.active = true
        root.logGrab("focus grab activation requested")

        grabActivationCheck.restart()
    }

    function openSubmenuForIndex(index, anchor, submenuModel) {
        if (!submenuModel) {
            closeSubmenu()
            return
        }

        submenuBridgeTimer.stop()
        activeSubmenuIndex = index

        pendingSubmenuAnchor = anchor
        pendingSubmenuModel = submenuModel

        if (submenuLoader.active && submenuLoader.item) {
            submenuLoader.item.anchorItem = anchor
            submenuLoader.item.model = submenuModel
            if (submenuLoader.item["open"]) {
                submenuLoader.item["open"]()
            }
            root.invokeTopMenuUpdateGrab(true)
            return
        }

        submenuLoader.active = true
    }

    function closeSubmenu() {
        submenuBridgeTimer.stop()

        if (submenuLoader.item) {
            if (submenuLoader.item["close"]) {
                submenuLoader.item["close"]()
            }
        }

        submenuLoader.active = false
        pendingSubmenuAnchor = null
        pendingSubmenuModel = null
        activeSubmenuIndex = -1

        root.invokeTopMenuUpdateGrab(true)
    }

    function open() {
        if (root.isTopMenu) {
            MenuState.requestOpen(root)
            root.logGrab("top menu open")
        }

        if (root.anchor && root.anchor.updateAnchor) {
            root.anchor.updateAnchor()
        }
        root.visible = true
        focusScope.forceActiveFocus()

        hoveredIndex = findFirstSelectableIndex()

        if (root.isTopMenu) {
            root.updateFocusGrab(false)
            if (root.backingWindowVisible) {
                root.activateFocusGrab()
            }
        } else {
            root.invokeTopMenuUpdateGrab(true)
        }
    }

    function close() {
        closeSubmenu()

        root.visible = false
        hoveredIndex = -1
        selectedIndex = -1
        activeSubmenuIndex = -1

        if (root.isTopMenu) {
            root.logGrab("top menu close")
            root.grabRequested = false
            root.updateFocusGrab(false)
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
            if (item.type !== "separator" && item.type !== "header" && !item.disabled) {
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
            if (item.type !== "separator" && item.type !== "header" && !item.disabled) {
                hoveredIndex = newIndex
                return
            }
            newIndex++
        }
    }

    function findFirstSelectableIndex() {
        for (var i = 0; i < model.length; i++) {
            var item = model[i]
            if (item.type !== "separator" && item.type !== "header" && !item.disabled) {
                return i
            }
        }
        return -1
    }

    function activateItem(index) {
        var item = model[index]
        if (item && !item.disabled) {
            selectedIndex = index
            itemClicked(item, index)
            if (item.action) item.action()
            root.closeTopMenu()
        }
    }

    // Menu item component
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
                cursorShape: parent.itemData.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor

                onEntered: {
                    if (parent.itemData.disabled) return

                    var index = parent.parent.itemIndex
                    root.hoveredIndex = index

                    if (parent.itemData.submenu) {
                        root.openSubmenuForIndex(index, parent, parent.itemData.submenu)
                    } else {
                        root.closeSubmenu()
                    }
                }

                onExited: {
                    var index = parent.parent.itemIndex

                    if (root.hoveredIndex === index && root.activeSubmenuIndex !== index) {
                        root.hoveredIndex = -1
                    }

                    if (parent.itemData.submenu && root.activeSubmenuIndex === index && !root.mouseInSubmenu) {
                        submenuBridgeTimer.restart()
                    }
                }

                onClicked: {
                    if (!parent.itemData.disabled && !parent.itemData.submenu) {
                        root.activateItem(parent.parent.itemIndex)
                    }
                }
            }
        }
    }

    // Separator component
    Component {
        id: separatorComponent
        MenuSeparator {}
    }

    // Header component
    Component {
        id: headerComponent
        MenuHeader {
            text: parent.itemData.label || ""
        }
    }
}
