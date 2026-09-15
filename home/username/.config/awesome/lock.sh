#!/bin/sh
# xss-lock hook: raises the AwesomeWM lockscreen when the session is considered idle.
awesome-client "require('modules.lockscreen').show()"
