#!/usr/bin/dash

SYSTEM_LANG="$LANG"
export LANG='POSIX'
exec >/dev/null 2>&1

export XMODIFIERS=@im=none

LANG="$SYSTEM_LANG" \
exec rofi -theme-str '@import "main.rasi"' \
          -no-lazy-grab \
          -show drun

exit ${?}

