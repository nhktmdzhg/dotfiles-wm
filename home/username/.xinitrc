#!/bin/sh
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax --exit-with-session)
fi

systemctl --user import-environment DISPLAY XAUTHORITY
# systemctl --user start graphical-session.target
systemctl --user start default.target --no-block
export SSH_AUTH_SOCK
export GNOME_KEYRING_CONTROL
export GNOME_KEYRING_PID

[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

xsettingsd &

exec awesome
