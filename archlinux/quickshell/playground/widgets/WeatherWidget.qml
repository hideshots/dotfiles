import QtQuick
import Quickshell.Widgets
import "../services" as Services

Rectangle {
    id: root

    implicitWidth: 164
    implicitHeight: 164
    radius: 22
    clip: false

    property string location: ""
    property string displayLocation: ""
    property string units: "m"
    property alias service: weatherService
    property real materialOpacity: 1.0
    property real glassTintOpacity: 0.35
    property real depthTopOpacity: 0.08
    property real depthBottomOpacity: 0
    property real innerStrokeOpacity: 0.11
    property real edgeHighlightOpacity: 0.10
    property real edgeShadeOpacity: 0.10
    property real noiseOpacity: 0.045
    property real shadowNearOpacity: 0.12
    property real shadowFarOpacity: 0.06

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

        Rectangle {
            anchors.fill: parent
            color: "transparent"
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(1, 1, 1, root.edgeHighlightOpacity * root.materialOpacity)
                }
                GradientStop {
                    position: 0.45
                    color: "transparent"
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0, 0, 0, root.edgeShadeOpacity * root.materialOpacity)
                }
            }
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
            id: contentColumn
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

        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            width: 58
            height: 14
        }
    }
}
