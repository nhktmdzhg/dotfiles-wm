#!/usr/bin/dash

export LANG='POSIX'
exec 2>/dev/null

ROW_ICON_FONT='feather 12'
MSG_ICON_FONT='feather 48'

B_='' B="<span font_desc='${ROW_ICON_FONT}' weight='bold'>${B_}</span>   Increase 5%"
C_='' C="<span font_desc='${ROW_ICON_FONT}' weight='bold'>${C_}</span>   Decrease 5%"
D_='' D="<span font_desc='${ROW_ICON_FONT}' weight='bold'>${D_}</span>   Toggle mute"
F_='' F="<span font_desc='${ROW_ICON_FONT}' weight='bold'>${F_}</span>   Brighten 5%"
G_='' G="<span font_desc='${ROW_ICON_FONT}' weight='bold'>${G_}</span>   Dim 5%"

case "${@}" in
    "$B") ~/.scripts/change-volume.sh +
    ;;
    "$C") ~/.scripts/change-volume.sh -
    ;;
    "$D") ~/.scripts/change-volume.sh 0
    ;;
    "$F") ~/.scripts/change-brightness.sh +
    ;;
    "$G") ~/.scripts/change-brightness.sh -
    ;;
esac

AUDIO_DEVICE="$(pactl list sinks | grep -B1 -A9 State: | grep 'Name: ' | cut -d' ' -f2)"
AUDIO_VOLUME="$(pactl get-sink-volume "${AUDIO_DEVICE}" | grep -oP '\d+%' | tr -d '%' | head -n1)"
AUDIO_MUTED="$(pactl get-sink-mute "${AUDIO_DEVICE}" | grep -oP 'yes')"

BRIGHTNESS_VALUE="$(brightnessctl get)"
MAX_BRIGHTNESS="$(brightnessctl max)"
BRIGHTNESS=$(( BRIGHTNESS_VALUE * 100 / MAX_BRIGHTNESS ))
if [ "$AUDIO_VOLUME" -eq 0 -o "$AUDIO_MUTED" = 'yes' ]; then
    [ -z "$AUDIO_MUTED" ] || MUTED='Muted'
    A_=''
elif [ "$AUDIO_VOLUME" -lt 30 ]; then
    A_=''
elif [ "$AUDIO_VOLUME" -lt 70 ]; then
    A_=''
else
    A_=''
fi

A="<span font_desc='${ROW_ICON_FONT}' weight='bold'>${A_}</span>   ${MUTED-${AUDIO_VOLUME}}"
E_='' E="<span font_desc='${ROW_ICON_FONT}' weight='bold'>${E_}</span>   ${BRIGHTNESS}"

MESSAGE="<span font_desc='${MSG_ICON_FONT}' weight='bold'></span>"

printf '%b\n' '\0use-hot-keys\037true' '\0markup-rows\037true' "\0message\037${MESSAGE}" \
              "${A}\0nonselectable\037true" "$B" "$C" "$D" "${E}\0nonselectable\037true" "$F" "$G"

exit ${?}

