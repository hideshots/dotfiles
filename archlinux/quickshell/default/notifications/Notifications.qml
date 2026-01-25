import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Scope {
    id: root

    // Similar to your Eww window width (~442px)
    property int toastWidth: 442
    property int maxToasts: 6
    property int toastTimeoutMs: 5000

    ListModel { id: toastModel }

    function indexOfNotif(n) {
        for (let i = 0; i < toastModel.count; i++) {
            if (toastModel.get(i).notif === n) return i
        }
        return -1
    }

    function removeNotif(n) {
        const idx = indexOfNotif(n)
        if (idx >= 0) toastModel.remove(idx)
    }

    NotificationServer {
        id: server

        // Advertise capabilities so apps actually send actions/icons/etc. [web:52]
    actionsSupported: true
    actionIconsSupported: true

        onNotification: (n) => {
            // Track it, otherwise it will be discarded by the server. [web:52]
            n.tracked = true

            toastModel.insert(0, ({
                notif: n,
                createdAtMs: Date.now()
            }))

            if (toastModel.count > root.maxToasts) {
                const oldest = toastModel.get(toastModel.count - 1).notif
                // Dismiss oldest (timeout-style), then drop from UI.
                oldest.dismiss()
                toastModel.remove(toastModel.count - 1)
            }
        }
    }

    // Default: show on all monitors (same pattern as your current config).
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "qsnotifs"
            anchors { top: true; right: true }
            exclusiveZone: 0
            width: root.toastWidth + 20
            height: 600
            color: "transparent"

            Column {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 10
                width: root.toastWidth
                spacing: 8

                Repeater {
                    model: toastModel

                    delegate: Item {
                        id: toast
                        required property var notif
                        required property var createdAtMs
                        property var n: notif

                        width: parent.width
                        implicitHeight: card.implicitHeight

                        // Remove from UI as soon as it closes. [web:1]
                        Connections {
                            target: n
                            function onClosed() { root.removeNotif(n) }
                        }

                        // --- Card ---
                        Item {
                            id: card
                            width: toast.width
                            implicitHeight: content.implicitHeight + 24
                            clip: true

                            // Hover state like your Eww :onhover / :onhoverlost
                            HoverHandler { id: hover }
                            property bool hovered: hover.hovered

                            // Background: approximate your HTML “liquid glass” layers
                            Item {
                                anchors.fill: parent
                                z: 0

                                Rectangle {
                                  anchors.fill: parent
                                  radius: 16
                                  color: "#262626"     // solid color
                                  opacity: 0.78        // overall glass darkness
                                }

                            }

                            // Foreground content
                            RowLayout {
                                id: content
                                z: 1
                                x: 13
                                y: 12
                                width: parent.width - 26
                                spacing: 13

                                // App icon
                                // Quickshell provides Notification.appIcon (string) and falls back to desktop entry when possible. [web:1]
                                Image {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    source: n.appIcon ?? ""
                                    fillMode: Image.PreserveAspectFit
                                    visible: source !== ""
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    opacity: card.hovered ? 0.35 : 1.0

                                    Text {
                                        Layout.fillWidth: true
                                        text: n.summary ?? ""
                                        color: "#FFFFFF"
                                        font.pixelSize: 13
                                        font.bold: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: n.body ?? ""
                                        visible: text !== ""
                                        color: "#FFFFFF"
                                        font.pixelSize: 13
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                // Right side (timestamp placeholder)
                                ColumnLayout {
                                    Layout.alignment: Qt.AlignTop
                                    spacing: 7

                                    Text {
                                        text: "now"
                                        color: "#C6C6C6"
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }

                            // Action buttons overlay (bottom-right) shown on hover
                            Flow {
                                id: actions
                                z: 2
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 10
                                spacing: 8

                                visible: card.hovered && (n.actions && n.actions.length > 0)

                                Repeater {
                                    model: n.actions ?? []
                                    delegate: Button {
                                        required property var modelData // NotificationAction

                                        text: modelData.text ?? ""

                                        // If the notification has action icons, the identifier is the icon name. [web:46]
                                        icon.name: (n.hasActionIcons ? (modelData.identifier ?? "") : "")
                                        display: AbstractButton.TextBesideIcon

                                        onClicked: modelData.invoke() // Invokes action; may auto-dismiss if non-resident. [web:46]
                                    }
                                }
                            }

                            // Close button (top-left) shown on hover
                            Button {
                                z: 3
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.margins: 8

                                visible: card.hovered
                                text: "×"
                                width: 26
                                height: 26
                                padding: 0

                                onClicked: n.close() // Explicit user close. [web:1]
                            }

                            // Click card to close (Eww-style “onclick close”)
                            TapHandler {
                                acceptedButtons: Qt.LeftButton
                                onTapped: n.close()
                            }

                            // Fixed 5s timeout (dismiss/expire style)
                            Timer {
                                interval: root.toastTimeoutMs
                                running: true
                                repeat: false
                                onTriggered: n.dismiss()
                            }
                        }
                    }
                }
            }
        }
    }
}
