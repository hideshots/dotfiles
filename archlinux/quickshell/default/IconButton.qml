import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    property string icon: ""
    property var highlightState: null
    signal clicked()

    height: parent.height
    width: iconText.width + (Theme.itemPadding * 2)
    color: "transparent"
    radius: Theme.borderRadius

    Text {
        id: iconText
        anchors.centerIn: parent
        text: root.icon
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        color: Theme.textSecondary
        renderType: Text.NativeRendering
    }

    DropShadow {
        anchors.fill: iconText
        source: iconText
        visible: Theme.isDark
        horizontalOffset: Theme.shadowHorizontalOffset
        verticalOffset: Theme.shadowVerticalOffset
        radius: Theme.shadowRadius
        samples: 16
        spread: 0
        color: Theme.shadowColor
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: root.clicked()
    }
}
