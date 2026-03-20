pragma ComponentBehavior: Bound

import QtQuick
import Qt5Compat.GraphicalEffects

import ".." as Root
import "../menu" as Menu

Rectangle {
    id: root

    property var highlightState: null

    readonly property var battery: Root.BatteryService
    readonly property var _batterySvgWarmupNames: ["battery.100percent.bolt", "battery.100percent", "battery.75percent", "battery.50percent", "battery.25percent", "battery.0percent"]
    readonly property bool _showPercentageCapsule: root.battery.showPercentage
    readonly property string _percentageDisplayText: String(root.battery.percentage)
    readonly property real _fixedPercentageCapsuleWidth: Math.max(
        Root.Theme.batteryPercentageCapsuleMinWidth,
        Math.ceil(percentageCapsuleTemplateMetrics.implicitWidth) + (Root.Theme.batteryPercentageCapsuleHorizontalPadding * 2)
    )
    readonly property real _contentWidth: Math.max(_fixedPercentageCapsuleWidth, batteryIcon.implicitWidth)

    visible: battery.visible
    height: parent.height
    width: visible ? contentVisual.implicitWidth + (Root.Theme.rightWidgetPadding * 2) : 0
    color: "transparent"
    radius: Root.Theme.borderRadius

    function _capsuleFontWeightKeyword(weight) {
        return weight >= Font.Bold ? "bold" : "normal";
    }

    function _capsuleCanvasFontSpec() {
        return root._capsuleFontWeightKeyword(Root.Theme.batteryPercentageCapsuleFontWeight)
            + " "
            + Root.Theme.batteryPercentageCapsuleFontSize
            + "px '"
            + Root.Theme.batteryPercentageCapsuleFontFamily
            + "'";
    }

    function _addRoundedRectPath(ctx, width, height, radius) {
        var clampedRadius = Math.max(0, Math.min(radius, width / 2, height / 2));

        ctx.beginPath();
        ctx.moveTo(clampedRadius, 0);
        ctx.lineTo(width - clampedRadius, 0);
        ctx.arc(width - clampedRadius, clampedRadius, clampedRadius, -Math.PI / 2, 0, false);
        ctx.lineTo(width, height - clampedRadius);
        ctx.arc(width - clampedRadius, height - clampedRadius, clampedRadius, 0, Math.PI / 2, false);
        ctx.lineTo(clampedRadius, height);
        ctx.arc(clampedRadius, height - clampedRadius, clampedRadius, Math.PI / 2, Math.PI, false);
        ctx.lineTo(0, clampedRadius);
        ctx.arc(clampedRadius, clampedRadius, clampedRadius, Math.PI, (Math.PI * 3) / 2, false);
        ctx.closePath();
    }

    readonly property var powerProfileMenuModel: root._buildPowerProfileMenuModel()
    function _buildPowerProfileMenuModel() {
        var items = [
            {
                type: "header",
                label: "Power Profile"
            }
        ];

        if (!root.battery.powerProfilesAvailable) {
            items.push({
                type: "action",
                label: root.battery.powerProfilesChecked ? "Unavailable" : "Checking",
                disabled: true
            });
            return items;
        }

        if (root.battery.powerProfileDegradationReason.length > 0) {
            items.push({
                type: "action",
                label: root.battery.powerProfileDegradationReason,
                disabled: true
            });
            items.push({
                type: "separator"
            });
        }

        var choices = root.battery.powerProfileChoices;
        for (var i = 0; i < choices.length; i++) {
            var choice = choices[i];
            if (!choice) {
                continue;
            }

            items.push({
                type: "action",
                label: choice.label,
                reserveCheckmark: true,
                checked: root.battery.powerProfile === choice.profile,
                action: (function (profile) {
                        return function () {
                            root.battery.setPowerProfile(profile);
                        };
                    })(choice.profile)
            });
        }

        return items;
    }

    function syncHighlight() {
        if (!root.highlightState) {
            return;
        }

        if (batteryMenu.visible) {
            root.highlightState.activeTarget = root;
            return;
        }

        if (root.highlightState.activeTarget === root) {
            root.highlightState.activeTarget = null;
        }
    }

    onVisibleChanged: {
        if (!visible && batteryMenu.visible) {
            batteryMenu.closeTopMenu();
        }
    }

    Item {
        id: batterySvgWarmup
        visible: false

        Repeater {
            model: root._batterySvgWarmupNames

            Image {
                required property string modelData
                source: Qt.resolvedUrl("../" + Root.Symbols.svgDir + "/" + modelData + ".svg")
                asynchronous: true
                cache: true
                sourceSize.width: Root.Theme.iconSize
                sourceSize.height: Root.Theme.iconSize
            }
        }
    }

    Item {
        id: contentVisual
        anchors.centerIn: parent
        implicitWidth: root._contentWidth
        implicitHeight: root._showPercentageCapsule ? batteryPercentageCapsule.implicitHeight : batteryIcon.implicitHeight

        Text {
            id: percentageCapsuleTemplateMetrics
            visible: false
            text: "100"
            font.family: Root.Theme.batteryPercentageCapsuleFontFamily
            font.pixelSize: Root.Theme.batteryPercentageCapsuleFontSize
            font.weight: Root.Theme.batteryPercentageCapsuleFontWeight
            renderType: Text.NativeRendering
        }

        Canvas {
            id: batteryPercentageCapsule
            anchors.centerIn: parent
            visible: root._showPercentageCapsule
            width: root._fixedPercentageCapsuleWidth
            height: Root.Theme.batteryPercentageCapsuleHeight
            implicitWidth: width
            implicitHeight: height
            smooth: true
            antialiasing: true

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                ctx.fillStyle = Root.Theme.batteryPercentageCapsuleFill;
                root._addRoundedRectPath(ctx, width, height, Root.Theme.batteryPercentageCapsuleRadius);
                ctx.fill();

                ctx.globalCompositeOperation = "destination-out";
                ctx.fillStyle = "rgba(0,0,0,1)";
                ctx.textAlign = "center";
                ctx.textBaseline = "middle";
                ctx.font = root._capsuleCanvasFontSpec();
                ctx.fillText(
                    root._percentageDisplayText,
                    width * 0.5,
                    (height * 0.5) + Root.Theme.batteryPercentageCapsuleTextVerticalOffset
                );
                ctx.globalCompositeOperation = "source-over";
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onVisibleChanged: requestPaint()
            Component.onCompleted: requestPaint()
        }

        Root.SymbolIcon {
            id: batteryIcon
            anchors.centerIn: parent
            visible: !root._showPercentageCapsule
            width: Root.Theme.iconSize
            height: Root.Theme.iconSize
            fallbackWhileSvgLoading: false
            glyph: root.battery.iconGlyph
            fallbackFontFamily: Root.Theme.fontFamily
            pixelSize: Root.Theme.iconSize
            fallbackColor: Root.Theme.textSecondary
        }

        DropShadow {
            anchors.fill: batteryIcon
            source: batteryIcon
            visible: Root.Theme.isDark && !root._showPercentageCapsule
            horizontalOffset: Root.Theme.shadowHorizontalOffset
            verticalOffset: Root.Theme.shadowVerticalOffset
            radius: Root.Theme.shadowRadius
            samples: 16
            spread: 0
            color: Root.Theme.shadowColor
        }
    }

    Connections {
        target: root.battery
        function onPercentageChanged() {
            batteryPercentageCapsule.requestPaint();
        }

        function onShowPercentageChanged() {
            batteryPercentageCapsule.requestPaint();
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: batteryMenu.toggle()
    }

    Menu.MenuPopup {
        id: batteryMenu
        anchorItem: root
        anchorPointX: root.width - implicitWidth
        anchorPointY: root.height + yOffset
        yOffset: 8
        adaptiveWidth: true

        model: [
            {
                type: "header",
                label: "Battery"
            },
            {
                type: "action",
                label: "Power source: " + root.battery.powerSourceText,
                disabled: true
            },
            {
                type: "action",
                label: "Status: " + root.battery.statusText,
                disabled: true
            },
            {
                type: "separator"
            },
            {
                type: "action",
                label: "Power Profile: " + root.battery.powerProfileText,
                submenu: root.powerProfileMenuModel,
                disabled: !root.battery.powerProfilesAvailable
            },
            {
                type: "separator"
            },
            {
                type: "action",
                label: "Show Percentage",
                reserveCheckmark: true,
                checked: root.battery.showPercentage,
                action: function () {
                    root.battery.showPercentage = !root.battery.showPercentage;
                }
            }
        ]
    }

    Connections {
        target: batteryMenu
        function onVisibleChanged() {
            root.syncHighlight();
        }
    }

    Component.onDestruction: {
        if (root.highlightState && root.highlightState.activeTarget === root) {
            root.highlightState.activeTarget = null;
        }
    }
}
