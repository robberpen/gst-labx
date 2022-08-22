#!/bin/sh

# case #06031643 "tee" and use one instance of qtijpegenc only
# export XDG_RUNTIME_DIR=/dev/socket/weston
# weston --tty=1 --device=hdmi --idle-time=0 &

# Test Result:
# 220822 - check by VLC, and HDMI is working(120 loop cont-) need more test

export GST_PLAY_DUR=10
export GST_READY_DUR=2
export GST_DEBUG=0
export GST_ROUND=1440
# export GST_DEBUG=qtivcomposer:0
# Enabled change resolution, 0 is disabled
export GST_CAP_TOGGLE=1

rm -fr   /data/dot
mkdir -p /data/dot
export GST_DEBUG_DUMP_DOT_DIR=/data/dot

# element capfilter's name must be "Cap1", "Cap2", "Cap3" ..
export GST_CAP_NAME=Cap
export GST_CAP1="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1"
export GST_CAP2="video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1"

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

export XDG_RUNTIME_DIR=/dev/socket/weston
#hdmi_up
#rtsp_server

/data/gst-pipeline-app -e qtiqmmfsrc name=qmmf0 camera=0 ! "video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" \
! queue ! tee name=t1 ! queue ! qtivcomposer name=mix sink_0::position="<49, 49>" sink_0::dimensions="<658, 370>" sink_1::position="<0, 0>" sink_1::dimensions="<1920, 1080>" \
! "video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! qtioverlay overlay-bbox="bbox0, bbox=<40, 40, 200, 48>, label="Pet", color=0x0000FFFF;" \
! "video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! omxh264enc target-bitrate=4000000 control-rate=2 interval-intraframes=30 max-quant-i-frames=38 max-quant-p-frames=40 ! \
h264parse config-interval=-1 ! rtph264pay pt=96 ! udpsink host=$RTSP_SERVER_IP port=8554 \
qmmf0.video_1 ! "video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1" ! queue ! tee name=t2 ! queue ! qtivcomposer name=mix1 \
sink_1::position="<33, 33>" sink_1::dimensions="<439, 246>" sink_0::position="<0, 0>" sink_0::dimensions="<1280, 720>" \
! "video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1" ! qtioverlay overlay-bbox="bbox0, bbox=<40, 40, 200, 48>, label="Pet", color=0x0000FFFF;" ! "video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1" ! qtijpegenc ! fakesink \
t1. ! queue ! qtivcomposer name=mix2 sink_1::position="<49, 49>" sink_1::dimensions="<658, 370>" sink_0::position="<0, 0>" sink_0::dimensions="<1920, 1080>" ! \
"video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! waylandsink fullscreen=true async=false \
t2. ! videorate max-rate=15 ! queue ! qtivtransform ! "video/x-raw, format=RGB, width=(int)416, height=(int)416, framerate=15/1" ! fakesink \
t2. ! videorate max-rate=5 ! queue ! qtivtransform ! jpegenc! fakesink \
qtiqmmfsrc name=qmmf1 camera=1 video_2::source-index=0 video_3::source-index=1 video_4::source-index=1 ! \
"video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! queue ! tee name=tee1 ! queue ! mix. \
qmmf1.video_1 ! capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1" name=Cap ! queue ! tee name=tee2 ! queue ! mix1. \
tee1. ! queue ! mix2. \
tee2. ! videorate max-rate=15 ! queue ! qtivtransform ! "video/x-raw, format=RGB, width=(int)416, height=(int)416, framerate=15/1" ! fakesink \
tee2. ! videorate max-rate=5 ! queue ! qtivtransform ! jpegenc ! fakesink

