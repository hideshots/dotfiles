pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import "." as Weather
import "services" as Services

Rectangle {
    id: root

    implicitWidth: isMedium ? 338 : 164
    implicitHeight: isMedium ? 158 : 164
    radius: 22
    clip: false

    property string location: ""
    property string displayLocation: ""
    property string units: "m"
    property string variant: "small"
    property alias service: weatherService
    property real materialOpacity: 1.0
    property real glassTintOpacity: 0.55
    property real depthTopOpacity: 0.07
    property real depthBottomOpacity: 0.1
    property real innerStrokeOpacity: 0.11
    property real edgeHighlightOpacity: 0.6
    property real edgeShadeOpacity: 0.10
    property real rimWidthPx: 1.2
    property real rimGlowWidthPx: 1.0
    property real rimCornerBoost: 0.28
    property bool rimDebug: false
    property real noiseOpacity: 0.015
    property real shadowNearOpacity: 0.12
    property real shadowFarOpacity: 0.06
    readonly property bool isMedium: variant === "medium"

    color: "transparent"

    Services.WttrService {
        id: weatherService
        location: root.location
        units: root.units
    }

    Rectangle {
        anchors.fill: glassLayer
        anchors.margins: -1
        radius: root.radius + 1
        color: Qt.rgba(0, 0, 0, root.shadowNearOpacity * root.materialOpacity)
    }

    Rectangle {
        anchors.fill: glassLayer
        anchors.margins: -3
        radius: root.radius + 3
        color: Qt.rgba(0, 0, 0, root.shadowFarOpacity * root.materialOpacity)
    }

    ClippingRectangle {
        id: glassLayer
        anchors.fill: parent
        radius: root.radius
        color: Qt.rgba(20 / 255, 20 / 255, 20 / 255, root.glassTintOpacity * root.materialOpacity)

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(1, 1, 1, root.depthTopOpacity * root.materialOpacity)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0, 0, 0, root.depthBottomOpacity * root.materialOpacity)
                }
            }
        }

        Weather.EdgeRimEffect {
            anchors.fill: parent
            radius: root.radius
            rimWidthPx: root.rimWidthPx
            glowWidthPx: root.rimGlowWidthPx
            highlightOpacity: root.edgeHighlightOpacity * root.materialOpacity
            shadeOpacity: root.edgeShadeOpacity * root.materialOpacity
            cornerBoost: root.rimCornerBoost
            debug: root.rimDebug
            enabled: root.materialOpacity > 0
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(root.radius - 1, 0)
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, root.innerStrokeOpacity * root.materialOpacity)
        }

        Canvas {
            id: noiseLayer
            anchors.fill: parent
            opacity: root.noiseOpacity * root.materialOpacity
            smooth: false
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                const dotCount = Math.floor(width * height * 0.08);
                for (let i = 0; i < dotCount; i++) {
                    const v = Math.floor(Math.random() * 255);
                    ctx.fillStyle = "rgba(" + v + "," + v + "," + v + ",1)";
                    ctx.fillRect(
                        Math.floor(Math.random() * width),
                        Math.floor(Math.random() * height),
                        1,
                        1
                    );
                }
            }
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Component.onCompleted: requestPaint()
        }

        MouseArea {
            anchors.fill: parent
            onClicked: weatherService.refresh()
        }

        Column {
            id: smallContent
            visible: !root.isMedium
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 16
            spacing: 16

            Column {
                spacing: -3

                Row {
                    spacing: 4

                    Text {
                        text: root.displayLocation.trim().length > 0
                            ? root.displayLocation
                            : weatherService.data.city
                        color: "#FFFFFF"
                        elide: Text.ElideRight
                        width: 100
                        font.family: "SF Pro Text"
                        font.weight: Font.Bold
                        font.pixelSize: 14
                    }

                    Item {
                        width: 2
                        height: 1
                    }

                    Text {
                        visible: weatherService.offline
                        text: "Offline"
                        color: "#D8A5A5"
                        font.family: "SF Pro Text"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: weatherService.data.temp === "—"
                        ? "—"
                        : weatherService.data.temp + "°"
                    color: "#FFFFFF"
                    font.family: "SF Pro Display"
                    font.pixelSize: 42
                    font.weight: Font.Normal
                    lineHeight: 0.9
                }
            }

            Column {
                spacing: 0

                Text {
                    width: 19
                    height: 19
                    text: weatherService.data.symbol
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.family: "SF Pro"
                    font.pixelSize: 16
                    font.weight: Font.Normal
                }

                Text {
                    text: weatherService.data.condition
                    color: "#FFFFFF"
                    font.family: "SF Pro Text"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    width: 120
                }

                Item {
                    width: 2
                    height: 2
                }

                Text {
                    text: "H:" + weatherService.data.high + "° L:" + weatherService.data.low + "°"
                    color: "#D9D9D9"
                    font.family: "SF Pro Text"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                }
            }
        }

        Column {
            id: mediumContent
            visible: root.isMedium
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16

            Row {
                width: parent.width
                spacing: 12

                Column {
                    width: 156
                    spacing: -2

                    Row {
                        spacing: 4

                        Text {
                            text: root.displayLocation.trim().length > 0
                                ? root.displayLocation
                                : weatherService.data.city
                            color: "#FFFFFF"
                            elide: Text.ElideRight
                            width: 112
                            font.family: "SF Pro Text"
                            font.weight: Font.Bold
                            font.pixelSize: 14
                        }

                        Text {
                            visible: weatherService.offline
                            text: "Offline"
                            color: "#D8A5A5"
                            font.family: "SF Pro Text"
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }

                    Text {
                        text: weatherService.data.temp === "—"
                            ? "—"
                            : weatherService.data.temp + "°"
                        color: "#FFFFFF"
                        font.family: "SF Pro Display"
                        font.pixelSize: 42
                        font.weight: Font.Normal
                        lineHeight: 0.9
                    }
                }

                Column {
                    width: parent.width - 168
                    spacing: 2

                    Text {
                        text: weatherService.data.symbol
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                        font.family: "SF Pro"
                        font.pixelSize: 16
                        font.weight: Font.Normal
                    }

                    Text {
                        text: weatherService.data.condition
                        color: "#FFFFFF"
                        font.family: "SF Pro Text"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                    }

                    Text {
                        text: "H:" + weatherService.data.high + "° L:" + weatherService.data.low + "°"
                        color: "#D9D9D9"
                        font.family: "SF Pro Text"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignRight
                        width: parent.width
                    }
                }
            }

            Row {
                id: hourlyRow
                width: parent.width
                spacing: 0

                Repeater {
                    model: 6

                    Column {
                        required property int index

                        width: root.isMedium ? (mediumContent.width / 6) : 0
                        spacing: 4

                        readonly property var hourlyEntry: {
                            const hourly = root.service.data.hourly;
                            if (!Array.isArray(hourly) || index >= hourly.length) {
                                return { timeLabel: "—", symbol: "—", temp: "—" };
                            }
                            return hourly[index];
                        }

                        Text {
                            text: parent.hourlyEntry.timeLabel || "—"
                            color: "#AEB4BB"
                            font.family: "SF Pro Text"
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        Text {
                            text: parent.hourlyEntry.symbol || "—"
                            color: "#FFFFFF"
                            font.family: "SF Pro"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }

                        Text {
                            text: parent.hourlyEntry.temp === "—" ? "—" : parent.hourlyEntry.temp + "°"
                            color: "#FFFFFF"
                            font.family: "SF Pro Text"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                            width: parent.width
                        }
                    }
                }
            }
        }
    }
}
