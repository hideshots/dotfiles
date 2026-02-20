pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import "../weather"

Rectangle {
    id: root

    implicitWidth: 164
    implicitHeight: 164
    radius: 22
    clip: false

    signal requestContextMenu(real x, real y)

    property bool showLabel: false
    property bool followSystemDate: true

    property int shownYear: (new Date()).getFullYear()
    property int shownMonth: (new Date()).getMonth()

    property color calendarBackground: Qt.rgba(20 / 255, 20 / 255, 20 / 255, 0.55)
    property color accentColor: Qt.rgba(1.0, 1.0, 1.0, 0.75)
    property color weekendColor: Qt.rgba(1.0, 1.0, 1.0, 0.50)
    property color dateColor: Qt.rgba(1.0, 1.0, 1.0, 0.75)

    property real materialOpacity: 1.0
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

    readonly property int cellSize: 18
    readonly property int rowGap: 6
    readonly property int gridWidth: 134

    // Model
    property var cells: []
    property int rowsUsed: 6

    property int _lastSystemDay: -1
    property int _lastSystemMonth: -1
    property int _lastSystemYear: -1

    readonly property var weekdayLabels: ["S", "M", "T", "W", "T", "F", "S"]

    color: "transparent"

    function daysInMonth(year, month) {
        return new Date(year, month + 1, 0).getDate();
    }

    function monthLabel(year, month) {
        const value = new Date(year, month, 1).toLocaleString(Qt.locale(), "MMMM");
        return value.toUpperCase();
    }

    function buildCells(year, month) {
        const result = [];
        const now = new Date();
        const todayDay = now.getDate();
        const todayMonth = now.getMonth();
        const todayYear = now.getFullYear();

        // Sunday-first offset: 0..6
        const firstDayOffset = new Date(year, month, 1).getDay();
        const total = daysInMonth(year, month);

        // How many rows are actually needed this month: 4..6
        const neededRows = Math.ceil((firstDayOffset + total) / 7);
        rowsUsed = Math.max(4, Math.min(6, neededRows));

        for (let i = 0; i < 42; i++) {
            const day = i - firstDayOffset + 1;
            const inMonth = day >= 1 && day <= total;
            const col = i % 7;
            const isToday = inMonth && day === todayDay && month === todayMonth && year === todayYear;
            result.push({
                day: inMonth ? day : 0,
                inMonth: inMonth,
                isToday: isToday,
                col: col
            });
        }

        return result;
    }

    function refreshCells() {
        cells = buildCells(shownYear, shownMonth);
    }

    function colorToRgbaString(value, opacityScale) {
        const alpha = Math.max(0, Math.min(1, value.a * opacityScale));
        return "rgba("
            + Math.round(value.r * 255) + ","
            + Math.round(value.g * 255) + ","
            + Math.round(value.b * 255) + ","
            + alpha + ")";
    }

    Timer {
        interval: 60 * 1000
        repeat: true
        running: true
        onTriggered: {
            const now = new Date();
            const day = now.getDate();
            const month = now.getMonth();
            const year = now.getFullYear();

            const changed = day !== root._lastSystemDay
                || month !== root._lastSystemMonth
                || year !== root._lastSystemYear;

            if (!changed) {
                return;
            }

            root._lastSystemDay = day;
            root._lastSystemMonth = month;
            root._lastSystemYear = year;

            if (root.followSystemDate) {
                root.shownYear = year;
                root.shownMonth = month;
            }

            root.refreshCells();
        }
    }

    Component.onCompleted: {
        const now = new Date();
        _lastSystemDay = now.getDate();
        _lastSystemMonth = now.getMonth();
        _lastSystemYear = now.getFullYear();
        refreshCells();
    }

    // Shadows (same pattern as WeatherWidget)
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
        color: Qt.rgba(
            root.calendarBackground.r,
            root.calendarBackground.g,
            root.calendarBackground.b,
            root.calendarBackground.a * root.materialOpacity
        )

        // Depth overlays
        // Rectangle {
        //     anchors.fill: parent
        //     gradient: Gradient {
        //         GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.depthTopOpacity * root.materialOpacity) }
        //         GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.0) }
        //         GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.depthBottomOpacity * root.materialOpacity) }
        //     }
        // }

        // Rim shader (reuse)
        EdgeRimEffect {
            anchors.fill: parent
            radius: root.radius
            rimWidthPx: root.rimWidthPx
            glowWidthPx: root.rimGlowWidthPx
            highlightOpacity: root.edgeHighlightOpacity * root.materialOpacity
            shadeOpacity: root.edgeShadeOpacity * root.materialOpacity
            cornerBoost: root.rimCornerBoost
            debug: root.rimDebug
        }

        // Inner stroke
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, root.innerStrokeOpacity * root.materialOpacity)
        }

        // Noise
        Canvas {
            anchors.fill: parent
            opacity: root.noiseOpacity * root.materialOpacity
            smooth: false
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                const dotCount = Math.floor(width * height * 0.08);
                for (let i = 0; i < dotCount; i++) {
                    const value = Math.floor(Math.random() * 255);
                    ctx.fillStyle = "rgba(" + value + "," + value + "," + value + ",1)";
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
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPressed: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    root.requestContextMenu(mouse.x, mouse.y);
                }
            }
        }

        Item {
            id: content
            anchors.fill: parent
            anchors.topMargin: 17
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: 16

            Item {
                id: monthHeader
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 15

                Text {
                    anchors.top: parent.top
                    anchors.topMargin: 2
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    text: root.monthLabel(root.shownYear, root.shownMonth)
                    color: Qt.rgba(
                        root.accentColor.r,
                        root.accentColor.g,
                        root.accentColor.b,
                        root.accentColor.a * root.materialOpacity
                    )
                    font.family: "SF Pro Text"
                    font.weight: Font.DemiBold
                    font.pixelSize: 11
                    renderType: Text.NativeRendering
                }
            }

            Item {
                id: weekdayRow
                anchors.top: monthHeader.bottom
                anchors.topMargin: 3
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.gridWidth
                height: root.cellSize

                readonly property real xStride: (width - (7 * root.cellSize)) / 6

                Repeater {
                    model: root.weekdayLabels.length
                    delegate: Item {
                        id: weekdayCell
                        required property int index
                        x: index * (root.cellSize + weekdayRow.xStride)
                        width: root.cellSize
                        height: root.cellSize

                        Text {
                            anchors.centerIn: parent
                            text: root.weekdayLabels[weekdayCell.index]
                            color: (weekdayCell.index === 0 || weekdayCell.index === 6) ? root.weekendColor : root.dateColor
                            font.family: "SF Pro Text"
                            font.weight: Font.DemiBold
                            font.pixelSize: 10
                            opacity: root.materialOpacity
                            renderType: Text.NativeRendering
                        }
                    }
                }
            }

            Item {
                id: dateGrid
                anchors.top: weekdayRow.bottom
                anchors.topMargin: 2
                anchors.horizontalCenter: parent.horizontalCenter
                width: root.gridWidth
                height: (root.rowsUsed * root.cellSize) + ((root.rowsUsed - 1) * root.rowGap)

                readonly property real xStride: (width - (7 * root.cellSize)) / 6

                Repeater {
                    model: root.cells
                    delegate: Item {
                        id: dayCell
                        required property int index
                        required property var modelData

                        property int col: modelData.col
                        property int row: Math.floor(index / 7)

                        // Hide rows not used this month so we can shrink the grid height.
                        visible: row < root.rowsUsed

                        x: col * (root.cellSize + dateGrid.xStride)
                        y: row * (root.cellSize + root.rowGap)
                        width: root.cellSize
                        height: root.cellSize

                        Canvas {
                            anchors.fill: parent
                            visible: dayCell.modelData.isToday
                            smooth: true
                            antialiasing: true
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);

                                ctx.fillStyle = root.colorToRgbaString(root.accentColor, root.materialOpacity);
                                ctx.beginPath();
                                ctx.arc(width * 0.5, height * 0.5, Math.min(width, height) * 0.5, 0, Math.PI * 2);
                                ctx.fill();

                                ctx.globalCompositeOperation = "destination-out";
                                ctx.fillStyle = "rgba(0,0,0,1)";
                                ctx.textAlign = "center";
                                ctx.textBaseline = "middle";
                                ctx.font = "800 10px 'SF Pro Text'";
                                ctx.fillText(String(dayCell.modelData.day), width * 0.5, height * 0.5 + 0.5);
                            }
                            onWidthChanged: requestPaint()
                            onHeightChanged: requestPaint()
                            onVisibleChanged: requestPaint()
                            Component.onCompleted: requestPaint()
                        }

                        Text {
                            anchors.centerIn: parent
                            text: dayCell.modelData.inMonth ? String(dayCell.modelData.day) : ""
                            visible: dayCell.modelData.inMonth && !dayCell.modelData.isToday
                            color: (dayCell.col === 0 || dayCell.col === 6) ? root.weekendColor : root.dateColor
                            font.family: "SF Pro Text"
                            font.weight: Font.ExtraBold
                            font.pixelSize: 10
                            opacity: root.materialOpacity
                            renderType: Text.NativeRendering
                        }
                    }
                }
            }
        }
    }

    Text {
        visible: root.showLabel
        anchors.top: root.bottom
        anchors.topMargin: 9
        anchors.horizontalCenter: root.horizontalCenter
        text: "Calendar"
        color: Qt.rgba(1, 1, 1, 0.92)
        font.family: "SF Pro Text"
        font.weight: Font.DemiBold
        font.pixelSize: 12
        style: Text.Raised
        styleColor: Qt.rgba(0, 0, 0, 0.7)
        renderType: Text.NativeRendering
    }
}
