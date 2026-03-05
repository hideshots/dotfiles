pragma ComponentBehavior: Bound

import QtQuick

import ".." as Root

Item {
    id: root

    readonly property var network: Root.NetworkStatsService

    visible: network.visible
    height: parent.height
    width: visible ? (horizontalPadding * 2) + arrowColumnWidth + reservedArrowGap + valueColumnWidth : 0

    property int horizontalPadding: 5
    property int compactGap: -8
    property int wideGap: -6
    property int wideHoldMs: 60000
    property bool wideSpacingActive: false
    readonly property int effectiveArrowGap: wideSpacingActive ? wideGap : compactGap
    readonly property int reservedArrowGap: Math.max(compactGap, wideGap)
    readonly property int arrowColumnWidth: Math.ceil(Math.max(upArrowMetrics.width, downArrowMetrics.width))
    readonly property int valueColumnWidth: Math.ceil(valueTemplateMetrics.width)

    function _numericPrefix(valueText) {
        var parsed = parseFloat(String(valueText || "").trim());
        if (!isFinite(parsed)) {
            return 0;
        }
        return parsed;
    }

    function _needsWideSpacing() {
        return _numericPrefix(root.network.uploadText) >= 100 || _numericPrefix(root.network.downloadText) >= 100;
    }

    function updateSpacingMode() {
        if (_needsWideSpacing()) {
            root.wideSpacingActive = true;
            shrinkCooldown.stop();
            return;
        }

        if (!root.wideSpacingActive) {
            return;
        }

        shrinkCooldown.interval = Math.max(1000, root.wideHoldMs);
        shrinkCooldown.restart();
    }

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
            spacing: root.effectiveArrowGap

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
                font.weight: Font.DemiBold
                color: "#ffffff"
                renderType: Text.NativeRendering
            }
        }

        Row {
            spacing: root.effectiveArrowGap

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
                font.weight: Font.DemiBold
                color: "#ffffff"
                renderType: Text.NativeRendering
            }
        }
    }

    Connections {
        target: root.network
        function onUploadTextChanged() {
            root.updateSpacingMode();
        }
        function onDownloadTextChanged() {
            root.updateSpacingMode();
        }
    }

    Timer {
        id: shrinkCooldown
        interval: Math.max(1000, root.wideHoldMs)
        repeat: false
        onTriggered: {
            if (!root._needsWideSpacing()) {
                root.wideSpacingActive = false;
            }
        }
    }

    onWideHoldMsChanged: {
        if (shrinkCooldown.running) {
            shrinkCooldown.interval = Math.max(1000, root.wideHoldMs);
            shrinkCooldown.restart();
        }
    }

    onCompactGapChanged: root.updateSpacingMode()
    onWideGapChanged: root.updateSpacingMode()

    Component.onCompleted: root.updateSpacingMode()
}
