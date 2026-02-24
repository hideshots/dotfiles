pragma ComponentBehavior: Bound

import QtQuick

import "../.." as Root

FocusScope {
    id: root

    property bool open: false
    property int panelWidth: 392
    property int panelHeight: 560
    property int panelPadding: 10
    property int headerHeight: 42
    property int listSpacing: 8
    property int maxHistoryVisible: 100
    property var expandedById: ({})

    readonly property var notificationService: Root.NotificationService
    readonly property bool hasHistory: notificationService.historyCount > 0

    signal requestClose

    implicitWidth: panelWidth
    implicitHeight: panelHeight

    visible: open || opacity > 0.01
    opacity: open ? 1 : 0
    x: open ? 0 : 16
    enabled: opacity > 0.95
    focus: open

    Keys.onEscapePressed: function(event) {
        if (!root.open) {
            return;
        }

        event.accepted = true;
        root.requestClose();
    }

    onOpenChanged: {
        if (open) {
            pruneExpandedState();
            return;
        }

        clearExpandedState();
    }

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

    Connections {
        target: root.notificationService

        function onHistoryCountChanged() {
            root.pruneExpandedState();
        }
    }

    function _idKey(value) {
        if (value === undefined || value === null) {
            return "";
        }
        return String(value);
    }

    function _hasOwn(objectValue, key) {
        return Object.prototype.hasOwnProperty.call(objectValue, key);
    }

    function clearExpandedState() {
        expandedById = ({})
    }

    function isExpanded(notificationId) {
        var key = _idKey(notificationId);
        return _hasOwn(expandedById, key) && !!expandedById[key];
    }

    function setExpanded(notificationId, expanded) {
        var next = ({})
        var key = _idKey(notificationId);
        var source = expandedById || ({})
        var mapKey = "";

        for (mapKey in source) {
            if (!_hasOwn(source, mapKey) || mapKey === key || !source[mapKey]) {
                continue;
            }
            next[mapKey] = true;
        }

        if (expanded) {
            next[key] = true;
        }

        expandedById = next;
    }

    function toggleExpanded(notificationId) {
        setExpanded(notificationId, !isExpanded(notificationId));
    }

    function pruneExpandedState() {
        var allowed = ({})
        var i = 0;

        for (i = 0; i < notificationService.historyCount; i++) {
            var row = notificationService.historyList.get(i);
            allowed[_idKey(row.id)] = true;
        }

        var next = ({})
        var source = expandedById || ({})
        var key = "";

        for (key in source) {
            if (!_hasOwn(source, key) || !source[key] || !_hasOwn(allowed, key)) {
                continue;
            }
            next[key] = true;
        }

        expandedById = next;
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
                        acceptedButtons: Qt.LeftButton
                        preventStealing: true
                        cursorShape: Qt.PointingHandCursor

                        onPressed: function(mouse) {
                            mouse.accepted = true;
                        }

                        onClicked: function(mouse) {
                            mouse.accepted = true;
                            root.notificationService.clearHistory();
                        }
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
                        acceptedButtons: Qt.LeftButton
                        preventStealing: true
                        cursorShape: Qt.PointingHandCursor

                        onPressed: function(mouse) {
                            mouse.accepted = true;
                        }

                        onClicked: function(mouse) {
                            mouse.accepted = true;
                            root.requestClose();
                        }
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
                verticalLayoutDirection: ListView.TopToBottom

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

                    readonly property bool withinVisibleLimit: index < Math.max(0, root.maxHistoryVisible)

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
                    showActions: true
                    showDismissButton: true
                    showTimeLabel: true
                    dismissMode: "removeHistory"
                    clickActivatesDefault: true

                    interactionMode: "center"
                    draggableDismiss: false
                    pauseTimeoutOnHover: false
                    expandable: true
                    expanded: root.isExpanded(notificationId)
                    showActionsWhenExpanded: true

                    onRequestExpandToggle: root.toggleExpanded(notificationId)
                }
            }
        }
    }
}
