#!/bin/sh
# xss-lock hook: shows the AwesomeWM lockscreen and blocks until it is unlocked.

set -u

flag="${XDG_RUNTIME_DIR:-/tmp}/awesome-lockscreen.lock"
sleep_fd="${XSS_SLEEP_LOCK_FD:-}"

trap 'exit 0' TERM INT

result=$(awesome-client "return tostring(require('modules.lockscreen').show())" 2>&1)

case "$result" in
    *'"true"'*)
    ;;
    *)
        echo "awm-lockscreen: lockscreen.show() failed: $result" >&2
        exit 1
    ;;
esac

# The lock is up; let logind continue with the pending suspend.
[ -n "$sleep_fd" ] && eval "exec ${sleep_fd}<&-"

while [ -e "$flag" ]; do
    sleep 1
done
