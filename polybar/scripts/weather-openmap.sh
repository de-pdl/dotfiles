#!/usr/bin/env bash
set -euo pipefail

get_icon() {
    case $1 in
        01d) icon="󰖙 " ;; # Clear sky day (Sun)
        01n) icon="󰖔 " ;; # Clear sky night (Moon)
        02d) icon="󰖕 " ;; # Few clouds day
        02n) icon="󰼱 " ;; # Few clouds night
        04d) icon="󰖐 " ;; # Broken clouds day
        04n) icon="󰼵 " ;; # Broken clouds night
        09d) icon="󰖗 " ;; # Shower rain day
        09n) icon="󰖗 " ;; # Shower rain night
        10d) icon="󰖖 " ;; # Rain day
        10n) icon="󰼳 " ;; # Rain night
        11d) icon="󰖓 " ;; # Thunderstorm day
        11n) icon="󰖓 " ;; # Thunderstorm night
        13d) icon="󰖘 " ;; # Snow day
        13n) icon="󰖘 " ;; # Snow night
        50d) icon="󰖑 " ;; # Mist/Fog day
        50n) icon="󰖑 " ;; # Mist/Fog night
        *)   icon="󰖐 " ;; # Default (Cloud)
    esac

    echo $icon
}



get_duration() {

    osname=$(uname -s)

    case $osname in
        *BSD) date -r "$1" -u +%H:%M;;
        *) date --date="@$1" -u +%H:%M;;
    esac

}

KEY="bcbdca713092c2d99f91859256367d07"
CITY="Sydney"
UNITS="metric"
SYMBOL="°"

API="https://api.openweathermap.org/data/2.5"

if [ ! -z $CITY ]; then
    if [ "$CITY" -eq "$CITY" ] 2>/dev/null; then
        CITY_PARAM="id=$CITY"
    else
        CITY_PARAM="q=$CITY"
    fi

    current=$(curl -sf "$API/weather?appid=$KEY&$CITY_PARAM&units=$UNITS")
    #curl -s "https://api.openweathermap.org/data/2.5/onecall?lat=0&lon=0&appid=TOKEN&units=metric" | jq -r '.daily[1].temp.day'
    forecast=$(curl -sf "$API/forecast?appid=$KEY&$CITY_PARAM&units=$UNITS&cnt=1")
else
    location=$(curl -sf https://location.services.mozilla.com/v1/geolocate?key=geoclue)

    if [ ! -z "$location" ]; then
        location_lat="$(echo "$location" | jq '.location.lat')"
        location_lon="$(echo "$location" | jq '.location.lng')"

        current=$(curl -sf "$API/weather?appid=$KEY&lat=$location_lat&lon=$location_lon&units=$UNITS")
        forecast=$(curl -sf "$API/forecast?appid=$KEY&lat=$location_lat&lon=$location_lon&units=$UNITS&cnt=1")
    fi
fi

if [ ! -z "$current" ] && [ ! -z "$forecast" ]; then
    current_temp=$(printf "%.0f" $(echo "$current" | jq ".main.temp"))
    current_icon=$(echo "$current" | jq -r ".weather[0].icon")

    forecast_temp=$(printf "%.0f" $(echo "$forecast" | jq ".list[].main.temp"))
    forecast_icon=$(echo "$forecast" | jq -r ".list[].weather[0].icon")

    sun_rise=$(echo "$current" | jq ".sys.sunrise")
    sun_set=$(echo "$current" | jq ".sys.sunset")
    now=$(date +%s)

    if [ "$sun_rise" -gt "$now" ]; then
        daytime="🌅 $(get_duration "$((sun_rise-now))")"
    elif [ "$sun_set" -gt "$now" ]; then
        daytime="🌇 $(get_duration "$((sun_set-now))")"
    else
        daytime="🌅 $(get_duration "$((sun_rise-now))")"
    fi

    echo "$(get_icon "$current_icon") $current_temp$SYMBOL $(get_icon "$forecast_icon") $forecast_temp$SYMBOL  $daytime"
fi
