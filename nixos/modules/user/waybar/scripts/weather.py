#!/usr/bin/env python3

import json
import requests
from datetime import datetime

# Mapping weather codes to emoji
WEATHER_CODES = {
    '113': '☀️',
    '116': '⛅️',
    '119': '☁️',
    '122': '☁️',
    '143': '🌫',
    '176': '🌦',
    '179': '🌧',
    '182': '🌧',
    '185': '🌧',
    '200': '⛈',
    '227': '🌨',
    '230': '❄️',
    '248': '🌫',
    '260': '🌫',
    '263': '🌦',
    '266': '🌦',
    '281': '🌧',
    '284': '🌧',
    '293': '🌦',
    '296': '🌦',
    '299': '🌧',
    '302': '🌧',
    '305': '🌧',
    '308': '🌧',
    '311': '🌧',
    '314': '🌧',
    '317': '🌧',
    '320': '🌨',
    '323': '🌨',
    '326': '🌨',
    '329': '❄️',
    '332': '❄️',
    '335': '❄️',
    '338': '❄️',
    '350': '🌧',
    '353': '🌦',
    '356': '🌧',
    '359': '🌧',
    '362': '🌧',
    '365': '🌧',
    '368': '🌨',
    '371': '❄️',
    '374': '🌧',
    '377': '🌧',
    '386': '⛈',
    '389': '🌩',
    '392': '⛈',
    '395': '❄️'
}

def format_time(time_str):
    """Normalize hour string (e.g., '0', '600', '1200')."""
    return time_str.replace('00', '').zfill(2)


def format_temp_f(hour):
    """Format the 'Feels Like' temperature in Fahrenheit."""
    return f"{hour['FeelsLikeF']}°F".ljust(4)


def format_chances(hour):
    """Return weather event chance descriptions."""
    chances = {
        'chanceoffog': 'Fog',
        'chanceoffrost': 'Frost',
        'chanceofovercast': 'Overcast',
        'chanceofrain': 'Rain',
        'chanceofsnow': 'Snow',
        'chanceofsunshine': 'Sunshine',
        'chanceofthunder': 'Thunder',
        'chanceofwindy': 'Wind'
    }
    conditions = []
    for key, label in chances.items():
        if int(hour.get(key, 0)) > 0:
            conditions.append(f"{label} {hour[key]}%")
    return ', '.join(conditions)


def main():
    data = {}
    # Request JSON data
    # 'format=j1' returns both Celsius and Fahrenheit fields
    weather = requests.get(
        'https://wttr.in/krasnodar,Manitoba?format=j1'
    ).json()

    current = weather['current_condition'][0]
    icon = WEATHER_CODES.get(current['weatherCode'], '')
    temp_f = current['FeelsLikeF']
    wind_mph = current['windspeedMiles']

    # Text for waybar
    data['text'] = f"{icon} {temp_f}°F"

    # Tooltip with more details
    tooltip = []
    tooltip.append(f"<b>{current['weatherDesc'][0]['value']} {current['temp_F']}°F</b>")
    tooltip.append(f"Feels like: {current['FeelsLikeF']}°F")
    tooltip.append(f"Wind: {wind_mph} mph")
    tooltip.append(f"Humidity: {current['humidity']}%")

    # Forecast for today & tomorrow
    for idx, day in enumerate(weather['weather'][:2]):
        label = 'Today' if idx == 0 else 'Tomorrow'
        tooltip.append(f"\n<b>{label}, {day['date']}</b>")
        tooltip.append(
            f"⬆️ {day['maxtempF']}°F ⬇️ {day['mintempF']}°F "
            f" {day['astronomy'][0]['sunrise']}  {day['astronomy'][0]['sunset']}"
        )
        # Hourly details (skip past hours for today)
        for hour in day['hourly']:
            h = format_time(hour['time'])
            if idx == 0 and int(h) < datetime.now().hour - 2:
                continue
            icon_h = WEATHER_CODES.get(hour['weatherCode'], '')
            tooltip.append(
                f"{h}:00 {icon_h} {format_temp_f(hour)} "
                f"{hour['weatherDesc'][0]['value']}, {format_chances(hour)}"
            )

    data['tooltip'] = '\n'.join(tooltip)
    print(json.dumps(data))

if __name__ == '__main__':
    main()
