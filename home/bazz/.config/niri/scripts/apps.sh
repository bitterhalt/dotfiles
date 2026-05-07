#!/usr/bin/env bash

pgrep -x zen >/dev/null || zen &
pgrep -x thunderbird >/dev/null || thunderbird &
pgrep -x Discord >/dev/null || discord &
pgrep -x steam >/dev/null || steam &
pgrep -x transmission-gtk >/dev/null || transmission-gtk &
