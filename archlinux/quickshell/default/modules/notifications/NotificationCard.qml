pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets

import "../.." as Root

FocusScope {
    id: root

    property int notificationId: -1
    property string appName: ""
    property string appIcon: ""
    property string summary: ""
    property string body: ""
    property string timeLabel: ""
    property var actions: []
    property int maxActionButtons: 2
    property bool keyboardInteractive: false
    property bool clickActivatesDefault: true
    property bool showDismissButton: true
    property bool showTimeLabel: true
    property bool showActions: true
    // "dismiss" (active popup semantics) | "removeHistory" (history list semantics)
    property string dismissMode: "dismiss"

    readonly property var notificationService: Root.NotificationService
    readonly property int cardPadding: 10
    readonly property bool hasBody: _trimmed(body).length > 0
    readonly property int actionButtonCount: Math.min(maxActionButtons, _safeLength(actions))
    readonly property string effectiveTitle: _trimmed(summary).length > 0 ? _trimmed(summary) : (_trimmed(appName).length > 0 ? _trimmed(appName) : "Notification")
    readonly property string fallbackIconText: _fallbackLabel()

    implicitWidth: 352
    implicitHeight: contentColumn.implicitHeight + (cardPadding * 2)
    activeFocusOnTab: keyboardInteractive

    Keys.onReturnPressed: if (keyboardInteractive)
        activateDefault()
    Keys.onEnterPressed: if (keyboardInteractive)
        activateDefault()
    Keys.onSpacePressed: if (keyboardInteractive)
        activateDefault()
    Keys.onEscapePressed: if (keyboardInteractive)
        dismiss()

    function _trimmed(value) {
        if (value === undefined || value === null) {
            return "";
        }
        return String(value).trim();
    }

    function _safeLength(value) {
        if (!value || value.length === undefined || value.length === null) {
            return 0;
        }
        var length = Number(value.length);
        if (!isFinite(length) || length < 0) {
            return 0;
        }
        return Math.floor(length);
    }

    function _fallbackLabel() {
        var name = _trimmed(appName);
        if (name.length === 0) {
            name = _trimmed(summary);
        }
        if (name.length === 0) {
            return "N";
        }
        return name.charAt(0).toUpperCase();
    }

    function _safeAction(index) {
        if (!actions || index < 0 || index >= _safeLength(actions)) {
            return null;
        }
        return actions[index];
    }

    function _actionId(action) {
        if (!action || action.id === undefined || action.id === null) {
            return "";
        }
        return String(action.id);
    }

    function _actionText(action) {
        if (!action || action.text === undefined || action.text === null) {
            return "";
        }
        return String(action.text);
    }

    function activateDefault() {
        if (notificationId < 0) {
            return;
        }
        notificationService.defaultActivate(notificationId);
    }

    function dismiss() {
        if (notificationId < 0) {
            return;
        }

        if (dismissMode === "removeHistory") {
            notificationService.removeFromHistory(notificationId);
            return;
        }

        notificationService.dismissNotification(notificationId);
    }

    function invokeAction(actionId) {
        if (notificationId < 0 || _trimmed(actionId).length === 0) {
            return;
        }
        notificationService.invokeAction(notificationId, actionId);
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Root.Theme.isDark ? Qt.rgba(0.12, 0.12, 0.12, 0.96) : Qt.rgba(0.98, 0.98, 0.98, 0.96)
        border.width: 1
        border.color: (root.keyboardInteractive && root.activeFocus) ? Qt.rgba(Root.Theme.menuHighlight.r, Root.Theme.menuHighlight.g, Root.Theme.menuHighlight.b, 0.55) : (Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.10))
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: "transparent"
        border.width: 1
        border.color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.70)
    }

    MouseArea {
        id: cardMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: function () {
            if (root.keyboardInteractive) {
                root.forceActiveFocus();
            }
            if (root.clickActivatesDefault) {
                root.activateDefault();
            }
        }
    }

    Column {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: root.cardPadding
        spacing: 8

        Row {
            id: headerRow
            width: parent.width
            spacing: 10

            Rectangle {
                id: iconSlot
                width: 32
                height: 32
                radius: 8
                color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.07)

                IconImage {
                    id: appIconImage
                    anchors.fill: parent
                    anchors.margins: 5
                    source: root._trimmed(root.appIcon)
                    visible: root._trimmed(root.appIcon).length > 0
                }

                Text {
                    anchors.centerIn: parent
                    text: root.fallbackIconText
                    visible: !appIconImage.visible
                    font.family: Root.Theme.fontFamilyDisplay
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: Root.Theme.textPrimary
                    renderType: Text.NativeRendering
                }
            }

            Column {
                id: textColumn
                width: Math.max(0, headerRow.width - iconSlot.width - controlsColumn.width - (headerRow.spacing * 2))
                spacing: 2

                Text {
                    width: parent.width
                    text: root.effectiveTitle
                    color: Root.Theme.textPrimary
                    font.family: Root.Theme.fontFamilyDisplay
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    wrapMode: Text.NoWrap
                    renderType: Text.NativeRendering
                }

                Text {
                    id: bodyText
                    width: parent.width
                    visible: root.hasBody
                    text: root._trimmed(root.body)
                    color: Root.Theme.textSecondary
                    opacity: 0.92
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                    renderType: Text.NativeRendering
                }
            }

            Column {
                id: controlsColumn
                spacing: 4
                width: Math.max(timeText.implicitWidth, dismissButton.width)

                Text {
                    id: timeText
                    text: root._trimmed(root.timeLabel)
                    visible: root.showTimeLabel && root._trimmed(root.timeLabel).length > 0
                    color: Root.Theme.textSecondary
                    opacity: 0.82
                    font.family: Root.Theme.fontFamily
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignRight
                    wrapMode: Text.NoWrap
                    renderType: Text.NativeRendering
                }

                Rectangle {
                    id: dismissButton
                    visible: root.showDismissButton
                    width: 20
                    height: 20
                    radius: 10
                    anchors.right: parent.right
                    color: dismissMouseArea.containsMouse ? (Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.12)) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "x"
                        color: Root.Theme.textSecondary
                        font.family: Root.Theme.fontFamilyDisplay
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: dismissMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.dismiss()
                    }
                }
            }
        }

        // TODO: expand this into richer action layouts in the notification-center phase.
        Row {
            id: actionRow
            visible: root.showActions && root.actionButtonCount > 0
            spacing: 6

            Repeater {
                model: root.actionButtonCount

                Rectangle {
                    id: actionButton
                    required property int index
                    readonly property var actionData: root._safeAction(index)
                    readonly property string actionId: root._actionId(actionData)
                    readonly property string actionText: root._actionText(actionData)

                    visible: actionText.length > 0
                    implicitHeight: 24
                    implicitWidth: Math.min(150, Math.max(70, actionLabel.implicitWidth + 16))
                    radius: 8
                    color: actionMouseArea.containsMouse ? Qt.rgba(Root.Theme.menuHighlight.r, Root.Theme.menuHighlight.g, Root.Theme.menuHighlight.b, 0.22) : (Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08))
                    border.width: 1
                    border.color: Root.Theme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.10)

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionButton.actionText
                        color: Root.Theme.textPrimary
                        font.family: Root.Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        renderType: Text.NativeRendering
                    }

                    MouseArea {
                        id: actionMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.invokeAction(actionButton.actionId)
                    }
                }
            }
        }
    }
}
