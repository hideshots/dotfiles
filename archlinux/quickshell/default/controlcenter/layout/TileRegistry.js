.pragma library

var _entries = {
    toggle: {
        componentName: "ToggleTile",
        supportedSpans: ["1x1", "2x1", "2x2"],
        defaultSpan: "2x2"
    },
    action: {
        componentName: "ActionTile",
        supportedSpans: ["1x1"],
        defaultSpan: "1x1"
    },
    slider: {
        componentName: "SliderTile",
        supportedSpans: ["2x1", "4x1"],
        defaultSpan: "4x1"
    },
    nowPlaying: {
        componentName: "NowPlayingTile",
        supportedSpans: ["2x1", "2x2"],
        defaultSpan: "2x2"
    }
};

var _warnedUnsupportedKinds = {};
var _warnedSpanClamps = {};

function _toInt(value, fallback) {
    var number = Number(value);
    if (!isFinite(number)) {
        return fallback;
    }

    return Math.floor(number);
}

function _spanParts(span) {
    var text = span === undefined || span === null ? "" : String(span).trim();
    var match = text.match(/^(\d+)x(\d+)$/);
    if (!match) {
        return null;
    }

    var width = _toInt(match[1], 0);
    var height = _toInt(match[2], 0);
    if (width < 1 || height < 1) {
        return null;
    }

    return {
        w: width,
        h: height,
        key: width + "x" + height
    };
}

function _distance(left, right) {
    return Math.abs(left.w - right.w) + Math.abs(left.h - right.h);
}

function _resolveSupportedSpan(entry, requestedKey) {
    var supported = entry && entry.supportedSpans ? entry.supportedSpans : [];
    if (supported.length === 0) {
        return _spanParts("1x1");
    }

    for (var i = 0; i < supported.length; i++) {
        if (supported[i] === requestedKey) {
            return _spanParts(requestedKey);
        }
    }

    var requested = _spanParts(requestedKey);
    if (!requested) {
        return _spanParts(entry.defaultSpan || supported[0]);
    }

    var best = _spanParts(supported[0]);
    if (!best) {
        return _spanParts("1x1");
    }

    var bestDistance = _distance(requested, best);
    var requestedArea = requested.w * requested.h;

    for (var index = 1; index < supported.length; index++) {
        var candidate = _spanParts(supported[index]);
        if (!candidate) {
            continue;
        }

        var candidateDistance = _distance(requested, candidate);
        if (candidateDistance < bestDistance) {
            best = candidate;
            bestDistance = candidateDistance;
            continue;
        }

        if (candidateDistance === bestDistance) {
            var bestAreaDelta = Math.abs((best.w * best.h) - requestedArea);
            var candidateAreaDelta = Math.abs((candidate.w * candidate.h) - requestedArea);
            if (candidateAreaDelta < bestAreaDelta) {
                best = candidate;
                bestDistance = candidateDistance;
            }
        }
    }

    return best;
}

function entryForKind(kind) {
    if (!kind || !_entries[kind]) {
        return null;
    }

    return _entries[kind];
}

function spanKey(width, height) {
    var safeWidth = Math.max(1, _toInt(width, 1));
    var safeHeight = Math.max(1, _toInt(height, 1));
    return safeWidth + "x" + safeHeight;
}

function componentForKind(kind) {
    var entry = entryForKind(kind);
    if (!entry) {
        if (!_warnedUnsupportedKinds[kind]) {
            _warnedUnsupportedKinds[kind] = true;
            console.warn("[controlcenter] Unsupported tile kind '" + kind + "'");
        }
        return "";
    }

    return entry.componentName;
}

function resolveSpan(kind, requestedSpan) {
    var entry = entryForKind(kind);
    if (!entry) {
        if (!_warnedUnsupportedKinds[kind]) {
            _warnedUnsupportedKinds[kind] = true;
            console.warn("[controlcenter] Unsupported tile kind '" + kind + "'");
        }

        var fallback = _spanParts("1x1");
        return {
            kind: kind,
            componentName: "",
            requestedSpan: requestedSpan,
            requestedKey: String(requestedSpan),
            key: fallback.key,
            w: fallback.w,
            h: fallback.h,
            clamped: true,
            warning: false
        };
    }

    var fallbackKey = entry.defaultSpan || "1x1";
    var requestText = requestedSpan === undefined || requestedSpan === null ? fallbackKey : String(requestedSpan);
    var resolved = _resolveSupportedSpan(entry, requestText);
    var clamped = resolved.key !== requestText;
    var warning = false;

    if (clamped) {
        var warningKey = kind + "|" + requestText + "->" + resolved.key;
        if (!_warnedSpanClamps[warningKey]) {
            _warnedSpanClamps[warningKey] = true;
            warning = true;
            console.warn("[controlcenter] Clamped span for '" + kind + "' from '" + requestText + "' to '" + resolved.key + "'");
        }
    }

    return {
        kind: kind,
        componentName: entry.componentName,
        requestedSpan: requestText,
        requestedKey: requestText,
        key: resolved.key,
        w: resolved.w,
        h: resolved.h,
        clamped: clamped,
        warning: warning
    };
}
