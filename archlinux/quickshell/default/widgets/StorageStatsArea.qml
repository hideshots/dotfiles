pragma ComponentBehavior: Bound

import QtQuick

import ".." as Root

Item {
    id: root

    readonly property var storage: Root.StorageStatsService

    property int horizontalPadding: 4
    property int columnSpacing: 5
    property int entryWidth: 24
    property int entryHeight: 21
    property int labelHeight: 11
    property int pillWidth: 22
    property int pillHeight: 8
    property int pillTop: 12
    property int fillTop: 14
    property int fillInset: 2
    property int fillHeight: 4

    visible: storage.visible
    height: parent.height
    width: visible ? contentRow.implicitWidth + (horizontalPadding * 2) : 0

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: root.columnSpacing

        Repeater {
            model: root.storage.displayEntries

            Item {
                id: entryRoot
                required property var modelData
                readonly property int valuePercent: Math.max(0, Math.min(100, Number(modelData.percent)))
                readonly property int fillWidth: Math.round(((root.pillWidth - (root.fillInset * 2)) * valuePercent) / 100)

                width: root.entryWidth
                height: root.entryHeight

                Text {
                    x: 0
                    y: 0
                    width: parent.width
                    height: root.labelHeight
                    text: String(entryRoot.modelData.label || "")
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.Normal
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignLeft
                    elide: Text.ElideRight
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    x: 0
                    y: root.pillTop
                    width: root.pillWidth
                    height: root.pillHeight
                    radius: 4
                    opacity: 0.8
                    color: "transparent"
                    border.width: 1
                    border.color: "#ffffff"
                }

                Rectangle {
                    x: root.fillInset
                    y: root.fillTop
                    width: entryRoot.fillWidth
                    height: root.fillHeight
                    radius: 5.5
                    color: "#d9d9d9"
                }
            }
        }
    }
}
