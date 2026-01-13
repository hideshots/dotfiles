import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    property string icon: ""
    signal clicked()

    height: parent.height
    width: iconText.width + (Theme.itemPadding * 2)
    color: mouseArea.containsMouse
        ? Qt.rgba(255, 255, 255, 0.1)
        : (mouseArea.pressed ? Qt.rgba(255, 255, 255, 0.05) : "transparent")
    radius: Theme.borderRadius

    Behavior on color {
        ColorAnimation {
            duration: Theme.animationDuration
            easing.type: Theme.animationEasing
        }
    }

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
