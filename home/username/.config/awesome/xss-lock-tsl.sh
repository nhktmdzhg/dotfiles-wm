#!/usr/bin/dash

exec >/dev/null 2>&1

trap 'kill %%' TERM INT

betterlockscreen -l blur
wait

{
    dunstctl set-paused false
    dunstify 'Session Manager' "Welcome back <u>${USER:-$(id -nu)}</u>" -h string:synchronous:session-manager \
                                                                        -a joyful_desktop \
                                                                        -i ~/.icons/Gladient/logout.png
} &
exit ${?}
