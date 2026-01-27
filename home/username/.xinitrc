#!/bin/sh

if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax --exit-with-session)
fi

eval $(/usr/bin/gnome-keyring-daemon --start --components=pkcs11,secrets,ssh)

systemctl --user import-environment DISPLAY XAUTHORITY
# systemctl --user start graphical-session.target
systemctl --user start default.target --no-block
export SSH_AUTH_SOCK
export GNOME_KEYRING_CONTROL
export GNOME_KEYRING_PID

if [ -d "/etc"/X11/Xresources ]; then
    for i in "/etc"/X11/Xresources/*; do
        [ -f "$i" ] && xrdb -merge "$i"
    done
    elif [ -f "/etc"/X11/Xresources ]; then
    xrdb -merge "/etc"/X11/Xresources
fi
[ -f "$HOME"/.Xresources ] && xrdb -merge "$HOME"/.Xresources
[ -f "$XDG_CONFIG_HOME"/X11/Xresources ] && xrdb -merge "$XDG_CONFIG_HOME"/X11/Xresources

xsettingsd &

exec awesome
