import QtQuick
import Qt5Compat.GraphicalEffects
import ".."

Item {
    id: root

    // Public API
    property var model: []
    property bool isOpen: false
    property int menuWidth: Theme.menuWidth
    property Item anchorItem: null

    // Internal state
    property int hoveredIndex: -1
    property int selectedIndex: -1

    // Signals
    signal itemClicked(var item, int index)
    signal closed()

    width: menuWidth
    height: contentColumn.height + 10
    visible: root.isOpen
    opacity: root.isOpen ? 1 : 0
    scale: root.isOpen ? 1 : 0.95


    Behavior on opacity {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }
    Behavior on scale {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    // Glass background
    Rectangle {
        id: menuBackground
        anchors.fill: parent
        radius: Theme.menuBorderRadius
        color: "transparent"

        // Shadow layer
        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4
            radius: 25
            samples: 50
            color: "#40000000"
            spread: 0
        }
    }

    // Glass effect background
    Rectangle {
        id: glassBackground
        anchors.fill: parent
        radius: Theme.menuBorderRadius
        color: Theme.menuBackground

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
        id: contentColumn
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
                width: parent.width
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

    // Click outside to close
    MouseArea {
        id: closeArea
        anchors.fill: parent
        z: -1
        propagateComposedEvents: true
        onPressed: function(mouse) {
            mouse.accepted = false
        }
    }

    // Keyboard navigation
    Keys.onUpPressed: {
        navigateUp()
    }
    Keys.onDownPressed: {
        navigateDown()
    }
    Keys.onReturnPressed: {
        if (hoveredIndex >= 0) {
            activateItem(hoveredIndex)
        }
    }
    Keys.onEscapePressed: {
        close()
    }

    // Functions
    function open() {
        root.isOpen = true
        root.forceActiveFocus()
        hoveredIndex = findFirstSelectableIndex()
    }

    function close() {
        root.isOpen = false
        hoveredIndex = -1
        selectedIndex = -1
        closed()
    }

    function toggle() {
        if (root.isOpen) {
            close()
        } else {
            open()
        }
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
            if (item.submenu) {
                // Open submenu
                openSubmenu(item, index)
            } else {
                // Execute action
                selectedIndex = index
                itemClicked(item, index)
                if (item.action) {
                    item.action()
                }
                close()
            }
        }
    }

    function openSubmenu(item, index) {
        // Submenus can be handled by the parent component
        // For now, just emit the clicked signal
        itemClicked(item, index)
    }

    // Menu item component
    Component {
        id: menuItemComponent

        MenuItem {
            itemData: parent.itemData
            isHovered: parent.isHovered || mouseArea.containsMouse
            isSelected: parent.isSelected

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: parent.itemData.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor

                onEntered: {
                    if (!parent.itemData.disabled) {
                        root.hoveredIndex = parent.parent.itemIndex
                    }
                }
                onExited: {
                    if (root.hoveredIndex === parent.parent.itemIndex) {
                        root.hoveredIndex = -1
                    }
                }
                onClicked: {
                    if (!parent.itemData.disabled) {
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
