pragma ComponentBehavior: Bound

import QtQuick

import "../.." as Root

Item {
    id: root

    property int edgeMargin: 12
    property int spacing: 8
    property int maxVisible: 5
    property int cardWidth: 352
    property int maxHeight: 720
    property string anchorCorner: "top-right"

    readonly property var notificationService: Root.NotificationService
    readonly property int visibleCount: Math.min(notificationService.activeCount, Math.max(0, maxVisible))
    readonly property real contentHeightWithMargins: listView.contentHeight + (edgeMargin * 2)

    implicitWidth: cardWidth + (edgeMargin * 2)
    implicitHeight: visibleCount > 0 ? Math.min(maxHeight, contentHeightWithMargins) : 0

    width: implicitWidth
    height: implicitHeight
    clip: true
    visible: visibleCount > 0

    ListView {
        id: listView
        anchors.fill: parent
        anchors.margins: root.edgeMargin
        spacing: root.spacing
        clip: true
        model: root.notificationService.activeList
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height
        orientation: ListView.Vertical
        verticalLayoutDirection: ListView.BottomToTop

        add: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 170
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    property: "x"
                    from: 24
                    to: 0
                    duration: 170
                    easing.type: Easing.OutCubic
                }
            }
        }

        remove: Transition {
            ParallelAnimation {
                NumberAnimation {
                    property: "opacity"
                    to: 0
                    duration: 140
                    easing.type: Easing.InCubic
                }
                NumberAnimation {
                    property: "x"
                    to: 24
                    duration: 140
                    easing.type: Easing.InCubic
                }
            }
        }

        displaced: Transition {
            NumberAnimation {
                properties: "x,y"
                duration: 170
                easing.type: Easing.OutCubic
            }
        }

        delegate: NotificationCard {
            required property int index
            required property var model

            readonly property bool withinVisibleLimit: index >= Math.max(0, ListView.view.count - root.maxVisible)

            width: listView.width
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
        }
    }
}
