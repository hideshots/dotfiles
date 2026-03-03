pragma ComponentBehavior: Bound

import QtQuick

import "layout/GridPacker.js" as GridPacker
import "layout/TileRegistry.js" as TileRegistry
import "providers" as Providers
import "tiles" as Tiles

Item {
    id: root

    property bool floorLampChecked: false
    property bool focusChecked: false
    property bool cameraChecked: false
    property real displayValue: 0.68
    property real volumeValue: 0.0

    property int gridUnit: 64
    property int gridGap: 12
    property int gridColumns: 4

    readonly property var tileDescriptors: [
        {
            id: "nowPlaying",
            kind: "nowPlaying",
            w: 2,
            h: 2,
            order: 10,
            data: {
                provider: nowPlayingProvider
            }
        },
        {
            id: "floorLamp",
            kind: "toggle",
            w: 1,
            h: 1,
            order: 20,
            data: {
                symbol: "􀛮",
                title: "Floor Lamp",
                detailOn: "On",
                detailOff: "Off",
                checked: root.floorLampChecked
            }
        },
        {
            id: "focus",
            kind: "toggle",
            w: 2,
            h: 1,
            order: 30,
            data: {
                symbol: "􀆺",
                title: "Do Not Disturb",
                compactTitleWrap: true,
                detailOn: "On",
                detailOff: "Off",
                checked: root.focusChecked
            }
        },
        {
            id: "camera",
            kind: "action",
            w: 1,
            h: 1,
            order: 40,
            data: {
                symbol: "􀌟",
                checked: root.cameraChecked
            }
        },
        {
            id: "display",
            kind: "slider",
            w: 4,
            h: 1,
            order: 50,
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
            order: 60,
            data: {
                title: "Volume",
                minusSymbol: "􀊡",
                plusSymbol: "􀊩",
                value: root.volumeValue
            }
        }
    ]

    readonly property var resolvedTileDescriptors: root.resolveTileDescriptors(root.tileDescriptors)
    readonly property var packedLayout: GridPacker.pack(root.resolvedTileDescriptors, root.gridColumns, root.gridUnit, root.gridGap)
    readonly property var placements: packedLayout.placements ? packedLayout.placements : []
    readonly property int panelPixelWidth: packedLayout.widthPx ? packedLayout.widthPx : 0
    readonly property int panelPixelHeight: packedLayout.heightPx ? packedLayout.heightPx : 0

    implicitWidth: root.panelPixelWidth
    implicitHeight: root.panelPixelHeight
    width: implicitWidth
    height: implicitHeight

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
        if (tileId === "floorLamp") {
            root.floorLampChecked = !!nextChecked;
            return;
        }

        if (tileId === "focus") {
            root.focusChecked = !!nextChecked;
            return;
        }

        if (tileId === "camera") {
            root.cameraChecked = !!nextChecked;
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

        if (tileId === "volume") {
            root.volumeValue = clamped;
            volumeProvider.setVolume(clamped);
        }
    }

    Providers.NowPlayingProvider {
        id: nowPlayingProvider
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
