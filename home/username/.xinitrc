#!/bin/sh
# if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
#   eval $(dbus-launch --auto-syntax)
# fi
# systemctl --user start default.target --no-block
# if [ -d /etc/X11/xinit/xinitrc.d ] ; then
#     for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
#         [ -x "$f" ] && . "$f"
#     done
#     unset f
# fi
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  eval $(dbus-launch --sh-syntax --exit-with-session)
fi

dbus-update-activation-environment --all

systemctl --user start default.target --no-block

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

eval $(gnome-keyring-daemon --start --components=secrets)
export GNOME_KEYRING_CONTROL GNOME_KEYRING_PID GPG_AGENT_INFO SSH_AUTH_SOCK

xrdb -merge ~/.Xresources
xsettingsd &
exec awesome

