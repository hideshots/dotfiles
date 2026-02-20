import QtQuick

Item {
    id: root
    width: parent.width
    height: 11
    implicitWidth: 0

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: -1
        anchors.rightMargin: -4
        height: 1
        color: Theme.menuSeparator
    }
}
