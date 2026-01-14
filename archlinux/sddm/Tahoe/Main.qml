import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Item {
    id: root
    width: 1920
    height: 1080
    focus: true

    property bool uiVisible: false
    readonly property int inactivityMs: 30000
    readonly property int fadeMs: 820

    // SDDM-provided models: sessionModel, userModel, and sddm proxy object.
    // Keep selected indices stable even when popups open/close.
    property int selectedSessionIndex: (sessionModel && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0
    property string selectedUserName: (userModel && userModel.lastUser && userModel.lastUser.length > 0)
                                     ? userModel.lastUser : "drama"

    QtObject {
        id: theme
        readonly property color white: "#ffffff"
        readonly property color panel: "#262626"
        readonly property color accent: "#0088ff"

        readonly property int topMargin: 96
        readonly property int corner: 13

        readonly property int loginBottomMargin: 43
        readonly property int loginWidth: 198

        readonly property string fontUI: "SF Pro Display"
        readonly property string fontEmoji: "Apple Color Emoji"
    }

    function emojiForUser(u) {
        if (u === "drama") return "🦅"
        if (u === "root")  return "🛠️"
        return "👤"
    }

    function closePopups() {
        if (sessionPicker.visible) sessionPicker.close()
        if (userPicker.visible) userPicker.close()
    }

    function bumpActivity(focusPassword) {
        uiVisible = true
        idleTimer.restart()
        if (focusPassword === true) {
            Qt.callLater(function() { passwordField.forceActiveFocus() })
        }
    }

    Item {
        id: backgroundLayer
        anchors.fill: parent
        z: -10

        Image {
            id: bg
            anchors.fill: parent
            source: "background.png"
            fillMode: Image.PreserveAspectCrop
            smooth: true
            cache: true
        }

        ShaderEffectSource {
            id: bgSrc
            anchors.fill: parent
            sourceItem: bg
            live: true
            hideSource: true
        }

        ShaderEffect {
            anchors.fill: parent
            property variant source: bgSrc
            property real strength: 0.2
            property real zoom: 1.09
            fragmentShader: "pincushion.frag.qsb"
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        onPositionChanged: root.bumpActivity(false)
    }

    Keys.onPressed: root.bumpActivity(false)

    Timer {
        id: idleTimer
        interval: root.inactivityMs
        repeat: false
        running: true
        onTriggered: {
            root.uiVisible = false
            root.closePopups()
        }
    }

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Item {
        id: dateTimeBox
        anchors.top: parent.top
        anchors.topMargin: theme.topMargin
        anchors.horizontalCenter: parent.horizontalCenter
        z: 50

        width: Math.max(timeText.implicitWidth, dateText.implicitWidth)
        height: Math.max(timeText.y + timeText.implicitHeight, dateText.y + dateText.implicitHeight)

        Text {
            id: dateText
            opacity: 0.65
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "ddd MMM d")
            color: theme.white
            font.pixelSize: 32
            font.family: theme.fontUI
            font.weight: Font.DemiBold
            font.letterSpacing: -0.64
            wrapMode: Text.NoWrap
        }

        Text {
            id: timeText
            opacity: 0.5
            anchors.top: parent.top
            anchors.topMargin: 17
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(root.now, "h:mm")
            color: theme.white
            font.pixelSize: 150
            font.family: theme.fontUI
            font.weight: Font.Bold
            font.letterSpacing: -3.0
            wrapMode: Text.NoWrap
        }

        // Edge-light effect
        Text {
            id: timeMaskText
            visible: false
            anchors.fill: timeText
            text: timeText.text
            color: theme.white
            font: timeText.font
            wrapMode: Text.NoWrap
        }

        ShaderEffectSource {
            id: timeMaskSrc
            sourceItem: timeMaskText
            hideSource: true
            live: true
        }

        ShaderEffect {
            id: timeEdge
            anchors.fill: timeText
            z: timeText.z + 1

            property variant maskSource: timeMaskSrc
            property real edgePx: 1.35
            property real intensity: 0.55
            property vector2d invSize: Qt.vector2d(
                1.0 / Math.max(1, width),
                1.0 / Math.max(1, height)
            )
            property vector2d lightDir: Qt.vector2d(-0.7071067, -0.7071067)
            fragmentShader: "time_edge_light.frag.qsb"
        }
    }

    FocusScope {
        id: chrome
        anchors.fill: parent
        z: 49

        opacity: root.uiVisible ? 1.0 : 0.0
        visible: opacity > 0.01
        enabled: visible

        Behavior on opacity {
            NumberAnimation { duration: root.fadeMs; easing.type: Easing.OutCubic }
        }

        // Hidden ComboBox kept as a compatibility anchor for sessionModel usage
        ComboBox {
            id: sessionSelect
            visible: false
            model: sessionModel
            textRole: "name"
            currentIndex: root.selectedSessionIndex
            onCurrentIndexChanged: root.selectedSessionIndex = currentIndex
        }

        // Session button (top-right)
        Item {
            id: sessionButton
            width: 28
            height: 28
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 15
            anchors.rightMargin: 15
            z: 50

            Text {
                anchors.centerIn: parent
                text: "􀣌"
                color: theme.white
                opacity: 0.7
                font.pixelSize: 14
                font.family: theme.fontUI
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.bumpActivity(true)
                    sessionPicker.toggle()
                }
            }
        }

        // Login panel (bottom-center)
        Item {
          id: loginPanel
          width: theme.loginWidth
          height: 90
          z: 50
          visible: !userPicker.visible

          anchors.horizontalCenter: parent.horizontalCenter

          // Original: y: root.height - 43 - 171 + (801 - 866)
          y: root.height - theme.loginBottomMargin - height + (801 - 866)

            Column {
                anchors.fill: parent
                spacing: 10

                Item {
                    id: avatarRow
                    width: parent.width
                    height: 52

                    Rectangle {
                        id: avatar
                        width: 52
                        height: 52
                        radius: 26
                        anchors.horizontalCenter: parent.horizontalCenter
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#929292" }
                            GradientStop { position: 1.0; color: "#4d4d4d" }
                        }

                        readonly property int emojiSize: Math.round(width * 0.6)

                        Text {
                            anchors.centerIn: parent
                            text: root.emojiForUser(root.selectedUserName)
                            font.pixelSize: avatar.emojiSize
                            font.family: theme.fontEmoji
                            color: theme.white
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.bumpActivity(false)
                                userPicker.openAt(avatar)
                            }
                        }
                    }
                }

                Text {
                    id: userNameText
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.selectedUserName
                    color: theme.white
                    font.pixelSize: 15
                    font.family: theme.fontUI
                    font.weight: Font.Bold
                    font.letterSpacing: -0.90
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                }

                TextField {
                    id: passwordField
                    width: 160
                    height: 28
                    anchors.horizontalCenter: parent.horizontalCenter

                    echoMode: TextInput.Password
                    color: theme.white
                    font.pixelSize: 13
                    font.family: theme.fontUI
                    font.weight: Font.Bold

                    leftPadding: 14
                    rightPadding: 14

                    placeholderText: "Enter Password"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.45)

                    background: Rectangle {
                        radius: height / 2
                        color: "#d9d9d9"
                        opacity: 0.45
                    }

                    Keys.onReturnPressed: sddm.login(root.selectedUserName, text, root.selectedSessionIndex)
                    Keys.onEnterPressed:  sddm.login(root.selectedUserName, text, root.selectedSessionIndex)

                    onTextEdited: root.bumpActivity(false)
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Your password is required to\nlog in"
                    opacity: 0.45
                    color: theme.white
                    font.pixelSize: 13
                    font.family: theme.fontUI
                    font.weight: Font.Bold
                    font.letterSpacing: -0.65
                }
            }
        }
    }

    Popup {
        id: sessionPicker
        parent: (Overlay.overlay ? Overlay.overlay : root)
        z: 100
        padding: 0
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        function reposition() {
            const p = sessionButton.mapToItem(sessionPicker.parent, 0, 0)

            let w = sessionPicker.implicitWidth
            if (w <= 0 && sessionPicker.contentItem) w = sessionPicker.contentItem.implicitWidth
            if (w <= 0) w = 200

            const gap = 15
            const desiredX = (p.x + sessionButton.width - w) - gap
            const maxX = sessionPicker.parent.width - w

            sessionPicker.x = Math.round(Math.max(0, Math.min(maxX, desiredX)))
            sessionPicker.y = Math.round(p.y + sessionButton.height + 8)
        }

        function toggle() {
            root.bumpActivity(false)
            if (!chrome.visible) return
            if (sessionPicker.visible) sessionPicker.close()
            else sessionPicker.open()
        }

        onOpened: reposition()
        onWidthChanged: if (visible) reposition()
        onImplicitWidthChanged: if (visible) reposition()

        background: Rectangle {
            radius: theme.corner
            color: theme.panel
            opacity: 0.85
        }

        contentItem: Item {
            implicitWidth: sessionListView.implicitWidth + 24
            implicitHeight: sessionListView.contentHeight + 10

            ListView {
                id: sessionListView
                x: 12
                y: 5
                width: implicitWidth
                height: contentHeight
                interactive: false
                model: sessionModel

                property real implicitWidth: Math.max(95, Math.min(320, maxTextWidth + 24))
                property real maxTextWidth: 0

                delegate: Item {
                    width: sessionListView.implicitWidth
                    height: 24

                    required property int index
                    required property string name

                    Component.onCompleted: sessionListView.maxTextWidth =
                            Math.max(sessionListView.maxTextWidth, sessionLabel.implicitWidth)

                    Rectangle {
                        x: -7
                        y: 0
                        width: parent.width + 14
                        height: parent.height
                        radius: 8
                        color: theme.accent
                        visible: hoverArea.containsMouse
                    }

                    Text {
                        id: sessionLabel
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        text: name
                        color: theme.white
                        font.pixelSize: 13
                        font.family: theme.fontUI
                        font.weight: Font.Medium
                    }

                    MouseArea {
                        id: hoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.bumpActivity(true)
                            root.selectedSessionIndex = index
                            sessionSelect.currentIndex = index
                            sessionPicker.close()
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: userPicker
        parent: (Overlay.overlay ? Overlay.overlay : root)
        z: 100
        padding: 10
        modal: false
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        property Item anchorItem: null

        function openAt(item) {
            anchorItem = item
            open()
        }

        function reposition() {
            if (!anchorItem) return
            const p = anchorItem.mapToItem(userPicker.parent, 0, 0)

            // Center horizontally on avatar, show above it if possible, else below.
            userPicker.x = Math.round(p.x + (anchorItem.width - userPicker.width) / 2)
            const aboveY = p.y - userPicker.height - 10
            const belowY = p.y + anchorItem.height + 10
            userPicker.y = Math.round((aboveY >= 0) ? aboveY : belowY)
        }

        onOpened: {
            root.bumpActivity(false)
            reposition()
        }
        onWidthChanged: if (visible) reposition()
        onHeightChanged: if (visible) reposition()

        background: Rectangle {
            radius: theme.corner
            color: theme.panel
            opacity: 0
        }

        contentItem: ListView {
            id: userListView
            spacing: 13
            interactive: false
            model: userModel

            implicitWidth: 260
            implicitHeight: Math.min(260, contentHeight)

            delegate: Item {
                width: userListView.width
                height: 52
                required property string name

                Row {
                    anchors.fill: parent
                    spacing: 11

                    Rectangle {
                        width: 52
                        height: 52
                        radius: 26
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#929292" }
                            GradientStop { position: 1.0; color: "#4d4d4d" }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: root.emojiForUser(name)
                            font.pixelSize: 32
                            font.family: theme.fontEmoji
                            color: theme.white
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: name
                        font.pixelSize: 15
                        font.family: theme.fontUI
                        font.weight: Font.Bold
                        font.letterSpacing: -0.90
                        color: theme.white
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight
                        width: parent.width - 52 - 11
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.bumpActivity(true)
                        root.selectedUserName = name
                        passwordField.text = ""
                        userPicker.close()
                    }
                }
            }
        }
    }
}
