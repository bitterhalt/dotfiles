#!/bin/bash
pwm1=$(cat "/sys/class/drm/card0/device/hwmon/hwmon3/pwm1")
rpm_max=3630
pwm_max=255
rpm1=$(echo "$rpm_max/100" | bc -l )
rpm2=$(echo "$pwm1/$pwm_max" | bc -l)
echo "scale=0; $rpm1*$rpm2*100 / 1" | bc
