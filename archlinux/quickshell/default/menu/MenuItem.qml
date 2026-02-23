pragma ComponentBehavior: Bound
import QtQuick

Rectangle {
    id: root

    property var itemData: ({})
    property bool isHovered: false
    property bool isSelected: false
    property bool isSubmenuOpen: false
    // property var contentWidth: 12 + 6 + 12 + 6 + labelText.implicitWidth + 24 + shortcutRow.width + (hasSubmenu ? 18 : 0) + 14
    property var contentWidth: 12 + 6 + 12 + 6 + labelText.implicitWidth + shortcutRow.width + (hasSubmenu ? 18 : 0) 
    implicitWidth: contentWidth

    // Computed properties
    property bool hasSubmenu: itemData.submenu !== undefined
    property bool isDisabled: itemData.disabled || itemData.enabled === false || false
    readonly property bool showActiveText: !isDisabled && (isHovered || isSelected)
    property bool isChecked: itemData.checked || false
    property bool reserveCheckmark: itemData.reserveCheckmark || false
    readonly property bool showCheckColumn: reserveCheckmark || isChecked
    property string icon: itemData.icon || ""
    property string label: itemData.label || ""
    property var shortcut: itemData.shortcut || []

    height: Theme.menuItemHeight
    width: parent.width
    color: "transparent"
    radius: Theme.menuItemBorderRadius

    // Highlight background
    Rectangle {
        id: highlightBg
        anchors.fill: parent
        anchors.leftMargin: -7
        anchors.rightMargin: -7
        radius: Theme.menuItemBorderRadius
        color: {
            if (root.isDisabled) return "transparent"
            if (root.showActiveText) {
                return Theme.menuHighlight
            }
            if (root.isSubmenuOpen) {
                return Qt.rgba(1, 1, 1, 0.1)
            }
            return "transparent"
        }
        visible: !root.isDisabled && (root.isHovered || root.isSelected || root.isSubmenuOpen)

        Behavior on color {
            ColorAnimation { duration: Theme.animationDuration }
        }
    }

    Row {
        anchors.fill: parent
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        // Checkmark area (for toggle items)
        Item {
            width: root.showCheckColumn ? 1 : 0
            height: parent.height

            Text {
                anchors.centerIn: parent
                text: "􀆅"
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: root.showActiveText
                    ? "#ffffff"
                    : (root.isDisabled ? Theme.menuTextDisabled : Theme.menuText)
                renderType: Text.NativeRendering
                visible: root.isChecked
            }
        }

        // Icon
        Item {
            width: 12
            height: parent.height

            Text {
                anchors.centerIn: parent
                text: root.icon
                font.family: Theme.fontFamily
                font.pixelSize: 10
                color: root.showActiveText
                    ? "#ffffff"
                    : (root.isDisabled ? Theme.menuTextDisabled : Theme.menuText)
                renderType: Text.NativeRendering
                visible: root.icon !== ""
            }
        }

        // Label
        Text {
            id: labelText
            height: parent.height
            verticalAlignment: Text.AlignVCenter
            text: root.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize
            font.weight: Font.Medium
            color: root.showActiveText
                ? "#ffffff"
                : (root.isDisabled ? Theme.menuTextDisabled : Theme.menuText)
            elide: Text.ElideRight
            renderType: Text.NativeRendering
        }

        // Flexible spacer
        Item {
            width: Math.max(0,
                parent.width
                - 12 - 12
                - labelText.implicitWidth
                - shortcutRow.width
                - (root.hasSubmenu ? 18 : 0)
                - 8 // right padding; tweak (0..12)
            )
            height: 1
        }

        // Shortcuts
        Row {
            id: shortcutRow
            height: parent.height
            spacing: 1
            visible: root.shortcut.length > 0 && !root.hasSubmenu
            property color shortcutColor: root.showActiveText
                ? "#ffffff"
                : (root.isDisabled ? Theme.menuTextDisabled : Theme.menuShortcutText)

            Repeater {
                model: root.shortcut

                Text {
                    required property var modelData
                    height: parent.height
                    width: 12
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: shortcutRow.shortcutColor
                    renderType: Text.NativeRendering
                }
            }
        }

        // Submenu chevron
        Text {
            height: parent.height
            width: 12
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: "􀆊"
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: root.showActiveText
                ? "#ffffff"
                : (root.isDisabled ? Theme.menuTextDisabled : Theme.menuText)
            visible: root.hasSubmenu
            renderType: Text.NativeRendering
        }
    }
}
