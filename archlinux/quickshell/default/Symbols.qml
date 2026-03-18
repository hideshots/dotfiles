pragma Singleton
import QtQuick

QtObject {
    id: root

    property bool svgEnabled: true
    readonly property string svgDir: "assets/svg"

    readonly property var glyphMap: ({
            // Theme / privacy
            "􀋒": { sfName: "", usage: "privacy location arrow", textOnly: true },
            "􀅾": { sfName: "", usage: "clear / dismiss buttons", textOnly: true },
            "􀆅": { sfName: "", usage: "menu checkmark", textOnly: true },
            "􀆊": { sfName: "", usage: "menu submenu chevron", textOnly: true },
            "􀆔": { sfName: "", usage: "menu shortcut command modifier (text-only by convention)", textOnly: true },
            "􀆕": { sfName: "", usage: "menu shortcut shift modifier (text-only by convention)", textOnly: true },
            "􀆝": { sfName: "", usage: "menu shortcut option modifier (text-only by convention)", textOnly: true },
            "􀆨": { sfName: "", usage: "menu restart", textOnly: true },
            "􀆿": { sfName: "sparkles", usage: "menubar apple logo" },
            "􀈎": { sfName: "", usage: "menu system settings", textOnly: true },
            "􀉩": { sfName: "", usage: "menu log out", textOnly: true },
            "􀊫": { sfName: "", usage: "unused commented menubar icon" },
            "􀎥": { sfName: "", usage: "menu sleep", textOnly: true },
            "􀙗": { sfName: "", usage: "menu about this mac", textOnly: true },
            "􀙧": { sfName: "", usage: "menu lock screen", textOnly: true },
            "􀜊": { sfName: "switch.2", usage: "menubar control center" },
            "􀜗": { sfName: "", usage: "menu force quit", textOnly: true },
            "􀷃": { sfName: "", usage: "menu shut down", textOnly: true },
            "􁣡": { sfName: "", usage: "menu app store", textOnly: true },

            // Control center
            "􀖀": { sfName: "bluetooth", usage: "bluetooth on" },
            "􀆬": { sfName: "sun.min.fill", usage: "slider minus / weather clear-day currently shares glyph" },
            "􀆮": { sfName: "sun.max.fill", usage: "slider plus / weather clear-day currently shares glyph" },
            "􀆺": { sfName: "moon.fill", usage: "focus / weather clear-night currently shares glyph" },
            "􀙈": { sfName: "wifi.slash", usage: "wireless off" },
            "􀙇": { sfName: "wifi", usage: "wireless on" },
            "􀙥": { sfName: "wifi.exclamationmark", usage: "wireless on but disconnected" },
            "􀛮": { sfName: "lightbulb.fill", usage: "nightshift min", scale: 1.0  },
            "􁷙": { sfName: "lightbulb.max.fill", usage: "nightshift max", scale: 1.4  },
            "􀯇": { sfName: "square.on.square.intersection.dashed", usage: "reduce transparency" },
            // "􀊄": { sfName: "play.fill", usage: "now playing play" },
            // "􀊆": { sfName: "pause.fill", usage: "now playing pause" },
            // "􀊊": { sfName: "backward.end.fill", usage: "now playing previous" },
            // "􀊌": { sfName: "forward.end.fill", usage: "now playing next" },
            "􀊡": { sfName: "speaker.fill", usage: "volume slider minus", scale: 0.7 },
            "􀊣": { sfName: "speaker.slash.fill", usage: "audio muted / unavailable" },
            "􀊩": { sfName: "speaker.wave.3.fill", usage: "volume slider plus", scale: 1.0 },
            "􀊱": { sfName: "", usage: "privacy mic active", textOnly: true },
            "􀌟": { sfName: "", usage: "privacy camera active", textOnly: true },
            "􁅀": { sfName: "", usage: "privacy system audio / screen share", textOnly: true },
            "􁅒": { sfName: "", usage: "bluetooth off", textOnly: true },
            "􁊕": { sfName: "circle.dotted.and.circle", usage: "reduce motion" },
            "􂱣": { sfName: "sun.righthalf.filled", usage: "night shift toggle" },
            "􀢋": { sfName: "battery.100percent.bolt", usage: "battery charging / adapter", scale: 1.8  },
            "􀛨": { sfName: "battery.100percent", usage: "battery full", scale: 1.8  },
            "􀺸": { sfName: "battery.75percent", usage: "battery 75 percent", scale: 1.8 },
            "􀺶": { sfName: "battery.50percent", usage: "battery 51 percent", scale: 1.8  },
            "􀛩": { sfName: "battery.25percent", usage: "battery 25 percent", scale: 1.8  },
            "􀛪": { sfName: "battery.0percent", usage: "battery empty", scale: 1.8  },

            // Weather
            "􀆲": { sfName: "sunrise.fill", usage: "weather sunrise event" },
            "􀆴": { sfName: "sunset.fill", usage: "weather sunset event", scale: 1.2 },
            "􀆶": { sfName: "sun.dust.fill", usage: "weather dust_day" },
            "􀆸": { sfName: "sun.haze.fill", usage: "weather haze_day" },
            "􀇃": { sfName: "cloud.fill", usage: "weather cloudy all-day" },
            "􀇄": { sfName: "cloud.drizzle.fill", usage: "weather drizzle" },
            "􀇅": { sfName: "cloud.sun.rain.fill", usage: "weather light_rain_day" },
            "􀇉": { sfName: "cloud.heavyrain.fill", usage: "weather heavy_rain/squall" },
            "􀇋": { sfName: "cloud.fog.fill", usage: "weather mist/fog" },
            "􀇏": { sfName: "cloud.snow.fill", usage: "weather snow" },
            "􀇕": { sfName: "cloud.sun.fill", usage: "weather cloudy_day (legacy)" },
            "􀇛": { sfName: "cloud.moon.fill", usage: "weather cloudy_night (legacy)" },
            "􀇝": { sfName: "cloud.moon.rain.fill", usage: "weather light_rain_night", scale: 1.3  },
            "􀇟": { sfName: "cloud.bolt.rain.fill", usage: "weather thunder/tornado" },
            "􀇣": { sfName: "smoke.fill", usage: "weather smoke" },
            "􀇤": { sfName: "sun.dust.fill", usage: "weather sand/ash" },
            "􁑰": { sfName: "moon.haze.fill", usage: "weather haze_night" },
            "􁶾": { sfName: "moon.dust.fill", usage: "weather dust_night" }
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

    function isTextFallbackGlyph(glyph) {
        var entry = _entryForGlyph(glyph);
        return !!(entry && entry.textOnly);
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
