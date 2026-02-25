pragma ComponentBehavior: Bound

import QtQuick

import "../.." as Root

Item {
    id: root

    property int edgeMargin: 12
    property int spacing: 8
    property int maxVisible: 5
    property int cardWidth: 352
    property int popupOverlayBleed: 11
    // Extra headroom so the top-most popup can render corner overlays above card bounds.
    property int popupOverlayTopBleed: 14
    property int maxHeight: 720
    property string anchorCorner: "top-right"
    readonly property bool stackHovered: stackHoverHandler.hovered

    readonly property var notificationService: Root.NotificationService
    readonly property int visibleCount: notificationService.activeCount
    readonly property real contentHeightWithMargins: listView.contentHeight + (edgeMargin * 2) + popupOverlayTopBleed

    implicitWidth: cardWidth + (edgeMargin * 2)
    implicitHeight: visibleCount > 0 ? Math.min(maxHeight, contentHeightWithMargins) : 0

    width: implicitWidth
    height: implicitHeight
    clip: true
    visible: visibleCount > 0

    Component.onCompleted: _syncServiceActiveLimit()
    onMaxVisibleChanged: _syncServiceActiveLimit()

    function _syncServiceActiveLimit() {
        if (!notificationService || notificationService.maxActive === undefined) {
            return;
        }

        var nextLimit = Math.max(0, maxVisible);
        if (notificationService.maxActive !== nextLimit) {
            notificationService.maxActive = nextLimit;
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        anchors.leftMargin: Math.max(0, root.edgeMargin - root.popupOverlayBleed)
        anchors.topMargin: root.edgeMargin
        anchors.rightMargin: root.edgeMargin
        anchors.bottomMargin: root.edgeMargin
        // Reserve renderable space *inside* the viewport so the first popup's
        // corner overlay can protrude above its delegate bounds without clipping.
        topMargin: root.popupOverlayTopBleed
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
            // Do not animate opacity during popup churn; keep rows fully legible.
            NumberAnimation {
                property: "x"
                from: 24
                to: 0
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        remove: Transition {
            // Keep removal motion simple and opacity-stable to avoid ghosting.
            NumberAnimation {
                property: "x"
                to: 24
                duration: 130
                easing.type: Easing.InCubic
            }
        }

        displaced: Transition {
            // Only animate vertical reflow to prevent transient opacity/x leakage.
            NumberAnimation {
                property: "y"
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        delegate: Item {
            id: rowWrapper
            required property var model
            readonly property int rowNotificationId: model && model.notificationId !== undefined ? Number(model.notificationId) : (model && model.id !== undefined ? Number(model.id) : -1)
            readonly property int rowRevision: model && model.revision !== undefined ? Number(model.revision) : 0
            readonly property var notificationSnapshot: {
                // Popups are capped service-side (maxActive) to avoid delegate visible/index gating loops.
                if (rowRevision < -1) {
                    return null;
                }
                if (rowNotificationId < 0) {
                    return null;
                }
                return root.notificationService.getNotification(rowNotificationId);
            }

            width: listView.width
            height: card.implicitHeight

            NotificationCard {
                id: card
                width: root.cardWidth
                height: parent.height
                anchors.right: parent.right
                anchors.top: parent.top

                notificationId: rowWrapper.rowNotificationId
                appName: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.appName !== undefined ? String(rowWrapper.notificationSnapshot.appName) : (rowWrapper.model && rowWrapper.model.appName ? String(rowWrapper.model.appName) : "")
                appIcon: rowWrapper.notificationSnapshot ? rowWrapper.notificationSnapshot.appIcon : (rowWrapper.model && rowWrapper.model.appIconHint ? String(rowWrapper.model.appIconHint) : "")
                appIconHint: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.appIconHint !== undefined ? String(rowWrapper.notificationSnapshot.appIconHint) : (rowWrapper.model && rowWrapper.model.appIconHint ? String(rowWrapper.model.appIconHint) : "")
                resolvedAppIconSource: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.resolvedAppIconSource !== undefined ? rowWrapper.notificationSnapshot.resolvedAppIconSource : (rowWrapper.model && rowWrapper.model.resolvedAppIconHint ? String(rowWrapper.model.resolvedAppIconHint) : "")
                resolvedAppIconHint: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.resolvedAppIconHint !== undefined ? String(rowWrapper.notificationSnapshot.resolvedAppIconHint) : (rowWrapper.model && rowWrapper.model.resolvedAppIconHint ? String(rowWrapper.model.resolvedAppIconHint) : "")
                summary: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.summary !== undefined ? String(rowWrapper.notificationSnapshot.summary) : (rowWrapper.model && rowWrapper.model.summary ? String(rowWrapper.model.summary) : "")
                body: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.body !== undefined ? String(rowWrapper.notificationSnapshot.body) : (rowWrapper.model && rowWrapper.model.body ? String(rowWrapper.model.body) : "")
                image: rowWrapper.notificationSnapshot ? rowWrapper.notificationSnapshot.image : (rowWrapper.model && rowWrapper.model.imageHint ? String(rowWrapper.model.imageHint) : "")
                imageHint: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.imageHint !== undefined ? String(rowWrapper.notificationSnapshot.imageHint) : (rowWrapper.model && rowWrapper.model.imageHint ? String(rowWrapper.model.imageHint) : "")
                rightSideImageSource: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.rightSideImageSource !== undefined ? String(rowWrapper.notificationSnapshot.rightSideImageSource) : (rowWrapper.model && rowWrapper.model.rightSideImageSource ? String(rowWrapper.model.rightSideImageSource) : "")
                contentPreviewImageSource: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.contentPreviewImageSource !== undefined ? String(rowWrapper.notificationSnapshot.contentPreviewImageSource) : (rowWrapper.model && rowWrapper.model.contentPreviewImageSource ? String(rowWrapper.model.contentPreviewImageSource) : "")
                hints: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.hints !== undefined ? rowWrapper.notificationSnapshot.hints : ({})
                timeLabel: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.timeLabel !== undefined ? String(rowWrapper.notificationSnapshot.timeLabel) : (rowWrapper.model && rowWrapper.model.timeLabel ? String(rowWrapper.model.timeLabel) : "")
                actions: rowWrapper.notificationSnapshot && rowWrapper.notificationSnapshot.actions ? rowWrapper.notificationSnapshot.actions : []
                keyboardInteractive: false
                interactionMode: "popup"
                showTimeLabel: false
                draggableDismiss: true
                pauseTimeoutOnHover: true
                externalHoverHold: root.stackHovered
                expandable: false
            }

            onRowNotificationIdChanged: card.resetVisualState()
            onRowRevisionChanged: card.resetVisualState()
        }
    }

    HoverHandler {
        id: stackHoverHandler
    }
}
