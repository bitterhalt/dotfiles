#!/usr/bin/env bash

# This launches all essentials from WM
discord &
$BROWSER &
thunderbird &
steam &
sleep 6 && transmission-gtk &
