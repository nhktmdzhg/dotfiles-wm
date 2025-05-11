#!/usr/bin/dash

export LANG='POSIX'
exec >/dev/null 2>&1

trap 'kill %%' TERM INT

# https://gnu.org/software/bash/manual/html_node/The-Shopt-Builtin.html#:~:text=expand_aliases
[ -z "$BASH" ] || shopt -s expand_aliases
betterlockscreen -l blur
wait

{
    dunstctl set-paused false

    dunstify 'Session Manager' "Welcome back <u>${USER:-$(id -nu)}</u>" -h string:synchronous:session-manager \
                                                                        -a joyful_desktop \
                                                                        -i ~/.icons/Gladient/logout.png
} &

exit ${?}

