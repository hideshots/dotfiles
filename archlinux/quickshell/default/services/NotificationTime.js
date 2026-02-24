.pragma library

function _safeNumber(value, fallbackValue) {
    var numeric = Number(value);
    if (!isFinite(numeric)) {
        return fallbackValue;
    }
    return numeric;
}

function _startOfDay(timestampMs) {
    var date = new Date(timestampMs);
    date.setHours(0, 0, 0, 0);
    return date.getTime();
}

function shortRelativeLabel(receivedAtMs, nowMs) {
    var now = _safeNumber(nowMs, Date.now());
    var receivedAt = _safeNumber(receivedAtMs, now);
    var diffMs = now - receivedAt;

    if (diffMs < 0) {
        diffMs = 0;
    }

    var seconds = Math.floor(diffMs / 1000);
    if (seconds < 45) {
        return "now";
    }

    if (seconds < 3600) {
        var minutes = Math.max(1, Math.floor(seconds / 60));
        return minutes + "m";
    }

    if (seconds < 86400) {
        var hours = Math.max(1, Math.floor(seconds / 3600));
        return hours + "h";
    }

    var todayStart = _startOfDay(now);
    if (receivedAt >= (todayStart - 86400000) && receivedAt < todayStart) {
        return "Yesterday";
    }

    var days = Math.max(1, Math.floor(seconds / 86400));
    return days + "d";
}
