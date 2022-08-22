#!/bin/sh

export XDG_RUNTIME_DIR=/dev/socket/weston

RTSP_SERVER_IP=192.168.1.168

hdmi_up() {
  weston --tty=1 --device=hdmi --idle-time=0 &
  sleep 15
}

rtsp_server()
{
  ifconfig eth0 $RTSP_SERVER_IP up

  gst-rtsp-server -a $RTSP_SERVER_IP -p 8900 -m /live \
  "( udpsrc name=pay0 port=8554 caps=\"application/x-rtp,media=video,clock-rate=90000,encoding-name=H264,payload=96\" )" &
  sleep 5
}


hdmi_up
rtsp_server
