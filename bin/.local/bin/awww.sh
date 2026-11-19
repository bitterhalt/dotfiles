#!/usr/bin/env bash

pgrep -x awww-daemon >/dev/null && pkill awww-daemon

awww-daemon &
awww-daemon -n overview &
