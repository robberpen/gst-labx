#!/bin/sh

while true;do

(logcat  | grep 'Selected Usecase' -m1 ) && logcat |tee /data/logcat.round.log|grep  'frame_num = 900' -m1;logcat -c

done
