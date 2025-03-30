#!/bin/sh

# A dwm_bar function to read the battery level and status
# GNU GPLv3

dwm_battery () {
    # Find available battery (BAT0 or BAT1)
    BATTERY_PATH=$(ls /sys/class/power_supply/ | grep -E '^BAT[0-9]$' | head -n1)

    # If no battery is found, return without printing anything
    if [ -z "$BATTERY_PATH" ]; then
        return
    fi

    CHARGE=$(cat /sys/class/power_supply/"$BATTERY_PATH"/capacity)
    STATUS=$(cat /sys/class/power_supply/"$BATTERY_PATH"/status)

    printf "%s" "$SEP1"
    if [ "$IDENTIFIER" = "unicode" ]; then
        if [ "$STATUS" = "Charging" ]; then
            printf "🔌 %s%% %s" "$CHARGE" "$STATUS"
        else
            printf "🔋 %s%% %s" "$CHARGE" "$STATUS"
        fi
    else
        printf "BAT %s%% %s" "$CHARGE" "$STATUS"
    fi
    printf "%s\n" "$SEP2"
}

dwm_battery

