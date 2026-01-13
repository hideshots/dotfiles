import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell

Rectangle {
    id: root

    height: parent.height
    width: timeText.width + (Theme.itemPadding * 2)
    color: timeMouseArea.containsMouse
        ? Qt.rgba(255, 255, 255, 0.1)
        : (timeMouseArea.pressed ? Qt.rgba(255, 255, 255, 0.05) : "transparent")
    radius: Theme.borderRadius

    Behavior on color {
        ColorAnimation {
            duration: Theme.animationDuration
            easing.type: Theme.animationEasing
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Text {
        id: timeText
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "ddd MMM d  h:mm AP")
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        renderType: Text.NativeRendering
        font.weight: Font.Medium
        color: Theme.textPrimary
    }

    DropShadow {
        anchors.fill: timeText
        source: timeText
        visible: Theme.isDark
        horizontalOffset: Theme.shadowHorizontalOffset
        verticalOffset: Theme.shadowVerticalOffset
        radius: Theme.shadowRadius
        samples: 16
        spread: 0
        color: Theme.shadowColor
    }

    MouseArea {
        id: timeMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onClicked: {
            // Time action (e.g., open calendar)
        }
    }
}
