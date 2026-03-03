.pragma library

function _toInt(value, fallback) {
    var number = Number(value);
    if (!isFinite(number)) {
        return fallback;
    }

    return Math.floor(number);
}

function _pixelSpan(span, unit, gap) {
    if (span <= 0) {
        return 0;
    }

    return (span * unit) + ((span - 1) * gap);
}

function _cellKey(row, col) {
    return row + "," + col;
}

function _fits(occupancy, row, col, width, height, columns) {
    if (col < 0 || row < 0 || width <= 0 || height <= 0) {
        return false;
    }

    if (col + width > columns) {
        return false;
    }

    for (var rowOffset = 0; rowOffset < height; rowOffset++) {
        for (var colOffset = 0; colOffset < width; colOffset++) {
            if (occupancy[_cellKey(row + rowOffset, col + colOffset)]) {
                return false;
            }
        }
    }

    return true;
}

function _occupy(occupancy, row, col, width, height) {
    for (var rowOffset = 0; rowOffset < height; rowOffset++) {
        for (var colOffset = 0; colOffset < width; colOffset++) {
            occupancy[_cellKey(row + rowOffset, col + colOffset)] = true;
        }
    }
}

function pack(tiles, columns, unit, gap) {
    var safeColumns = Math.max(1, _toInt(columns, 11));
    var safeUnit = Math.max(1, _toInt(unit, 64));
    var safeGap = Math.max(0, _toInt(gap, 12));
    var widthPx = _pixelSpan(safeColumns, safeUnit, safeGap);

    if (!Array.isArray(tiles) || tiles.length === 0) {
        return {
            placements: [],
            rowsUsed: 0,
            widthPx: widthPx,
            heightPx: 0
        };
    }

    var normalizedTiles = [];
    for (var i = 0; i < tiles.length; i++) {
        var tile = tiles[i] || {};
        var tileWidth = _toInt(tile.w, 0);
        var tileHeight = _toInt(tile.h, 0);

        if (tileWidth < 1 || tileHeight < 1 || tileWidth > safeColumns) {
            console.warn("[controlcenter] Skipping invalid tile descriptor:", tile.id || ("tile-" + i));
            continue;
        }

        normalizedTiles.push({
            id: tile.id || ("tile-" + i),
            kind: tile.kind || "",
            order: _toInt(tile.order, i),
            width: tileWidth,
            height: tileHeight,
            sourceIndex: i
        });
    }

    normalizedTiles.sort(function (left, right) {
        if (left.order !== right.order) {
            return left.order - right.order;
        }
        return left.sourceIndex - right.sourceIndex;
    });

    var occupancy = {};
    var placements = [];
    var maxOccupiedRow = -1;

    for (var tileIndex = 0; tileIndex < normalizedTiles.length; tileIndex++) {
        var current = normalizedTiles[tileIndex];
        var row = 0;
        var placed = false;

        while (!placed) {
            for (var col = 0; col <= safeColumns - current.width; col++) {
                if (!_fits(occupancy, row, col, current.width, current.height, safeColumns)) {
                    continue;
                }

                _occupy(occupancy, row, col, current.width, current.height);

                placements.push({
                    id: current.id,
                    kind: current.kind,
                    row: row,
                    col: col,
                    w: current.width,
                    h: current.height,
                    x: col * (safeUnit + safeGap),
                    y: row * (safeUnit + safeGap),
                    width: _pixelSpan(current.width, safeUnit, safeGap),
                    height: _pixelSpan(current.height, safeUnit, safeGap)
                });

                maxOccupiedRow = Math.max(maxOccupiedRow, row + current.height - 1);
                placed = true;
                break;
            }

            if (!placed) {
                row++;
            }
        }
    }

    var rowsUsed = maxOccupiedRow >= 0 ? maxOccupiedRow + 1 : 0;

    return {
        placements: placements,
        rowsUsed: rowsUsed,
        widthPx: widthPx,
        heightPx: rowsUsed > 0 ? _pixelSpan(rowsUsed, safeUnit, safeGap) : 0
    };
}
