#!/bin/sh

# based on gst-a
# 1. Add two latency after qtivcomposer
# 2. Support change resolution test
# 3. Fixed all 60fps to 30fps.

# export XDG_RUNTIME_DIR=/dev/socket/weston
# weston --tty=1 --device=hdmi --idle-time=0 &

export GST_PLAY_DUR=10
export GST_READY_DUR=2
export GST_DEBUG=0
export GST_ROUND=1440
#export GST_DEBUG=qtivcomposer:0
# Enabled change resolution, 0 is disabled
export GST_CAP_TOGGLE=1

# element capfilter's name must be "Cap1", "Cap2", "Cap3" ..
export GST_DEBUG_DUMP_DOT_DIR=/data/dot
rm -fr /data/dot 
mkdir -p /data/dot
export GST_CAP_NAME=CAP%
export GST_CAP1="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1"
export GST_CAP2="video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1"


/data/gst-pipeline-app --gst-debug-no-color -e qtiqmmfsrc name=qmmf0 camera=0 video_1::source-index=0 \
video_2::source-index=1 video_3::source-index=1 video_4::source-index=1 ! \
capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" name=CAP0 ! qtivcomposer name=mix latency=200 \
sink_0::position="<0, 200>" sink_0::dimensions="<640, 360>" \
sink_1::position="<640, 200>" sink_1::dimensions="<640, 360>" \
mix. ! capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" name=CAP1 ! \
omxh264enc target-bitrate=32000000 control-rate=2 interval-intraframes=29 ! \
h264parse config-interval=-1 ! rtph264pay pt=96 ! udpsink host=127.0.0.1 port=8554 \
qmmf0. ! capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" name=CAP2 ! mix. \
qmmf0. ! "video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=60/1" ! qtivcomposer name=mix1 latency=200 \
sink_0::position="<0, 270>" sink_0::dimensions="<960, 540>" \
sink_1::position="<960, 270>" sink_1::dimensions="<960, 540>" \
mix1. ! "video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=60/1" ! qtijpegenc ! fakesink \
qmmf0. ! "video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=60/1" ! mix1. \
qmmf0. ! video/x-raw,format=NV12,width=1280,height=720,framerate=10/1 ! \
qtivtransform ! "video/x-raw, format=RGB, width=(int)416, height=(int)416, framerate=10/1" ! fakesink
