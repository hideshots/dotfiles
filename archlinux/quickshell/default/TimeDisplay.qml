import QtQuick
import Qt5Compat.GraphicalEffects
import Quickshell

Rectangle {
    id: root
    property var highlightState: null

    height: parent.height
    width: timeText.width + (Theme.itemPadding * 2)
    color: "transparent"
    radius: Theme.borderRadius

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
        font.weight: Font.Normal
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
