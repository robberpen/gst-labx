#!/bin/sh

# case #06031643 "tee" and use one instance of qtijpegenc only
# export XDG_RUNTIME_DIR=/dev/socket/weston
# weston --tty=1 --device=hdmi --idle-time=0 &


# Bssed on gst2-qtijpeg-tee-demo.sh
# 1. Removed change resolution on fakesink.
# 2. Add 1080p,720p on RTSP_CAP with  [ qtivtransform ! capsfilter caps="..." name=RTSP_CAP... ]


# Test report
# 220822 U301
# 115r segfailure, coredump:core.VideoEncMsgThre  core.gst-pipeline-ap
# 528r PLAYING to READY suspend(msg: Can't get stream buffer, skip this request: Connection timed out)
# 200r segfailure:
#
#   ERROR: from element /GstPipeline:pipeline0/GstOMXH264Enc-omxh264enc:omxh264enc-omxh264enc0: GStreamer encountered a general supporting library erro$
#   Additional debug info:
#   ../../gst-omx-1.14.4/omx/gstomxvideoenc.c(2086): gst_omx_video_enc_loop (): /GstPipeline:pipeline0/GstOMXH264Enc-omxh264enc:omxh264enc-omxh264enc0:
#   OpenMAX component in error state Hardware (0x80001009)
#
# 45r, segfailure.
# 13r, 14r. segfailure.
# Pipeline state changed from READY to PAUSED, pending: PLAYING
# Pipeline is PREROLLING ...
# Choose an option: weston_keyboard_set_focus  keyboard addr:0x7fdce6ffd8, surface addr:0x7fdce6ffd0, focus_resource_list:0x7fdce6ffe0
# Segmentation fault (core dumped)
# root@qcs610-odk-64:/data# 3


export GST_PLAY_DUR=10
export GST_READY_DUR=2
export GST_DEBUG=0
export GST_ROUND=1440
#export GST_DEBUG=qtivcomposer:0
# Enabled change resolution, 0 is disabled
export GST_CAP_TOGGLE=1

rm -rf   /data/dot
mkdir -p /data/dot
export GST_DEBUG_DUMP_DOT_DIR=/data/dot

# element capfilter's name must be "Cap1", "Cap2", "Cap3" ..
# export GST_CAP_NAME=Cap%
export GST_CAP_NAME=RTSP_CAP
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

# 220824 follow up Dev team requirment.
export GST_DEBUG=GST_STATES:5,qtivcomposer:7
export GST_DEBUG_FILE=/data/gst_vcomposer.log
export GST_DEBUG_NO_COLOR=1

/data/gst-pipeline-app -e qtiqmmfsrc name=qmmf0 camera=0 ! "video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" \
! queue ! tee name=t1 ! queue ! qtivcomposer name=mix sink_0::position="<49, 49>" sink_0::dimensions="<658, 370>" sink_1::position="<0, 0>" sink_1::dimensions="<1920, 1080>" \
! "video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! qtioverlay overlay-bbox="bbox0, bbox=<40, 40, 200, 48>, label="Pet", color=0x0000FFFF;" \
! qtivtransform ! capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1" name=RTSP_CAP ! omxh264enc target-bitrate=4000000 control-rate=2 interval-intraframes=30 max-quant-i-frames=38 max-quant-p-frames=40 ! \
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
qmmf1.video_1 ! capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1" name=NA ! queue ! tee name=tee2 ! queue ! mix1. \
tee1. ! queue ! mix2. \
tee2. ! videorate max-rate=15 ! queue ! qtivtransform ! "video/x-raw, format=RGB, width=(int)416, height=(int)416, framerate=15/1" ! fakesink \
tee2. ! videorate max-rate=5 ! queue ! qtivtransform ! jpegenc ! fakesink

