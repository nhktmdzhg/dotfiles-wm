#!/usr/bin/dash

export LANG='POSIX'
exec 2>/dev/null

ROW_ICON_FONT='feather 12'
MSG_ICON_FONT='feather 48'

A_='' A="<span font_desc='${ROW_ICON_FONT}' weight='bold'>${A_}</span>    Performance"
B_='' B="<span font_desc='${ROW_ICON_FONT}' weight='bold'>${B_}</span>    Balanced"
C_='' C="<span font_desc='${ROW_ICON_FONT}' weight='bold'>${C_}</span>    Super Battery"
# https://gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html#:~:text=expand_aliases
[ -z "$BASH" ] || shopt -s expand_aliases

case "${@}" in
    "$A") powerprofilesctl set performance && notify-send -i ~/.local/share/icons/BeautyLine/apps/scalable/portfolio-performance-bin.svg 'Performance mode activated'
    ;;
    "$B") powerprofilesctl set balanced && notify-send -i ~/.local/share/icons/BeautyLine/apps/scalable/portfolio-performance-bin.svg 'Balanced mode activated'
    ;;
    "$C") powerprofilesctl set power-saver && notify-send -i ~/.local/share/icons/BeautyLine/apps/scalable/portfolio-performance-bin.svg 'Super Battery mode activated'
    ;;
esac
CURR_MODE="$(powerprofilesctl get)"
case "$CURR_MODE" in
    pe*) MODE="Performance" I_="${A_}${A_}"
    ;;
    ba*) MODE="Balanced" I_="${B_}${B_}"
    ;;
    po*) MODE="Super Battery" I_="${C_}${C_}"
    ;;
esac
I="<span font_desc='${ROW_ICON_FONT}' weight='bold'>${I_}</span>   Current mode: ${MODE}"
MESSAGE="<span font_desc='${MSG_ICON_FONT}' weight='bold'></span>"

printf '%b\n' '\0use-hot-keys\037true' '\0markup-rows\037true' "\0message\037${MESSAGE}" \
              "$I" "$A" "$B" "$C"

exit ${?}
