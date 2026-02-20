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

    property PopupWindow topMenu: root
    readonly property bool isTopMenu: topMenu === root
    property int grabRev: 0

    surfaceFormat.opaque: false
    color: "transparent"

    function refreshGrab() { topMenu.grabRev++ }

    function chainWindows() {
        var wins = [root]
        if (submenuLoader.active && submenuLoader.item) {
            wins = wins.concat(submenuLoader.item.chainWindows())
        }
        return wins
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: root.isTopMenu && root.visible
        windows: root.isTopMenu ? (root.topMenu.grabRev, root.topMenu.chainWindows()) : []
        onCleared: root.topMenu.close()
    }

    // Internal state
    property int hoveredIndex: -1
    property int selectedIndex: -1
    property int activeSubmenuIndex: -1

    visible: false
    implicitWidth: adaptiveWidth ? menuContent.implicitWidth + 24 : Theme.menuWidth
    implicitHeight: menuContent.height + 10

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

    // Focus scope for keyboard handling
    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: true

        // Keyboard navigation
        Keys.onUpPressed: navigateUp()
        Keys.onDownPressed: navigateDown()
        Keys.onReturnPressed: {
            if (hoveredIndex >= 0) activateItem(hoveredIndex)
        }
        Keys.onEscapePressed: root.topMenu.close()

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
                item.topMenu = root.topMenu
                item.placement = "right"
                item.yOffset = 0
                item.adaptiveWidth = true

                item.itemClicked.connect(function(clickedItem, index) {
                    root.itemClicked(clickedItem, index)
                    root.topMenu.close()
                })

                item.open()
                root.refreshGrab()
            }
        }
    }

    // Functions
    function open() {
        root.visible = true
        focusScope.forceActiveFocus()
        hoveredIndex = findFirstSelectableIndex()
        root.refreshGrab()
    }

    function close() {
        root.visible = false
        hoveredIndex = -1
        selectedIndex = -1
        activeSubmenuIndex = -1
        submenuLoader.active = false
        root.refreshGrab()
    }

    function toggle() {
        if (root.visible) root.topMenu.close()
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
            root.topMenu.close()
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
                    if (!parent.itemData.disabled) {
                        root.hoveredIndex = parent.parent.itemIndex

                        // Handle submenu opening
                        if (parent.itemData.submenu) {
                            root.activeSubmenuIndex = parent.parent.itemIndex
                            submenuLoader.active = false // Reset
                            submenuLoader.active = true
                            if (submenuLoader.item) {
                                submenuLoader.item.model = parent.itemData.submenu
                                submenuLoader.item.anchorItem = parent
                                root.refreshGrab()
                            }
                        } else {
                            root.activeSubmenuIndex = -1
                            submenuLoader.active = false
                            root.refreshGrab()
                        }
                    }
                }
                onExited: {
                    if (root.hoveredIndex === parent.parent.itemIndex) {
                        root.hoveredIndex = -1
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
