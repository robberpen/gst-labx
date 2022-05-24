#!/bin/sh

while [ 1 ]; do
uptime
systemd-cgtop -m |grep qmmf

sleep 10
done
