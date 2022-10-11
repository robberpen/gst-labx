#!/bin/sh

# 220920 - copied from gst2-latency.sh, format pipeline

export GST_PLAY_DUR=10
export GST_READY_DUR=2
export GST_DEBUG=1
export GST_ROUND=1440
#export GST_DEBUG=qtivcomposer:6

rm -rf   /data/dot
mkdir -p /data/dot
rm -f /data/coredump/*
export GST_DEBUG_DUMP_DOT_DIR=/data/dot

# element capfilter's name must be "Cap1", "Cap2", "Cap3" ..
# export GST_CAP_NAME=Cap%
export GST_CAP_TOGGLE=1
export GST_CAP_NAME=CAP%
export GST_CAP1="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1"
export GST_CAP2="video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1"

export XDG_RUNTIME_DIR=/dev/socket/weston
RTSP_SERVER_IP=192.168.1.168


GSTAPP="gst-launch-1.0 -e"
#GSTAPP="/data/gst-pipeline-app -e"
#qmmfsrc0="qtiqmmfsrc name=qmmf0 camera=0 video_2::source-index=1 video_3::source-index=1 video_4::source-index=1 video_5::source-index=1"
#qmmfsrc0="qtiqmmfsrc name=qmmf0 camera=0 video_3::source-index=2"
qmmfsrc0="qtiqmmfsrc name=qmmf0 camera=0"
qmmfsrc1='qtiqmmfsrc name=qmmf1 camera=1 video_2::source-index=0 video_3::source-index=1 video_4::source-index=1'

#mix0='qtivcomposer name=mix0 sink_0::position="<49, 49>" sink_0::dimensions="<658, 370>" sink_1::position="<0, 0>" sink_1::dimensions="<1920, 1080>" latency=200'
mix0='qtivcomposer name=mix0 sink_0::position="<0, 0>" sink_0::dimensions="<960, 1080>" sink_1::position="<960, 0>" sink_1::dimensions="<960, 1080>" latency=200'
mix1='qtivcomposer name=mix1 sink_1::position="<33, 33>" sink_1::dimensions="<439, 246>" sink_0::position="<0, 0>" sink_0::dimensions="<1280, 720>" latency=200'
mix2='qtivcomposer name=mix2 sink_1::position="<49, 49>" sink_1::dimensions="<658, 370>" sink_0::position="<0, 0>" sink_0::dimensions="<1920, 1080>" latency=200'
mix6='qtivcomposer name=mix6 sink_0::position="<0, 0>" sink_0::dimensions="<640, 360>" 
 sink_1::position="<640,   0>" sink_1::dimensions="<640, 360>"
 sink_2::position="<1280,  0>" sink_2::dimensions="<640, 360>"
 sink_3::position="<0,   360>" sink_3::dimensions="<640, 360>"
 sink_4::position="<640, 360>" sink_4::dimensions="<640, 360>"
 sink_5::position="<1280,360>" sink_5::dimensions="<640, 360>"
 sink_6::position="<0,   720>" sink_6::dimensions="<640, 360>"
 sink_7::position="<640, 720>" sink_7::dimensions="<640, 360>"
 sink_8::position="<1280,720>" sink_8::dimensions="<640, 360>"
 latency=200'

overlay='qtioverlay overlay-bbox="bbox0, bbox=<40, 40, 200, 48>, label=\"Pet\", color=0x0000FFFF;"'

tee()
{
    echo "tee name=$1"
}

overlay_txt()
{
    #echo "overlay='qtioverlay overlay-bbox=\"bbox0, bbox=<40, 40, 200, 48>, label=\"$1\", color=0x0000FFFF;\"'"
    echo "qtioverlay overlay-bbox=\"bbox0, bbox=<40, 40, 200, 72>, label=\\\"$1\\\", color=0x0000FFFF;\""
}

#$(overlay_txt "a")
#exit 0
# transform='qtivtransform ! capsfilter caps=\"video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1\" name=RTSP_CAP'

#omx264="omxh264enc target-bitrate=4000000 control-rate=2 interval-intraframes=30 max-quant-i-frames=38 max-quant-p-frames=40 ! h264parse config-interval=-1"
omx264="omxh264enc target-bitrate=4000000 control-rate=2  max-quant-i-frames=38 max-quant-p-frames=40 ! h264parse config-interval=-1"
#omx264="omxh264enc  max-quant-i-frames=38  ! h264parse config-interval=-1"
#omx264="omxh264enc ! h264parse config-interval=-1"

rtsp="rtph264pay pt=96 ! udpsink host=$RTSP_SERVER_IP port=8554"

#waylandsink='waylandsink fullscreen=true async=false'
waylandsink='waylandsink fullscreen=true  sync=false async=true'



NV_1080P30='video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1'
NV_720P30='video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1'
NV_720P15='video/x-raw,format=NV12,width=1280,height=720,framerate=15/1'
NV_720P5='video/x-raw,format=NV12,width=1280,height=720,framerate=5/1'

RAW_1080P30='video/x-raw,format=NV12,width=1920,height=1080,framerate=30/1'

AI_TRANS="qtivtransform ! video/x-raw, format=RGB, width=(int)416, height=(int)416, framerate=15/1 ! fakesink"

TransForm1080P()
{
   echo 'qtivtransform ! capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" name='$1
}
CAPS_1080P()
{
    echo 'capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" name='$1
}
$GSTAPP $qmmfsrc0 ldc=1 ! $NV_1080P30 ! $waylandsink
#$GSTAPP  $qmmfsrc0 ! $NV_1080P30 ! $(overlay_txt RTSP) ! queue ! $omx264 ! $rtsp

# working, but unstable on VLC streams
$GSTAPP \
$qmmfsrc0     ! $NV_1080P30 ! $(overlay_txt HDMI) ! $mix6 ! queue ! $NV_1080P30 ! $waylandsink \
qmmf0.video_1 ! $NV_1080P30 ! $(overlay_txt Mixer) ! mix6. \
qmmf0.video_2 ! $NV_1080P30 ! $(tee t) ! queue ! mix6. \
t. ! queue ! mix6. \
t. ! queue ! mix6. \
t. ! queue ! $omx264 ! $rtsp

exit 0


#t. ! queue ! $omx264 ! $rtsp

exit 0
#qmmf0.video_4 ! $NV_1080P30 ! $(overlay_txt a) ! mix6. \
#qmmf0.video_5 ! $NV_1080P30 ! mix6.



#gst-launch-1.0 -e qtiqmmfsrc name=qmmf ! "video/x-raw(memory:GBM),format=NV12,camera=0,width=1920,height=1080,framerate=30/1" ! \
#tee name=t ! queue ! omxh264enc ! h264parse ! mp4mux ! queue ! filesink location="/data/mux.mp4" t. ! queue ! waylandsink sync=false fullscreen=true



exit 0
$GSTAPP $qmmfsrc0 ! $NV_1080P30 ! $waylandsink \
qmmf0.video_1 ! $NV_1080P30 ! fakesink \
qmmf0.video_2 ! $RAW_1080P30 ! $(tee T1) ! fakesink \
T1. ! fakesink

exit 0
qmmf0.video_3 ! $NV_1080P30  ! $omx264 ! $rtsp \
qmmf0.video_4 ! $NV_1080P30 ! qtijpegenc ! fakesink \
qmmf0.video_5 ! $NV_1080P30 ! $omx264

exit 0
echo 1 > /sys/class/kgsl/kgsl-3d0/force_rail_on
echo 1 > /sys/class/kgsl/kgsl-3d0/force_clk_on
echo 1 > /sys/class/kgsl/kgsl-3d0/force_bus_on
echo 10000000 > /sys/class/kgsl/kgsl-3d0/idle_timer
echo 0 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
echo 0 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
echo performance > /sys/class/kgsl/kgsl-3d0/devfreq/governor
echo 845000000 > /sys/class/kgsl/kgsl-3d0/gpuclk
echo 845000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
echo 845000000 > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
echo performance > /sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw/governor

$GSTAPP \
$qmmfsrc0     ! $NV_1080P30 ! $mix6 ! queue ! $NV_1080P30 ! $waylandsink \
qmmf0.video_1 ! $NV_1080P30 ! $(tee t) ! mix6. \
t. ! queue ! $(overlay_txt a) ! mix6. \

exit 0
qmmf0.video_3 ! $NV_1080P30 ! mix6. \
qmmf0.video_4 ! $NV_1080P30 ! $(overlay_txt b) ! mix6. \
qmmf0.video_5 ! $NV_1080P30 ! mix6.


sleep 1
# 220921 - see 720P-MJ.png, 1080P-MJ.png
# tested: 465r-segfail
export GST_DEBUG=GST_STATES:5,GST_PADS:5,task:5,qtivcomposer:6,aggregator:4 GST_DEBUG_FILE=/data/gst_vcomposer_trim.log GST_DEBUG_NO_COLOR=1

#$GSTAPP $qmmfsrc0 ! $(CAPS_1080P "CAP0") ! $mix0 ! queue ! $(overlay_txt "HDMI") ! $(CAPS_1080P "CAP1") ! $waylandsink \
#qmmf0.video_1 ! $NV_1080P30 ! $(overlay_txt "MMM") ! mix0.

#exit 0
#$GSTAPP $qmmfsrc0 ! $(CAPS_1080P "CAP0") ! queue ! $(overlay_txt "RTSP") ! $(CAPS_1080P "CAP1") ! $omx264 ! $rtsp \
#qmmf0.video_1 ! $NV_1080P30 ! $mix0 ! queue ! $NV_1080P30 ! $waylandsink \
#qmmf0.video_2 ! $NV_1080P30 ! mix0.

$GSTAPP $qmmfsrc0 ! $(CAPS_1080P "CAP0") ! queue ! $(overlay_txt "RTSP") ! $(CAPS_1080P "CAP1") ! $omx264 ! $rtsp \
qmmf0.video_1 ! $(CAPS_1080P "CAP2") ! queue ! $(overlay_txt "JPEG")  ! $(CAPS_1080P "CAP3") ! qtijpegenc ! fakesink \
qmmf0.video_2 ! $NV_1080P30 ! $mix0 ! queue ! $NV_1080P30 ! $waylandsink \
qmmf0.video_3 ! $NV_1080P30 ! mix0.

#qmmf0.video_4 ! $NV_720P5   ! qtivtransform ! jpegenc ! fakesink \

exit 0
# Tee only + queue working
$GSTAPP $qmmfsrc0 ! $NV_1080P30 ! $(tee t) ! queue ! $omx264 ! filesink location="/data/mux.mp4" \
t. ! queue ! waylandsink sync=false fullscreen=true \
t. ! queue ! fakesink \
t. ! queue ! fakesink \
t. ! queue ! fakesink \


# working, but overlay issue, depend on source-index
$GSTAPP \
$qmmfsrc0     ! $NV_1080P30 ! $mix6 ! queue ! $NV_1080P30 ! $waylandsink \
qmmf0.video_1 ! $NV_1080P30 ! mix6. \
qmmf0.video_2 ! $NV_1080P30 ! $(overlay_txt b) ! mix6. \
qmmf0.video_3 ! $NV_1080P30 ! mix6. \
qmmf0.video_4 ! $NV_1080P30 ! $(overlay_txt a) ! mix6. \
qmmf0.video_5 ! $NV_1080P30 ! mix6.


# working, but unstable on VLC streams
$GSTAPP \
$qmmfsrc0     ! $NV_1080P30 ! $(overlay_txt HDMI) ! $mix6 ! queue ! $NV_1080P30 ! $waylandsink \
qmmf0.video_1 ! $NV_1080P30 ! $(overlay_txt RTSP) ! queue ! $omx264 ! $rtsp \
qmmf0.video_2 ! $NV_1080P30 ! $(tee t) ! queue ! mix6. \
t. ! queue ! mix6. \
t. ! queue ! mix6. \
t. ! queue ! mix6.
