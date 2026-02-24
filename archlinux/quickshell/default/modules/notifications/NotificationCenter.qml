pragma ComponentBehavior: Bound

import QtQuick

import "../.." as Root

Item {
    id: root

    property bool open: false
    property int panelWidth: 392
    property int panelHeight: 560
    property int panelPadding: 10
    property int headerHeight: 42
    property int listSpacing: 8
    property int maxHistoryVisible: 100

    readonly property var notificationService: Root.NotificationService
    readonly property bool hasHistory: notificationService.historyCount > 0

    signal requestClose

    implicitWidth: panelWidth
    implicitHeight: panelHeight

    visible: open || opacity > 0.01
    opacity: open ? 1 : 0
    x: open ? 0 : 16
    enabled: opacity > 0.95

    Behavior on opacity {
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    Behavior on x {
        NumberAnimation {
            duration: 170
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Root.Theme.isDark ? Qt.rgba(0.10, 0.10, 0.10, 0.97) : Qt.rgba(0.98, 0.98, 0.98, 0.97)
        border.width: 1
        border.color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.12)
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "transparent"
        border.width: 1
        border.color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.72)
    }

    Column {
        anchors.fill: parent
        anchors.margins: root.panelPadding
        spacing: 8

        Rectangle {
            id: header
            width: parent.width
            height: root.headerHeight
            radius: 10
            color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.04)

            Row {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications"
                    font.family: Root.Theme.fontFamilyDisplay
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Root.Theme.textPrimary
                    renderType: Text.NativeRendering
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.notificationService.historyCount
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 12
                    color: Root.Theme.textSecondary
                    opacity: 0.88
                    renderType: Text.NativeRendering
                }

                Item {
                    width: Math.max(0, parent.width - clearAllButton.width - closeButton.width - 145)
                    height: 1
                }

                Rectangle {
                    id: clearAllButton
                    anchors.verticalCenter: parent.verticalCenter
                    width: 62
                    height: 24
                    radius: 7
                    visible: root.hasHistory
                    color: clearAllMouseArea.containsMouse ? Qt.rgba(Root.Theme.menuHighlight.r, Root.Theme.menuHighlight.g, Root.Theme.menuHighlight.b, 0.20) : (Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08))
                    border.width: 1
                    border.color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08)

                    Text {
                        anchors.centerIn: parent
                        text: "Clear All"
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        color: Root.Theme.textPrimary
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: clearAllMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.notificationService.clearHistory()
                    }
                }

                Rectangle {
                    id: closeButton
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    radius: 12
                    color: closeMouseArea.containsMouse ? (Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "x"
                        font.family: Root.Theme.fontFamilyDisplay
                        font.pixelSize: 12
                        color: Root.Theme.textSecondary
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: closeMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.requestClose()
                    }
                }
            }
        }

        Item {
            id: bodyArea
            width: parent.width
            height: parent.height - header.height - parent.spacing

            Text {
                anchors.centerIn: parent
                visible: !root.hasHistory
                text: "No Notifications"
                font.family: Root.Theme.fontFamilyDisplay
                font.pixelSize: 14
                color: Root.Theme.textSecondary
                opacity: 0.80
                renderType: Text.NativeRendering
            }

            ListView {
                id: historyListView
                anchors.fill: parent
                visible: root.hasHistory
                clip: true
                spacing: root.listSpacing
                model: root.notificationService.historyList
                boundsBehavior: Flickable.StopAtBounds
                interactive: contentHeight > height
                orientation: ListView.Vertical
                verticalLayoutDirection: ListView.BottomToTop

                add: Transition {
                    NumberAnimation {
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 130
                    }
                }

                remove: Transition {
                    NumberAnimation {
                        property: "opacity"
                        to: 0
                        duration: 110
                    }
                }

                displaced: Transition {
                    NumberAnimation {
                        properties: "x,y"
                        duration: 140
                        easing.type: Easing.OutCubic
                    }
                }

                delegate: NotificationCard {
                    required property int index
                    required property var model

                    readonly property bool withinVisibleLimit: index >= Math.max(0, ListView.view.count - root.maxHistoryVisible)

                    width: historyListView.width
                    visible: withinVisibleLimit
                    height: visible ? implicitHeight : 0
                    opacity: visible ? 1 : 0

                    notificationId: Number(model.id)
                    appName: model.appName ? String(model.appName) : ""
                    appIcon: model.appIcon ? String(model.appIcon) : ""
                    summary: model.summary ? String(model.summary) : ""
                    body: model.body ? String(model.body) : ""
                    timeLabel: model.timeLabel ? String(model.timeLabel) : ""
                    actions: model.actions ? model.actions : []

                    keyboardInteractive: false
                    showActions: false
                    showDismissButton: true
                    showTimeLabel: true
                    dismissMode: "removeHistory"
                    clickActivatesDefault: true
                }
            }
        }
    }
}
