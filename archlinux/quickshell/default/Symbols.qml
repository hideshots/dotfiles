pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool svgEnabled: true
    readonly property string svgDir: "assets/svg"

    readonly property var glyphMap: ({
            // Theme / privacy
            "􀋒": { sfName: "", usage: "privacy location arrow" },
            "􀅾": { sfName: "", usage: "clear / dismiss buttons" },
            "􀆅": { sfName: "", usage: "menu checkmark" },
            "􀆊": { sfName: "", usage: "menu submenu chevron" },
            "􀆔": { sfName: "", usage: "menu shortcut command modifier (text-only by convention)" },
            "􀆕": { sfName: "", usage: "menu shortcut shift modifier (text-only by convention)" },
            "􀆝": { sfName: "", usage: "menu shortcut option modifier (text-only by convention)" },
            "􀆨": { sfName: "", usage: "menu restart" },
            "􀆿": { sfName: "sparkles", usage: "menubar apple logo" },
            "􀈎": { sfName: "", usage: "menu system settings" },
            "􀉩": { sfName: "", usage: "menu log out" },
            "􀊫": { sfName: "", usage: "unused commented menubar icon" },
            "􀎥": { sfName: "", usage: "menu sleep" },
            "􀙗": { sfName: "", usage: "menu about this mac" },
            "􀙧": { sfName: "", usage: "menu lock screen" },
            "􀜊": { sfName: "switch.2", usage: "menubar control center" },
            "􀜗": { sfName: "", usage: "menu force quit" },
            "􀷃": { sfName: "", usage: "menu shut down" },
            "􁣡": { sfName: "", usage: "menu app store" },

            // Control center
            "􀖀": { sfName: "bluetooth", usage: "bluetooth on" },
            "􀆬": { sfName: "sun.min.fill", usage: "slider minus / weather clear-day currently shares glyph" },
            "􀆮": { sfName: "sun.max.fill", usage: "slider plus / weather clear-day currently shares glyph" },
            "􀆺": { sfName: "moon.fill", usage: "focus / weather clear-night currently shares glyph" },
            "􀙈": { sfName: "wifi.slash", usage: "wireless off" },
            "􀙇": { sfName: "wifi", usage: "wireless on" },
            "􀯇": { sfName: "square.on.square.intersection.dashed", usage: "reduce transparency" },
            "􀊄": { sfName: "play", usage: "now playing play" },
            "􀊆": { sfName: "pause", usage: "now playing pause" },
            "􀊊": { sfName: "backward", usage: "now playing previous" },
            "􀊌": { sfName: "forward", usage: "now playing next" },
            "􀊡": { sfName: "speaker.fill", usage: "volume slider minus", scale: 0.7 },
            "􀊩": { sfName: "speaker.wave.3.fill", usage: "volume slider plus", scale: 1.0 },
            "􀊱": { sfName: "", usage: "privacy mic active" },
            "􁅀": { sfName: "", usage: "privacy system audio / screen share" },
            "􁅒": { sfName: "", usage: "bluetooth off" },
            "􁊕": { sfName: "circle.dotted.and.circle", usage: "reduce motion" },
            "􂱣": { sfName: "sun.righthalf.filled", usage: "night shift toggle" },

            // Weather
            "􀆶": { sfName: "", usage: "weather dust_day" },
            "􀆸": { sfName: "", usage: "weather haze_day" },
            "􀇄": { sfName: "", usage: "weather drizzle" },
            "􀇅": { sfName: "", usage: "weather light_rain_day" },
            "􀇉": { sfName: "", usage: "weather heavy_rain/squall" },
            "􀇋": { sfName: "", usage: "weather mist/fog" },
            "􀇏": { sfName: "", usage: "weather snow" },
            "􀇕": { sfName: "", usage: "weather cloudy_day" },
            "􀇛": { sfName: "", usage: "weather cloudy_night" },
            "􀇝": { sfName: "", usage: "weather light_rain_night" },
            "􀇟": { sfName: "", usage: "weather thunder/tornado" },
            "􀇣": { sfName: "", usage: "weather smoke" },
            "􀇤": { sfName: "", usage: "weather sand/ash" },
            "􁑰": { sfName: "", usage: "weather haze_night" },
            "􁶾": { sfName: "", usage: "weather dust_night" }
        })

    property var _warnedKeys: ({})

    function _safeString(value) {
        if (value === undefined || value === null) {
            return "";
        }

        return String(value);
    }

    function _safeNumber(value, fallbackValue) {
        var numeric = Number(value);
        if (!isFinite(numeric)) {
            return fallbackValue;
        }
        return numeric;
    }

    function _entryForGlyph(glyph) {
        var key = _safeString(glyph);
        if (key.length === 0) {
            return null;
        }

        if (!root.glyphMap || root.glyphMap[key] === undefined) {
            return null;
        }

        return root.glyphMap[key];
    }

    function sfNameForGlyph(glyph) {
        var entry = _entryForGlyph(glyph);
        if (!entry) {
            return "";
        }

        return _safeString(entry.sfName).trim();
    }

    function hasGlyphEntry(glyph) {
        return _entryForGlyph(glyph) !== null;
    }

    function svgUrlForGlyph(glyph) {
        var sfName = sfNameForGlyph(glyph);
        if (sfName.length === 0) {
            return "";
        }

        return Qt.resolvedUrl(root.svgDir + "/" + sfName + ".svg");
    }

    function scaleForGlyph(glyph) {
        var entry = _entryForGlyph(glyph);
        if (!entry) {
            return 1.0;
        }

        return Math.max(0.1, _safeNumber(entry.scale, 1.0));
    }

    function warnMissingOnce(glyph, reason) {
        var key = _safeString(glyph);
        if (key.length === 0) {
            return;
        }

        var reasonText = _safeString(reason);
        var warnKey = key + "|" + reasonText;
        if (root._warnedKeys[warnKey]) {
            return;
        }

        root._warnedKeys[warnKey] = true;
        console.warn("[Symbols] SVG fallback glyph=\"" + key + "\" reason=\"" + reasonText + "\"");
    }
}
