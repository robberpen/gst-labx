#!/bin/sh

# This is test resolution change, stop after 720 Round.
# It change between 1080p30 720p30.

# PLAYING time 10 second
export GST_PLAY_DUR=15

# READY and NULL time 2 second
export GST_READY_DUR=2

# Stop $GST_ROUND (720) state change and exit from NULL to PLAYING loop testing
# GST_ROUND=0 is never stop.
export GST_ROUND=720


export GST_DEBUG=qtivcomposer:1


# Enabled change resolution, 0 is disabled
export GST_CAP_TOGGLE=1

# element capfilter's name must be "Cap1", "Cap2", "Cap3" ..
export GST_CAP_NAME=Cap%
export GST_CAP1="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1"
export GST_CAP2="video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1"

/data/gst-test --gst-debug-no-color -e qtiqmmfsrc name=qmmf0 camera=0 video_1::source-index=0 \
video_2::source-index=1 video_3::source-index=1 video_4::source-index=1 ! \
capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" name=Cap0 ! qtivcomposer name=mix latency=200 \
sink_0::position="<0, 100>" sink_0::dimensions="<640, 540>" \
sink_1::position="<640, 100>" sink_1::dimensions="<640, 540>" \
mix. ! capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=60/1" name=Cap1 ! \
omxh264enc target-bitrate=32000000 control-rate=2 interval-intraframes=29 ! \
h264parse config-interval=-1 ! rtph264pay pt=96 ! udpsink host=127.0.0.1 port=8554 \
qmmf0. ! capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=60/1" name=Cap2 ! mix.
