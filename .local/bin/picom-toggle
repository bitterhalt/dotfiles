#!/bin/bash

if [ `pgrep -x picom` ]; then
   notify-send -t 2000 'Picom disabled!'
   killall picom;
else
   notify-send -t 2000 'Picom enabled!'
   picom &
fi
exit

