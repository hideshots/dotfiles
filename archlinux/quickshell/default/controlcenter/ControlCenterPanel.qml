pragma ComponentBehavior: Bound

import QtQuick

import ".." as Root
import "layout/GridPacker.js" as GridPacker
import "layout/TileRegistry.js" as TileRegistry
import "providers" as Providers
import "tiles" as Tiles

Item {
    id: root

    readonly property bool wifiChecked: networkProvider.enabled
    readonly property bool wifiConnected: networkProvider.connected
    readonly property string wifiConnectedName: networkProvider.ssid
    readonly property bool bluetoothChecked: bluetoothProvider.enabled
    readonly property bool reduceTransparencyChecked: hyprAccessibilityProvider.reduceTransparencyEnabled
    readonly property bool focusChecked: Root.NotificationService.focusModeEnabled
    readonly property bool nightShiftChecked: nightShiftProvider.enabled
    readonly property bool reduceMotionChecked: hyprAccessibilityProvider.reduceMotionEnabled
    readonly property real nightShiftValue: nightShiftProvider.normalizedValue
    property real displayValue: 0.68
    property real volumeValue: 0.0

    property int gridUnit: 64
    property int gridGap: 12
    property int gridColumns: 4
    property int privacyRowHeight: 28
    property int privacyRowGap: 10
    property int footerButtonHeight: 28
    property int footerButtonGap: 10

    readonly property var privacyState: Root.PrivacyIndicatorService.state
    readonly property bool anyPrivacyActive: Root.PrivacyIndicatorService.anyActive
    readonly property var privacyIconDescriptors: _privacyIconDescriptors()
    readonly property string privacyPrimaryApp: _privacyPrimaryApp()
    readonly property string privacyAppLabelText: root.privacyPrimaryApp.length > 0 ? root.privacyPrimaryApp : "Unknown App"

    readonly property var tileDescriptors: root.buildTileDescriptors()

    readonly property var resolvedTileDescriptors: root.resolveTileDescriptors(root.tileDescriptors)
    readonly property var packedLayout: GridPacker.pack(root.resolvedTileDescriptors, root.gridColumns, root.gridUnit, root.gridGap)
    readonly property var placements: packedLayout.placements ? packedLayout.placements : []
    readonly property int panelPixelWidth: packedLayout.widthPx ? packedLayout.widthPx : 0
    readonly property int panelPixelHeight: packedLayout.heightPx ? packedLayout.heightPx : 0
    readonly property int contentTopInset: root.anyPrivacyActive ? (root.privacyRowHeight + root.privacyRowGap) : 0
    readonly property int footerInset: root.footerButtonGap + root.footerButtonHeight

    implicitWidth: root.panelPixelWidth
    implicitHeight: root.panelPixelHeight + root.contentTopInset + root.footerInset
    width: implicitWidth
    height: implicitHeight

    function _privacyPrimaryApp() {
        var apps = root.privacyState.activeApps;
        if (!Array.isArray(apps) || apps.length === 0) {
            return "";
        }

        var first = apps[0];
        if (first === undefined || first === null) {
            return "";
        }

        return String(first).trim();
    }

    function buildTileDescriptors() {
        var descriptors = [
            {
                id: "wireless",
                kind: "toggle",
                w: 2,
                h: 1,
                order: 10,
                data: {
                    symbol: "􀙈",
                    title: "Wi-Fi",
                    detailOn: "On",
                    detailOff: "Off",
                    detail: root.wifiChecked
                        ? (root.wifiConnected && root.wifiConnectedName.length > 0 ? root.wifiConnectedName : "On")
                        : "Off",
                    checked: root.wifiChecked
                }
            },
            {
                id: "nowPlaying",
                kind: "nowPlaying",
                w: 2,
                h: 2,
                order: 20,
                data: {
                    provider: nowPlayingProvider
                }
            },
            {
                id: "bluetooth",
                kind: "toggle",
                w: 1,
                h: 1,
                order: 30,
                data: {
                    symbolOn: "􀖀",
                    symbolOff: "􁅒",
                    title: "Bluetooth",
                    detailOn: "On",
                    detailOff: "Off",
                    checked: root.bluetoothChecked
                }
            },
            {
                id: "transparency",
                kind: "toggle",
                w: 1,
                h: 1,
                order: 30,
                data: {
                    symbol: "􀯇",
                    title: "Reduce Transparency",
                    detailOn: "On",
                    detailOff: "Off",
                    detail: root.reduceTransparencyChecked ? "On" : "Off",
                    checked: root.reduceTransparencyChecked
                }
            },
            {
                id: "focus",
                kind: "toggle",
                w: 2,
                h: 1,
                order: 40,
                data: {
                    symbol: "􀆺",
                    title: "Focus",
                    detailOn: "On",
                    detailOff: "Off",
                    checked: root.focusChecked
                }
            },
            {
                id: "nightshifttoggle",
                kind: "toggle",
                w: 1,
                h: 1,
                order: 50,
                data: {
                    symbol: "􂱣",
                    title: "Night Shift",
                    detailOn: "On",
                    detailOff: "Off",
                    checked: root.nightShiftChecked
                }
            },
            {
                id: "motion",
                kind: "toggle",
                w: 1,
                h: 1,
                order: 60,
                data: {
                    symbol: "􁊕",
                    title: "Reduce Motion",
                    detailOn: "On",
                    detailOff: "Off",
                    detail: root.reduceMotionChecked ? "On" : "Off",
                    checked: root.reduceMotionChecked
                }
            },
            {
                id: "display",
                kind: "slider",
                w: 4,
                h: 1,
                order: 80,
                data: {
                    title: "Display",
                    minusSymbol: "􀆬",
                    plusSymbol: "􀆮",
                    value: root.displayValue
                }
            },
            {
                id: "volume",
                kind: "slider",
                w: 4,
                h: 1,
                order: 90,
                data: {
                    title: "Volume",
                    minusSymbol: "􀊡",
                    plusSymbol: "􀊩",
                    value: root.volumeValue
                }
            },
        ];

        if (root.nightShiftChecked) {
            descriptors.push({
                id: "nightshift",
                kind: "slider",
                w: 4,
                h: 1,
                order: 70,
                data: {
                    title: "Night Shift",
                    minusSymbol: "􀛮",
                    plusSymbol: "􁷙",
                    value: root.nightShiftValue
                }
            });
        }

        return descriptors;
    }

    function _privacyIconDescriptors() {
        var descriptors = [];

        if (root.privacyState.micActive) {
            descriptors.push({
                glyph: "􀊱",
                color: Root.Theme.privacyMicrophoneIndicator
            });
        }
        if (root.privacyState.systemAudioRecordingActive || root.privacyState.screenShareActive) {
            descriptors.push({
                glyph: "􁅀",
                color: Root.Theme.privacySystemAudioIndicator
            });
        }
        if (root.privacyState.cameraActive) {
            descriptors.push({
                glyph: "􀌟",
                color: Root.Theme.privacyCameraIndicator
            });
        }
        if (root.privacyState.locationActive) {
            descriptors.push({
                glyph: Root.Theme.privacyIndicatorArrowGlyph,
                color: Root.Theme.privacyLocationIndicator
            });
        }

        return descriptors;
    }

    function descriptorForId(tileId) {
        for (var i = 0; i < root.resolvedTileDescriptors.length; i++) {
            var descriptor = root.resolvedTileDescriptors[i];
            if (descriptor && descriptor.id === tileId) {
                return descriptor;
            }
        }

        return null;
    }

    function sizeModeForPlacement(placement) {
        if (!placement) {
            return "1x1";
        }

        return TileRegistry.spanKey(placement.w, placement.h);
    }

    function resolveTileDescriptors(descriptors) {
        if (!Array.isArray(descriptors) || descriptors.length === 0) {
            return [];
        }

        var resolved = [];
        for (var i = 0; i < descriptors.length; i++) {
            var descriptor = descriptors[i];
            if (!descriptor) {
                continue;
            }

            var requestedSpan = TileRegistry.spanKey(descriptor.w, descriptor.h);
            var span = TileRegistry.resolveSpan(descriptor.kind, requestedSpan);

            resolved.push({
                id: descriptor.id,
                kind: descriptor.kind,
                w: span.w,
                h: span.h,
                order: descriptor.order,
                data: descriptor.data
            });
        }

        return resolved;
    }

    function tileDataForPlacement(placement) {
        if (!placement) {
            return ({});
        }

        var descriptor = root.descriptorForId(placement.id);
        if (!descriptor || descriptor.data === undefined || descriptor.data === null) {
            return ({});
        }

        return descriptor.data;
    }

    function componentForName(name) {
        if (name === "ToggleTile") {
            return toggleTileComponent;
        }

        if (name === "ActionTile") {
            return actionTileComponent;
        }

        if (name === "SliderTile") {
            return sliderTileComponent;
        }

        if (name === "NowPlayingTile") {
            return nowPlayingTileComponent;
        }

        return unknownTileComponent;
    }

    function sourceComponentForKind(kind) {
        return root.componentForName(TileRegistry.componentForKind(kind));
    }

    function handleToggleForTile(tileId, nextChecked) {
        if (tileId === "wireless") {
            networkProvider.setEnabled(!!nextChecked);
            return;
        }

        if (tileId === "bluetooth") {
            bluetoothProvider.setEnabled(!!nextChecked);
            return;
        }

        if (tileId === "transparency") {
            hyprAccessibilityProvider.setReduceTransparencyEnabled(!!nextChecked);
            return;
        }

        if (tileId === "focus") {
            Root.NotificationService.setFocusModeEnabled(!!nextChecked);
            return;
        }

        if (tileId === "nightshifttoggle") {
            nightShiftProvider.setEnabled(!!nextChecked);
            return;
        }

        if (tileId === "motion") {
            hyprAccessibilityProvider.setReduceMotionEnabled(!!nextChecked);
        }
    }

    function handleValueChangedForTile(tileId, nextValue) {
        var clamped = Math.max(0, Math.min(1, Number(nextValue)));
        if (!isFinite(clamped)) {
            return;
        }

        if (tileId === "display") {
            root.displayValue = clamped;
            return;
        }

        if (tileId === "nightshift") {
            nightShiftProvider.setNormalizedValue(clamped);
            return;
        }

        if (tileId === "volume") {
            root.volumeValue = clamped;
            volumeProvider.setVolume(clamped);
        }
    }

    Providers.NowPlayingProvider {
        id: nowPlayingProvider
    }

    Providers.NetworkProvider {
        id: networkProvider
    }

    Providers.BluetoothProvider {
        id: bluetoothProvider
    }

    Providers.HyprAccessibilityProvider {
        id: hyprAccessibilityProvider
    }

    Providers.NightShiftProvider {
        id: nightShiftProvider
    }

    Providers.VolumeProvider {
        id: volumeProvider
        onValueChanged: {
            if (Math.abs(value - root.volumeValue) < 0.0001) {
                return;
            }
            root.volumeValue = value;
        }
    }

    Component {
        id: toggleTileComponent

        Tiles.ToggleTile {
        }
    }

    Component {
        id: actionTileComponent

        Tiles.ActionTile {
        }
    }

    Component {
        id: sliderTileComponent

        Tiles.SliderTile {
        }
    }

    Component {
        id: nowPlayingTileComponent

        Tiles.NowPlayingTile {
        }
    }

    Component {
        id: unknownTileComponent

        Item {
            property string sizeMode: "1x1"
            property var tileData: ({})
        }
    }

    Tiles.TileSurface {
        id: privacyRow
        visible: root.anyPrivacyActive
        width: Math.min(root.panelPixelWidth, privacyContent.implicitWidth + 20)
        height: root.privacyRowHeight
        anchors.horizontalCenter: parent.horizontalCenter
        radius: Math.round(height / 2)
        tintColor: Qt.rgba(0, 0, 0, 0.20)
        contrastColor: Qt.rgba(1, 1, 1, 0.0)
        borderColor: Qt.rgba(1, 1, 1, 0.0)

        Row {
            id: privacyContent
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Row {
                id: privacyIconsRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Repeater {
                    model: root.privacyIconDescriptors

                    Rectangle {
                        id: privacyIconChip
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: 15
                        height: 15
                        radius: 7.5
                        color: modelData.color

                        Root.SymbolIcon {
                            anchors.centerIn: parent
                            width: 8
                            height: 8
                            glyph: privacyIconChip.modelData.glyph
                            fallbackColor: "#ffffff"
                            fallbackFontFamily: Root.Theme.fontFamilySymbol
                            pixelSize: 8
                            fontWeight: Font.Medium
                        }
                    }
                }
            }

            Text {
                id: privacyAppLabel
                anchors.verticalCenter: parent.verticalCenter
                readonly property real maxWidth: Math.max(0, root.panelPixelWidth - privacyIconsRow.implicitWidth - 32)
                width: Math.min(implicitWidth, maxWidth)
                text: root.privacyAppLabelText
                color: Qt.rgba(1, 1, 1, 0.88)
                font.family: Root.Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                elide: Text.ElideRight
                renderType: Text.NativeRendering
            }
        }
    }

    Item {
        id: gridLayer
        y: root.contentTopInset
        width: root.panelPixelWidth
        height: root.panelPixelHeight

        Repeater {
            model: root.placements

            Loader {
                id: tileLoader
                required property var modelData
                readonly property var placement: modelData
                readonly property string placementSizeMode: root.sizeModeForPlacement(placement)
                readonly property var descriptorData: root.tileDataForPlacement(placement)

                x: placement.x
                y: placement.y
                width: placement.width
                height: placement.height
                sourceComponent: root.sourceComponentForKind(placement.kind)

                function syncLoadedItem() {
                    if (!item) {
                        return;
                    }

                    item.width = width;
                    item.height = height;
                    item.sizeMode = placementSizeMode;
                    item.tileData = descriptorData;
                }

                onLoaded: syncLoadedItem()
                onWidthChanged: syncLoadedItem()
                onHeightChanged: syncLoadedItem()
                onPlacementSizeModeChanged: syncLoadedItem()
                onDescriptorDataChanged: syncLoadedItem()

                Connections {
                    target: tileLoader.item
                    ignoreUnknownSignals: true

                    function onToggled(nextChecked) {
                        root.handleToggleForTile(tileLoader.placement.id, nextChecked);
                    }

                    function onValueChangedByUser(nextValue) {
                        root.handleValueChangedForTile(tileLoader.placement.id, nextValue);
                    }
                }
            }
        }
    }

    Tiles.TileSurface {
        id: editControlsButton
        width: Math.min(root.panelPixelWidth, editControlsContent.implicitWidth + 20)
        height: root.footerButtonHeight
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.contentTopInset + root.panelPixelHeight + root.footerButtonGap
        radius: Math.round(height / 2)
        tintColor: Qt.rgba(0, 0, 0, 0.20)
        contrastColor: Qt.rgba(1, 1, 1, 0.0)
        borderColor: Qt.rgba(1, 1, 1, 0.0)

        Row {
            id: editControlsContent
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "Edit Controls"
                color: Qt.rgba(1, 1, 1, 0.88)
                font.family: Root.Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.Medium
                elide: Text.ElideNone
                renderType: Text.NativeRendering
            }
        }
    }
}
