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
    readonly property bool stackHovered: stackHoverHandler.hovered

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
        // Keep popup delegates non-reused to avoid stale role visuals near maxVisible boundaries.
        reuseItems: false
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

            readonly property bool withinVisibleLimit: index >= Math.max(0, ListView.view.count - root.maxVisible)
            // Resolve row data from activeList by current index so hidden/visible transitions
            // never depend on potentially stale delegate-local role objects.
            readonly property var rowData: {
                if (!withinVisibleLimit || !root.notificationService.activeList) {
                    return null;
                }

                var sourceModel = root.notificationService.activeList;
                if (index < 0 || index >= sourceModel.count) {
                    return null;
                }

                return sourceModel.get(index);
            }

            width: listView.width
            visible: withinVisibleLimit
            height: visible ? implicitHeight : 0
            opacity: visible ? 1 : 0

            notificationId: rowData ? Number(rowData.id) : -1
            appName: rowData && rowData.appName !== undefined && rowData.appName !== null ? String(rowData.appName) : ""
            appIcon: rowData && rowData.appIcon !== undefined && rowData.appIcon !== null ? String(rowData.appIcon) : ""
            summary: rowData && rowData.summary !== undefined && rowData.summary !== null ? String(rowData.summary) : ""
            body: rowData && rowData.body !== undefined && rowData.body !== null ? String(rowData.body) : ""
            timeLabel: rowData && rowData.timeLabel !== undefined && rowData.timeLabel !== null ? String(rowData.timeLabel) : ""
            actions: rowData && rowData.actions ? rowData.actions : []
            keyboardInteractive: false
            interactionMode: "popup"
            draggableDismiss: true
            pauseTimeoutOnHover: true
            externalHoverHold: root.stackHovered
            expandable: false
        }
    }

    HoverHandler {
        id: stackHoverHandler
    }
}
