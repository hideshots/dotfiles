import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property string location: ""
    property string units: "m" // "m" metric, "u" US
    property bool isLoading: false
    property string error: ""
    readonly property var symbolByKey: ({
        clear_day: "􀆮",
        clear_night: "􀆺",
        cloudy_day: "􀇃",
        cloudy_night: "􀇃",
        light_rain_day: "􀇅",
        light_rain_night: "􀇝",
        heavy_rain_day: "􀇉",
        heavy_rain_night: "􀇉",
        snow_day: "􀇏",
        snow_night: "􀇏",
        thunder_day: "􀇟",
        thunder_night: "􀇟",
        drizzle_day: "􀇄",
        drizzle_night: "􀇄",
        mist_day: "􀇋",
        mist_night: "􀇋",
        smoke_day: "􀇣",
        smoke_night: "􀇣",
        haze_day: "􀆸",
        haze_night: "􁑰",
        dust_day: "􀆶",
        dust_night: "􁶾",
        sand_day: "􀇤",
        sand_night: "􀇤",
        ash_day: "􀇤",
        ash_night: "􀇤",
        fog_day: "􀇋",
        fog_night: "􀇋",
        squall_day: "􀇉",
        squall_night: "􀇉",
        tornado_day: "􀇟",
        tornado_night: "􀇟"
    })
    readonly property string sunriseGlyph: "􀆲"
    readonly property string sunsetGlyph: "􀆴"
    property var data: ({
        city: "—",
        temp: "—",
        condition: "—",
        high: "—",
        low: "—",
        symbol: symbolByKey.cloudy_night,
        hourly: []
    })
    property double lastUpdated: 0

    readonly property string normalizedUnits: units === "u" ? "u" : "m"
    readonly property string requestedLocation: location.trim()
    readonly property string requestUrl: {
        const base = requestedLocation.length > 0
            ? "https://wttr.in/" + encodeURIComponent(requestedLocation)
            : "https://wttr.in";
        return base + "?format=j1&lang=en&" + normalizedUnits;
    }
    readonly property string cacheFilePath: Quickshell.cachePath("small-weather-last-good.json")
    readonly property bool offline: error.length > 0
    readonly property int requestTimeoutMs: 30 * 1000

    property var _lastGoodData: null
    property double _requestStartedAt: 0
    property bool _refreshQueued: false

    function refresh() {
        if (!isLoading && curlProcess.running) {
            _refreshQueued = true;
            curlProcess.signal(15);
            return;
        }

        if (isLoading) {
            const elapsed = _requestStartedAt > 0 ? (Date.now() - _requestStartedAt) : 0;
            if (!curlProcess.running || elapsed > requestTimeoutMs) {
                _resetStuckRequest("Previous weather request got stuck.");
                if (curlProcess.running) {
                    _refreshQueued = true;
                    return;
                }
            } else {
                return;
            }
        }

        _refreshQueued = false;
        isLoading = true;
        _requestStartedAt = Date.now();
        error = "";
        requestStartGuard.restart();
        requestTimeoutGuard.restart();

        curlProcess.exec([
            "curl",
            "--http1.1",
            "-fsSL",
            "--connect-timeout", "5",
            "--max-time", "10",
            "--retry", "2",
            "--retry-delay", "1",
            "-A", "Mozilla/5.0",
            requestUrl
        ]);
    }

    function _resetStuckRequest(nextError) {
        if (!isLoading) {
            return;
        }

        if (curlProcess.running) {
            curlProcess.signal(15);
        }

        isLoading = false;
        _requestStartedAt = 0;
        requestStartGuard.stop();
        requestTimeoutGuard.stop();
        _applyError(nextError);
    }

    function _safeValue(value) {
        if (value === undefined || value === null || value === "") {
            return "—";
        }

        return String(value);
    }

    function _safeGet(objectValue, path) {
        let cursor = objectValue;

        for (let i = 0; i < path.length; i++) {
            if (cursor === null || cursor === undefined) {
                return undefined;
            }
            cursor = cursor[path[i]];
        }

        return cursor;
    }

    function _placeholderData(cityHint) {
        const fallbackCity = cityHint && cityHint.length > 0
            ? cityHint
            : requestedLocation.length > 0
                ? requestedLocation
                : "—";

        return {
            city: fallbackCity,
            temp: "—",
            condition: "—",
            high: "—",
            low: "—",
            symbol: symbolByKey.cloudy_night,
            hourly: []
        };
    }

    function _isValidData(candidate) {
        return candidate
            && typeof candidate === "object"
            && candidate.city !== undefined
            && candidate.temp !== undefined
            && candidate.condition !== undefined
            && candidate.high !== undefined
            && candidate.low !== undefined;
    }

    function _parseHour(value) {
        if (value === undefined || value === null) {
            return -1;
        }

        const raw = String(value).trim();
        if (raw.length === 0) {
            return -1;
        }

        const match = raw.match(/(\d{1,2}):(\d{2})(?:\s*([AP]M))?/i);
        if (!match) {
            return -1;
        }

        let hour = parseInt(match[1], 10);
        const minute = parseInt(match[2], 10);
        if (isNaN(hour) || isNaN(minute) || minute < 0 || minute > 59) {
            return -1;
        }

        const suffix = match[3] ? match[3].toUpperCase() : "";
        if (suffix.length > 0) {
            if (hour < 1 || hour > 12) {
                return -1;
            }
            if (suffix === "AM" && hour === 12) {
                hour = 0;
            } else if (suffix === "PM" && hour !== 12) {
                hour += 12;
            }
        } else if (hour < 0 || hour > 23) {
            return -1;
        }

        return hour;
    }

    function _hourFromWttrTime(value) {
        if (value === undefined || value === null) {
            return -1;
        }

        const raw = String(value).trim();
        if (raw.length === 0) {
            return -1;
        }

        const numeric = parseInt(raw, 10);
        if (isNaN(numeric)) {
            return -1;
        }

        const hour = Math.floor(numeric / 100);
        if (hour < 0 || hour > 23) {
            return -1;
        }

        return hour;
    }

    function _minuteFromWttrTime(value) {
        if (value === undefined || value === null) {
            return -1;
        }

        const raw = String(value).trim();
        if (raw.length === 0) {
            return -1;
        }

        const numeric = parseInt(raw, 10);
        if (isNaN(numeric)) {
            return -1;
        }

        const hour = Math.floor(numeric / 100);
        const minute = numeric % 100;
        if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
            return -1;
        }

        return hour * 60 + minute;
    }

    function _minuteFromAmPm(value) {
        if (value === undefined || value === null) {
            return -1;
        }

        const raw = String(value).trim();
        if (raw.length === 0) {
            return -1;
        }

        const match = raw.match(/(\d{1,2}):(\d{2})\s*([AP]M)/i);
        if (!match) {
            return -1;
        }

        let hour = parseInt(match[1], 10);
        const minute = parseInt(match[2], 10);
        const suffix = match[3].toUpperCase();

        if (isNaN(hour) || isNaN(minute) || hour < 1 || hour > 12 || minute < 0 || minute > 59) {
            return -1;
        }

        if (suffix === "AM" && hour === 12) {
            hour = 0;
        } else if (suffix === "PM" && hour !== 12) {
            hour += 12;
        }

        return hour * 60 + minute;
    }

    function _parseDateOnly(value) {
        if (value === undefined || value === null) {
            return null;
        }

        const raw = String(value).trim();
        const match = raw.match(/^(\d{4})-(\d{2})-(\d{2})$/);
        if (!match) {
            return null;
        }

        const year = parseInt(match[1], 10);
        const month = parseInt(match[2], 10);
        const day = parseInt(match[3], 10);
        if (isNaN(year) || isNaN(month) || isNaN(day)) {
            return null;
        }

        return {
            year: year,
            month: month,
            day: day
        };
    }

    function _dayStartEpochMs(dateText) {
        const parsed = _parseDateOnly(dateText);
        if (!parsed) {
            return -1;
        }
        return new Date(parsed.year, parsed.month - 1, parsed.day, 0, 0, 0, 0).getTime();
    }

    function _observationEpochMs(current) {
        const raw = _safeValue(current.localObsDateTime).trim();
        const match = raw.match(/^(\d{4})-(\d{2})-(\d{2})\s+(\d{1,2}):(\d{2})(?:\s*([AP]M))?$/i);
        if (!match) {
            return Date.now();
        }

        const year = parseInt(match[1], 10);
        const month = parseInt(match[2], 10);
        const day = parseInt(match[3], 10);
        let hour = parseInt(match[4], 10);
        const minute = parseInt(match[5], 10);
        const suffix = match[6] ? match[6].toUpperCase() : "";

        if (isNaN(year) || isNaN(month) || isNaN(day) || isNaN(hour) || isNaN(minute) || minute < 0 || minute > 59) {
            return Date.now();
        }

        if (suffix.length > 0) {
            if (hour < 1 || hour > 12) {
                return Date.now();
            }
            if (suffix === "AM" && hour === 12) {
                hour = 0;
            } else if (suffix === "PM" && hour !== 12) {
                hour += 12;
            }
        } else if (hour < 0 || hour > 23) {
            return Date.now();
        }

        return new Date(year, month - 1, day, hour, minute, 0, 0).getTime();
    }

    function _ceilToHourEpochMs(epochMs) {
        const date = new Date(epochMs);
        date.setSeconds(0, 0);
        if (date.getMinutes() > 0) {
            date.setHours(date.getHours() + 1);
            date.setMinutes(0);
        }
        return date.getTime();
    }

    function _toAmPmLabel(hour24) {
        if (hour24 < 0 || hour24 > 23) {
            return "—";
        }

        const suffix = hour24 >= 12 ? "PM" : "AM";
        const hour12 = hour24 % 12 === 0 ? 12 : hour24 % 12;
        return hour12 + suffix;
    }

    function _toAmPmWithMinutesLabel(hour24, minute) {
        if (hour24 < 0 || hour24 > 23 || minute < 0 || minute > 59) {
            return "—";
        }

        const suffix = hour24 >= 12 ? "PM" : "AM";
        const hour12 = hour24 % 12 === 0 ? 12 : hour24 % 12;
        const minuteText = minute < 10 ? "0" + minute : String(minute);
        return hour12 + ":" + minuteText + suffix;
    }

    function _isDaytimeHour(hour24) {
        return hour24 >= 6 && hour24 < 18;
    }

    function _isDaytime(current) {
        const rawFlag = (current.isdaytime || current.isDayTime || current.is_day || "").toString().toLowerCase();
        if (rawFlag === "yes" || rawFlag === "day" || rawFlag === "1" || rawFlag === "true") {
            return true;
        }
        if (rawFlag === "no" || rawFlag === "night" || rawFlag === "0" || rawFlag === "false") {
            return false;
        }

        const obsHour = _parseHour(current.observation_time || "");
        if (obsHour >= 0) {
            return obsHour >= 6 && obsHour < 18;
        }

        const localHour = _parseHour(current.localObsDateTime || "");
        if (localHour >= 0) {
            return localHour >= 6 && localHour < 18;
        }

        return true;
    }

    function _weatherCategory(codeRaw, conditionRaw) {
        const condition = (conditionRaw || "").toString().toLowerCase();
        const code = parseInt(codeRaw, 10);
        const hasCode = !isNaN(code);

        if (condition.indexOf("tornado") !== -1) return "tornado";
        if (condition.indexOf("squall") !== -1) return "squall";
        if (condition.indexOf("thunder") !== -1) return "thunder";
        if (condition.indexOf("snow") !== -1 || condition.indexOf("sleet") !== -1 || condition.indexOf("blizzard") !== -1) return "snow";
        if (condition.indexOf("drizzle") !== -1 || condition.indexOf("freezing drizzle") !== -1) return "drizzle";
        if (condition.indexOf("heavy rain") !== -1 || condition.indexOf("torrential") !== -1) return "heavy_rain";
        if (condition.indexOf("rain") !== -1 || condition.indexOf("shower") !== -1) return "light_rain";
        if (condition.indexOf("mist") !== -1) return "mist";
        if (condition.indexOf("fog") !== -1) return "fog";
        if (condition.indexOf("smoke") !== -1) return "smoke";
        if (condition.indexOf("haze") !== -1) return "haze";
        if (condition.indexOf("dust") !== -1) return "dust";
        if (condition.indexOf("sand") !== -1) return "sand";
        if (condition.indexOf("ash") !== -1) return "ash";
        if (condition.indexOf("cloud") !== -1 || condition.indexOf("overcast") !== -1) return "cloudy";
        if (condition.indexOf("clear") !== -1 || condition.indexOf("sunny") !== -1) return "clear";

        if (hasCode) {
            if (code === 113) return "clear";
            if (code === 116 || code === 119 || code === 122) return "cloudy";
            if (code === 143) return "mist";
            if (code === 176 || code === 293 || code === 296 || code === 299 || code === 353) return "light_rain";
            if (code === 263 || code === 266 || code === 281 || code === 284 || code === 311 || code === 314 || code === 317 || code === 350) return "drizzle";
            if (code === 302 || code === 305 || code === 308 || code === 356 || code === 359) return "heavy_rain";
            if (code === 200 || code === 386 || code === 389) return "thunder";
            if (code === 227 || code === 230 || code === 323 || code === 326 || code === 329 || code === 332 || code === 335 || code === 338 || code === 368 || code === 371 || code === 374 || code === 377 || code === 392 || code === 395 || code === 179 || code === 182 || code === 185) return "snow";
            if (code === 248 || code === 260) return "fog";
        }

        return "cloudy";
    }

    function _resolveSymbol(current, conditionRaw) {
        const category = _weatherCategory(current.weatherCode, conditionRaw);
        const suffix = _isDaytime(current) ? "day" : "night";
        const key = category + "_" + suffix;
        return symbolByKey[key] || symbolByKey.cloudy_night;
    }

    function _resolveHourlySymbol(hourlyEntry, conditionRaw, hour24) {
        const category = _weatherCategory(hourlyEntry.weatherCode, conditionRaw);
        const suffix = _isDaytimeHour(hour24) ? "day" : "night";
        const key = category + "_" + suffix;
        return symbolByKey[key] || symbolByKey.cloudy_night;
    }

    function _forecastReferenceHour(current) {
        const localObsHour = _parseHour(current.localObsDateTime || "");
        if (localObsHour >= 0) {
            return localObsHour;
        }

        const obsHour = _parseHour(current.observation_time || "");
        if (obsHour >= 0) {
            return obsHour;
        }

        return (new Date()).getHours();
    }

    function _buildAnchorPoints(weatherDays) {
        const anchors = [];
        if (!Array.isArray(weatherDays) || weatherDays.length === 0) {
            return anchors;
        }

        for (let dayIndex = 0; dayIndex < weatherDays.length; dayIndex++) {
            const day = weatherDays[dayIndex] || {};
            const dayStart = _dayStartEpochMs(day.date);
            if (dayStart < 0) {
                continue;
            }

            const hourlyArray = day.hourly;
            if (!Array.isArray(hourlyArray) || hourlyArray.length === 0) {
                continue;
            }

            for (let i = 0; i < hourlyArray.length; i++) {
                const entry = hourlyArray[i] || {};
                const minuteOfDay = _minuteFromWttrTime(entry.time);
                if (minuteOfDay < 0) {
                    continue;
                }

                const tempRaw = normalizedUnits === "u" ? entry.tempF : entry.tempC;
                const tempNumber = Number(tempRaw);
                if (!isFinite(tempNumber)) {
                    continue;
                }

                const hour24 = Math.floor(minuteOfDay / 60);
                const conditionRaw = _safeGet(entry, ["weatherDesc", 0, "value"]);
                const symbol = _resolveHourlySymbol(entry, conditionRaw, hour24);
                const epochMs = dayStart + minuteOfDay * 60 * 1000;

                anchors.push({
                    epochMs: epochMs,
                    temp: tempNumber,
                    symbol: symbol,
                    entry: entry
                });
            }
        }

        anchors.sort(function (left, right) {
            return left.epochMs - right.epochMs;
        });

        return anchors;
    }

    function _buildAstronomyEvents(weatherDays) {
        const events = [];
        if (!Array.isArray(weatherDays) || weatherDays.length === 0) {
            return events;
        }

        for (let dayIndex = 0; dayIndex < weatherDays.length; dayIndex++) {
            const day = weatherDays[dayIndex] || {};
            const dayStart = _dayStartEpochMs(day.date);
            if (dayStart < 0) {
                continue;
            }

            const astronomy = _safeGet(day, ["astronomy", 0]) || {};
            const sunriseMinute = _minuteFromAmPm(astronomy.sunrise);
            const sunsetMinute = _minuteFromAmPm(astronomy.sunset);

            if (sunriseMinute >= 0) {
                events.push({
                    type: "sunrise",
                    epochMs: dayStart + sunriseMinute * 60 * 1000,
                    symbol: sunriseGlyph
                });
            }

            if (sunsetMinute >= 0) {
                events.push({
                    type: "sunset",
                    epochMs: dayStart + sunsetMinute * 60 * 1000,
                    symbol: sunsetGlyph
                });
            }
        }

        events.sort(function (left, right) {
            return left.epochMs - right.epochMs;
        });

        return events;
    }

    function _parseHourlyForecastLegacy(weatherDays, current) {
        if (!Array.isArray(weatherDays) || weatherDays.length === 0) {
            return [];
        }

        const nowHour = _forecastReferenceHour(current);
        const orderedEntries = [];

        for (let dayIndex = 0; dayIndex < weatherDays.length; dayIndex++) {
            const day = weatherDays[dayIndex] || {};
            const hourlyArray = day.hourly;
            if (!Array.isArray(hourlyArray) || hourlyArray.length === 0) {
                continue;
            }

            for (let i = 0; i < hourlyArray.length; i++) {
                const entry = hourlyArray[i] || {};
                const hour24 = _hourFromWttrTime(entry.time);
                if (hour24 < 0) {
                    continue;
                }

                const dayOffset = dayIndex === 0 && hour24 < nowHour
                    ? weatherDays.length
                    : dayIndex;

                orderedEntries.push({
                    entry: entry,
                    hour24: hour24,
                    sortKey: dayOffset * 24 + hour24
                });
            }
        }

        if (orderedEntries.length === 0) {
            return [];
        }

        orderedEntries.sort(function (left, right) {
            return left.sortKey - right.sortKey;
        });

        const output = [];
        for (let j = 0; j < 6; j++) {
            const item = orderedEntries[j % orderedEntries.length];
            const entry = item.entry;
            const hour24 = item.hour24;
            const conditionRaw = _safeGet(item.entry, ["weatherDesc", 0, "value"]);
            const tempRaw = normalizedUnits === "u" ? item.entry.tempF : item.entry.tempC;

            output.push({
                timeLabel: _toAmPmLabel(hour24),
                temp: _safeValue(tempRaw),
                symbol: _resolveHourlySymbol(entry, conditionRaw, hour24 >= 0 ? hour24 : 12)
            });
        }

        return output;
    }

    function _parseHourlyForecast(weatherDays, current) {
        const anchors = _buildAnchorPoints(weatherDays);
        if (anchors.length < 2) {
            return _parseHourlyForecastLegacy(weatherDays, current);
        }

        const slotCount = 6;
        const oneHourMs = 60 * 60 * 1000;
        const observationEpochMs = _observationEpochMs(current);
        const windowStart = _ceilToHourEpochMs(observationEpochMs);
        const windowEnd = windowStart + slotCount * oneHourMs;

        const output = [];

        for (let index = 0; index < slotCount; index++) {
            const targetEpoch = windowStart + index * oneHourMs;

            let rightIndex = -1;
            for (let i = 0; i < anchors.length; i++) {
                if (anchors[i].epochMs >= targetEpoch) {
                    rightIndex = i;
                    break;
                }
            }

            if (rightIndex <= 0) {
                return _parseHourlyForecastLegacy(weatherDays, current);
            }

            const left = anchors[rightIndex - 1];
            const right = anchors[rightIndex];
            if (right.epochMs <= left.epochMs) {
                return _parseHourlyForecastLegacy(weatherDays, current);
            }

            const ratio = (targetEpoch - left.epochMs) / (right.epochMs - left.epochMs);
            const temp = Math.round(left.temp + (right.temp - left.temp) * ratio);
            const date = new Date(targetEpoch);

            output.push({
                epochMs: targetEpoch,
                timeLabel: _toAmPmLabel(date.getHours()),
                temp: _safeValue(temp),
                symbol: left.symbol
            });
        }

        const events = _buildAstronomyEvents(weatherDays);
        let chosenEvent = null;
        for (let j = 0; j < events.length; j++) {
            const event = events[j];
            if (event.epochMs >= windowStart && event.epochMs < windowEnd) {
                chosenEvent = event;
                break;
            }
        }

        if (chosenEvent) {
            let bestIndex = 0;
            let bestDistance = Number.POSITIVE_INFINITY;
            for (let k = 0; k < output.length; k++) {
                const distance = Math.abs(output[k].epochMs - chosenEvent.epochMs);
                if (distance < bestDistance) {
                    bestDistance = distance;
                    bestIndex = k;
                }
            }

            const eventDate = new Date(chosenEvent.epochMs);
            output[bestIndex].timeLabel = _toAmPmWithMinutesLabel(eventDate.getHours(), eventDate.getMinutes());
            output[bestIndex].symbol = chosenEvent.symbol;
        }

        return output.map(function (entry) {
            return {
                timeLabel: entry.timeLabel,
                temp: entry.temp,
                symbol: entry.symbol
            };
        });
    }

    function _parseWeatherPayload(payloadText) {
        const parsed = JSON.parse(payloadText);
        const payload = parsed && typeof parsed === "object" && parsed.data && typeof parsed.data === "object"
            ? parsed.data
            : parsed;

        const cityFromApi = _safeGet(payload, ["nearest_area", 0, "areaName", 0, "value"]);
        const current = _safeGet(payload, ["current_condition", 0]) || {};
        const weatherDays = Array.isArray(payload.weather) ? payload.weather : [];
        const today = weatherDays[0] || {};

        const city = cityFromApi && String(cityFromApi).length > 0
            ? String(cityFromApi)
            : requestedLocation;

        const tempRaw = normalizedUnits === "u" ? current.temp_F : current.temp_C;
        const highRaw = normalizedUnits === "u" ? today.maxtempF : today.maxtempC;
        const lowRaw = normalizedUnits === "u" ? today.mintempF : today.mintempC;
        const conditionRaw = _safeGet(current, ["weatherDesc", 0, "value"]);
        const symbol = _resolveSymbol(current, conditionRaw);
        const hourly = _parseHourlyForecast(weatherDays, current);

        return {
            city: _safeValue(city),
            temp: _safeValue(tempRaw),
            condition: _safeValue(conditionRaw),
            high: _safeValue(highRaw),
            low: _safeValue(lowRaw),
            symbol: symbol,
            hourly: hourly
        };
    }

    function _storeLastGood(nextData) {
        _lastGoodData = nextData;
        data = nextData;
        lastUpdated = Date.now();
        cacheFile.setText(JSON.stringify({
            city: nextData.city,
            temp: nextData.temp,
            condition: nextData.condition,
            high: nextData.high,
            low: nextData.low,
            symbol: nextData.symbol,
            hourly: nextData.hourly,
            lastUpdated: lastUpdated
        }));
    }

    function _applyError(nextError) {
        error = nextError;
        if (_isValidData(_lastGoodData)) {
            data = _lastGoodData;
            return;
        }
        const cityHint = _lastGoodData && _lastGoodData.city
            ? _lastGoodData.city
            : requestedLocation;
        data = _placeholderData(cityHint);
    }

    function _loadCache() {
        const cachedText = cacheFile.text().trim();

        if (cachedText.length === 0) {
            return;
        }

        try {
            const cached = JSON.parse(cachedText);
            if (_isValidData(cached)) {
                _lastGoodData = {
                    city: _safeValue(cached.city),
                    temp: _safeValue(cached.temp),
                    condition: _safeValue(cached.condition),
                    high: _safeValue(cached.high),
                    low: _safeValue(cached.low),
                    symbol: cached.symbol ? String(cached.symbol) : symbolByKey.cloudy_night,
                    hourly: Array.isArray(cached.hourly) ? cached.hourly : []
                };
                data = _lastGoodData;
                if (typeof cached.lastUpdated === "number") {
                    lastUpdated = cached.lastUpdated;
                }
            }
        } catch (exception) {
            console.warn("Weather cache read failed:", exception);
        }
    }

    function _onFetchFinished(stderrText, stdoutText) {
        if (stdoutText.trim().length === 0) {
            if (stderrText.indexOf("not found") !== -1) {
                _applyError("curl is not installed or not in PATH.");
                return;
            }

            const details = stderrText.trim();
            _applyError(details.length > 0 ? details : "Weather fetch failed.");
            return;
        }

        try {
            const nextData = _parseWeatherPayload(stdoutText);
            _storeLastGood(nextData);
            error = "";
        } catch (exception) {
            const reason = exception && exception.message
                ? exception.message
                : "invalid payload";
            _applyError("Weather JSON parse failed: " + reason);
        }
    }

    function _handleCurlFinished() {
        if (!isLoading) {
            return;
        }

        _requestStartedAt = 0;
        requestStartGuard.stop();
        requestTimeoutGuard.stop();
        isLoading = false;
        _onFetchFinished(stderrCollector.text, stdoutCollector.text);
    }

    Component.onCompleted: {
        _loadCache();
        refresh();
    }

    property Timer refreshTimer: Timer {
        interval: 30 * 60 * 1000
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    property Timer requestStartGuard: Timer {
        interval: 1200
        repeat: false
        onTriggered: {
            if (root.isLoading && !curlProcess.running) {
                root._resetStuckRequest("Weather request failed to start.");
            }
        }
    }

    property Timer requestTimeoutGuard: Timer {
        interval: root.requestTimeoutMs
        repeat: false
        onTriggered: {
            if (root.isLoading) {
                root._resetStuckRequest("Weather request timed out.");
            }
        }
    }

    property Process curlProcess: Process {
        id: curlProcess
        stdout: StdioCollector {
            id: stdoutCollector
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: stderrCollector
            waitForEnd: true
        }

        onRunningChanged: {
            if (!running && root.isLoading) {
                root._handleCurlFinished();
                return;
            }

            if (!running && root._refreshQueued) {
                root._refreshQueued = false;
                Qt.callLater(root.refresh);
            }
        }
    }

    property FileView cacheFile: FileView {
        id: cacheFile
        path: root.cacheFilePath
        preload: true
        watchChanges: false
        blockLoading: true
        printErrors: false
        onSaveFailed: console.warn("Weather cache write failed.")
    }
}
