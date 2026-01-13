import Quickshell
import QtQuick
import Qt5Compat.GraphicalEffects
import ".."

PopupWindow {
    id: root

    // Public API
    property var model: []
    property Item anchorItem: null
    property int yOffset: 6
    property string placement: "bottom" // bottom or right
    property bool adaptiveWidth: false

    // Signals
    signal itemClicked(var item, int index)

    // Internal state
    property int hoveredIndex: -1
    property int selectedIndex: -1
    property int activeSubmenuIndex: -1

    visible: false
    implicitWidth: adaptiveWidth ? menuContent.implicitWidth + 24 : Theme.menuWidth
    implicitHeight: menuContent.height + 10
    color: "transparent"

    // Position relative to anchor
    anchor.window: anchorItem ? anchorItem.QsWindow.window : null
    anchor.rect.x: {
        if (!anchorItem) return 0
        var pos = anchorItem.mapToItem(null, 0, 0)
        if (placement === "right") return pos.x + anchorItem.width + 4
        return pos.x
    }
    anchor.rect.y: {
        if (!anchorItem) return 0
        var pos = anchorItem.mapToItem(null, 0, 0)
        if (placement === "right") return pos.y - 4
        return pos.y + anchorItem.height + yOffset
    }
    anchor.rect.width: anchorItem ? anchorItem.width : 0
    anchor.rect.height: 0

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
        Keys.onEscapePressed: close()

        // Glass effect background
        Rectangle {
            id: glassBackground
            anchors.fill: parent
            radius: Theme.menuBorderRadius
            color: Theme.menuBackground

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 4
                radius: 25
                samples: 50
                color: "#40000000"
                spread: 0
            }

            // Inner border highlights (simulating glass effect)
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: Theme.menuBorderRadius - 1
                color: "transparent"
                border.width: 1
                border.color: Theme.isDark ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.4)
            }
        }

        // Content column
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
                item.placement = "right"
                item.yOffset = 0
                item.adaptiveWidth = true
                item.itemClicked.connect(function(item, index) {
                    root.itemClicked(item, index)
                    root.close()
                })
                item.open()
            }
        }
    }

    // Functions
    function open() {
        root.visible = true
        focusScope.forceActiveFocus()
        hoveredIndex = findFirstSelectableIndex()
    }

    function close() {
        root.visible = false
        hoveredIndex = -1
        selectedIndex = -1
        activeSubmenuIndex = -1
        submenuLoader.active = false
    }

    function toggle() {
        if (root.visible) close()
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
            close()
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
                            submenuLoader.item.model = parent.itemData.submenu
                            submenuLoader.item.anchorItem = parent
                        } else {
                            root.activeSubmenuIndex = -1
                            submenuLoader.active = false
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
