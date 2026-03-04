import QtQuick
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    property string icon: ""
    property real iconOffsetX: 0
    property var highlightState: null
    signal clicked()

    height: parent.height
    width: iconVisual.implicitWidth + (Theme.itemPadding * 2)
    color: "transparent"
    radius: Theme.borderRadius

    SymbolIcon {
        id: iconVisual
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.iconOffsetX
        glyph: root.icon
        fallbackFontFamily: Theme.fontFamily
        pixelSize: Theme.fontSize
        fallbackColor: Theme.textSecondary
    }

    DropShadow {
        anchors.fill: iconVisual
        source: iconVisual
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
