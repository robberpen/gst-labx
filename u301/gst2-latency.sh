#!/bin/sh

# case #06049505, dual CAM, latency
# 220729 - add latency on vcomposor. run on U301 with 2 cam. is working
#
export GST_PLAY_DUR=10
export GST_READY_DUR=2
export GST_DEBUG=0
export GST_ROUND=1440
#export GST_DEBUG=qtivcomposer:6

rm -rf   /data/dot
mkdir -p /data/dot
export GST_DEBUG_DUMP_DOT_DIR=/data/dot

# element capfilter's name must be "Cap1", "Cap2", "Cap3" ..
# export GST_CAP_NAME=Cap%
export GST_CAP_TOGGLE=1
export GST_CAP_NAME=RTSP_CAP
export GST_CAP1="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1"
export GST_CAP2="video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1"
export XDG_RUNTIME_DIR=/dev/socket/weston
RTSP_SERVER_IP=192.168.1.168

run_composer_latency()
{

# Based on QCOM linh #06049505
# add change resolution on rtsp
/data/gst-pipeline-app -e qtiqmmfsrc name=qmmf0 camera=0 video_2::source-index=0 video_3::source-index=1 video_4::source-index=1 ! \
"video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! queue ! qtivcomposer name=mix \
sink_0::position="<49, 49>" sink_0::dimensions="<658, 370>" sink_1::position="<0, 0>" sink_1::dimensions="<1920, 1080>" latency=200 \
! "video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! qtioverlay overlay-bbox="bbox0, bbox=<40, 40, 200, 48>, label="Pet", color=0x0000FFFF;" \
!  qtivtransform ! capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" name=RTSP_CAP ! omxh264enc target-bitrate=4000000 control-rate=2 interval-intraframes=30 max-quant-i-frames=38 max-quant-p-frames=40 ! \
h264parse config-interval=-1 ! rtph264pay pt=96 ! udpsink host=$RTSP_SERVER_IP port=8554 \
qmmf0.video_1 ! "video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1" ! queue ! qtivcomposer name=mix1 \
sink_1::position="<33, 33>" sink_1::dimensions="<439, 246>" sink_0::position="<0, 0>" sink_0::dimensions="<1280, 720>" latency=200 \
! "video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1" ! qtioverlay overlay-bbox="bbox0, bbox=<40, 40, 200, 48>, label="Pet", color=0x0000FFFF;" ! "video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1" ! qtijpegenc ! fakesink \
qmmf0.video_2 ! "video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! queue ! qtivcomposer name=mix2 \
sink_1::position="<49, 49>" sink_1::dimensions="<658, 370>" sink_0::position="<0, 0>" sink_0::dimensions="<1920, 1080>" latency=200 ! \
"video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! waylandsink fullscreen=true async=false \
qmmf0.video_3 ! "video/x-raw,format=NV12,width=1280,height=720,framerate=15/1" ! queue ! qtivtransform ! \
"video/x-raw, format=RGB, width=(int)416, height=(int)416, framerate=15/1" ! fakesink \
qmmf0.video_4 ! "video/x-raw,format=NV12,width=1280,height=720,framerate=5/1" ! queue ! qtivtransform ! qtijpegenc! fakesink \
qtiqmmfsrc name=qmmf1 camera=1 video_2::source-index=0 video_3::source-index=1 video_4::source-index=1 ! \
"video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! queue ! mix. \
qmmf1.video_1 ! "video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1" ! queue ! mix1. \
qmmf1.video_2 ! "video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! queue ! mix2. \
qmmf1.video_3 ! video/x-raw,format=NV12,width=1280,height=720,framerate=15/1 ! queue ! qtivtransform ! \
"video/x-raw, format=RGB, width=(int)416, height=(int)416, framerate=15/1" ! fakesink \
qmmf1.video_4 ! video/x-raw,format=NV12,width=1280,height=720,framerate=5/1 ! queue ! qtivtransform ! jpegenc ! fakesink
}
run_composer_latency
