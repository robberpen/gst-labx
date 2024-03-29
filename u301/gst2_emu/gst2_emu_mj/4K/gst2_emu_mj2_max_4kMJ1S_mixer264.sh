#!/bin/sh

# 220920 - copied from gst2-latency.sh, format pipeline

export GST_PLAY_DUR=3
export GST_READY_DUR=2
export GST_DEBUG=2
export GST_ROUND=1440
#export GST_DEBUG=qtivcomposer:6

rm -rf   /data/dot
mkdir -p /data/dot
rm -f /data/coredump/*
# export GST_DEBUG_DUMP_DOT_DIR=/data/dot

# element capfilter's name must be "Cap1", "Cap2", "Cap3" ..
# export GST_CAP_NAME=Cap%
export GST_CAP_TOGGLE=1
export GST_CAP_NAME=CAP%
export GST_CAP1="video/x-raw(memory:GBM),format=NV12,width=3840,height=2160,framerate=30/1"
export GST_CAP2="video/x-raw(memory:GBM),format=NV12,width=640,height=360,framerate=30/1"

export XDG_RUNTIME_DIR=/dev/socket/weston
RTSP_SERVER_IP=127.0.0.1


GSTAPP="/data/gst-pipeline-app -e"
qmmfsrc0="qtiqmmfsrc name=qmmf0 camera=0 video_2::source-index=0 video_3::source-index=0 video_4::source-index=0"
qmmfsrc1='qtiqmmfsrc name=qmmf1 camera=1 video_2::source-index=0 video_3::source-index=0 video_4::source-index=0'

mix0='qtivcomposer name=mix0 sink_0::position="<49, 49>" sink_0::dimensions="<658, 370>" sink_1::position="<0, 0>" sink_1::dimensions="<1920, 1080>" latency=200'
mix1='qtivcomposer name=mix1 sink_1::position="<33, 33>" sink_1::dimensions="<439, 246>" sink_0::position="<0, 0>" sink_0::dimensions="<640, 360>" latency=200'
mix2='qtivcomposer name=mix2 sink_1::position="<49, 49>" sink_1::dimensions="<658, 370>" sink_0::position="<0, 0>" sink_0::dimensions="<1920, 1080>" latency=200'

overlay='qtioverlay overlay-bbox="bbox0, bbox=<40, 40, 200, 48>, label=\"Pet\", color=0x0000FFFF;"'

# transform='qtivtransform ! capsfilter caps=\"video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1\" name=RTSP_CAP'

omx264="omxh264enc target-bitrate=4000000 control-rate=2 interval-intraframes=30 max-quant-i-frames=38 max-quant-p-frames=40 ! h264parse config-interval=-1"
# omx264="omxh264enc ! h264parse config-interval=-1"

rtsp="rtph264pay pt=96 ! udpsink host=$RTSP_SERVER_IP port=8554"

# waylandsink='waylandsink fullscreen=true async=false'
waylandsink='waylandsink fullscreen=true  sync=false async=true'

multisink='multifilesink max-files=5 location=/data/frame%d.jpg  next-file=4 max-file-size=400000'

NV_1080P30='video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1'
NV_720P30='video/x-raw(memory:GBM),format=NV12,width=1280,height=720,framerate=30/1'
NV_720P15='video/x-raw,format=NV12,width=1280,height=720,framerate=15/1'
NV_720P5='video/x-raw,format=NV12,width=1280,height=720,framerate=5/1'
AI_TRANS="qtivtransform ! video/x-raw, format=RGB, width=(int)416, height=(int)416, framerate=15/1 ! fakesink"

TransForm1080P()
{
   echo 'qtivtransform ! capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" name='$1
}

CAPS_1080P()
{
   echo 'capsfilter caps="video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" name='$1
}
echo 1 > /sys/class/kgsl/kgsl-3d0/force_rail_on
echo 1 > /sys/class/kgsl/kgsl-3d0/force_clk_on
echo 1 > /sys/class/kgsl/kgsl-3d0/force_bus_on
echo 10000000 > /sys/class/kgsl/kgsl-3d0/idle_timer
echo 0 > /sys/class/kgsl/kgsl-3d0/min_pwrlevel
echo 0 > /sys/class/kgsl/kgsl-3d0/max_pwrlevel
# echo performance > /sys/class/kgsl/kgsl-3d0/devfreq/governor
echo 845000000 > /sys/class/kgsl/kgsl-3d0/gpuclk
echo 845000000 > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
echo 845000000 > /sys/class/kgsl/kgsl-3d0/devfreq/max_freq
echo performance > /sys/class/devfreq/soc:qcom,cpu-llcc-ddr-bw/governor

sleep 1
logcat -c
killall logcat
#logcat > /data/logcat.log &
# 220926 926r - disk full...
# 221021 seems not verify, checking...

# 221027 221028: 1440r debugbuild pass(gstreamer1.0_1.14.4-r0_qcs610_odk_64.ipk,gstreamer1.0-plugins-qti-oss-base-dbg_1.0-r0_aarch64.ipk) \ 
export GST_DEBUG=GST_STATES:5,GST_PADS:5,task:5,qtivcomposer:6,aggregator:4 GST_DEBUG_FILE=/data/gst_vcomposer_trim.log GST_DEBUG_NO_COLOR=1
# based from gst2_emu_mj2_max_4kMJ1S.sh(working case), add mixer
# 221111-gst2_emu_mj2_max_4kMJ1S_mixer.sh-r562-cam-died
# 221112-gst2_emu_mj2_max_4kMJ1S_mixer.sh-r425-cam-died
# 221112-gst2_emu_mj2_max_4kMJ1S_mixer.sh-r316-cam-died
# 221112-gst2_emu_mj2_max_4kMJ1S_mixer264.sh-r1334r-chgfail/
# 221114-gst2_emu_mj2_max_4kMJ1S_mixer264.sh-r404-chgfail
# 221114-gst2_emu_mj2_max_4kMJ1S_mixer264.sh-404r-chgfail
# reclaim images/page-onwer images
#
# 221116-gst2_emu_mj2_max_4kMJ1S_mixer264.sh-pass/
# 221117-gst2_emu_mj2_max_4kMJ1S_mixer264.sh-pass/
# 221117-gst2_emu_mj2_max_4kMJ1S_mixer264.sh-pass2
# 221124 update 1124_oom_seg_perf image
# 221126-gst2_emu_mj2_max_4kMJ1S_mixer264.sh-pass
$GSTAPP \
$qmmfsrc0 ! $(CAPS_1080P "CAP0") ! $mix1 ! queue ! $overlay   ! $(CAPS_1080P "CAP1") ! $omx264 ! fakesink \
$qmmfsrc1 ! $(CAPS_1080P "CAP2") ! mix1.

killall logcat
