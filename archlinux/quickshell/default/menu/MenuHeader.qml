import QtQuick
import ".."

Item {
    id: root

    property string text: ""

    width: parent.width
    height: 24

    Text {
        id: headerText
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 2
        text: root.text
        font.family: Theme.fontFamily
        font.pixelSize: 10
        font.weight: Font.Bold
        color: Theme.menuHeaderText
        renderType: Text.NativeRendering
    }

    implicitWidth: 18 + headerText.implicitWidth + 18
}
