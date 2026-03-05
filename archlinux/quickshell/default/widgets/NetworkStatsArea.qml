pragma ComponentBehavior: Bound

import QtQuick

import ".." as Root

Item {
    id: root

    readonly property var network: Root.NetworkStatsService

    visible: network.visible
    height: parent.height
    width: visible ? (horizontalPadding * 2) + arrowColumnWidth + arrowValueGap + valueColumnWidth : 0

    property int horizontalPadding: 5
    property int arrowValueGap: -6
    readonly property int arrowColumnWidth: Math.ceil(Math.max(upArrowMetrics.width, downArrowMetrics.width))
    readonly property int valueColumnWidth: Math.ceil(valueTemplateMetrics.width)

    TextMetrics {
        id: upArrowMetrics
        font.family: Root.Theme.fontFamilySymbol
        font.pixelSize: 7
        font.weight: Font.Normal
        text: "􀄨"
    }

    TextMetrics {
        id: downArrowMetrics
        font.family: Root.Theme.fontFamilySymbol
        font.pixelSize: 7
        font.weight: Font.Normal
        text: "􀄩"
    }

    TextMetrics {
        id: valueTemplateMetrics
        font.family: Root.Theme.fontFamily
        font.pixelSize: 9
        font.weight: Font.Normal
        text: "999.9 MB/s"
    }

    Column {
        id: contentColumn
        anchors.centerIn: parent
        spacing: 0

        Row {
            spacing: root.arrowValueGap

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: root.arrowColumnWidth
                horizontalAlignment: Text.AlignLeft
                text: "􀄨"
                font.family: Root.Theme.fontFamilySymbol
                font.pixelSize: 7
                font.weight: Font.Bold
                color: "#ffffff"
                renderType: Text.NativeRendering
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: root.valueColumnWidth
                horizontalAlignment: Text.AlignRight
                text: root.network.uploadText
                font.family: Root.Theme.fontFamily
                font.pixelSize: 9
                font.weight: Font.Normal
                color: "#ffffff"
                renderType: Text.NativeRendering
            }
        }

        Row {
            spacing: root.arrowValueGap

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: root.arrowColumnWidth
                horizontalAlignment: Text.AlignLeft
                text: "􀄩"
                font.family: Root.Theme.fontFamilySymbol
                font.pixelSize: 7
                font.weight: Font.Bold
                color: "#ffffff"
                renderType: Text.NativeRendering
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: root.valueColumnWidth
                horizontalAlignment: Text.AlignRight
                text: root.network.downloadText
                font.family: Root.Theme.fontFamily
                font.pixelSize: 9
                font.weight: Font.Normal
                color: "#ffffff"
                renderType: Text.NativeRendering
            }
        }
    }
}
