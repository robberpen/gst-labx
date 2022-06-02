
d:=$(shell date +'%Y-%m-%d-%H-%M')

t?=120

logcat_t0:=$(shell if [ $t -gt 120 ];then echo 120;else echo $t;fi)
run="/data/gst-b2"


gst-b2_help:
	@echo "init_once		# upload  test script"
	@echo "init_after_reboot	# init rtsp server"
	@echo "run_it run=\"/data/gst-b2\" t=43200	# run /data/gst-b2 12hr"
	@echo "logcat_t0: \"$(logcat_t0)\""
	@echo  "fail_log_get d=<DIR>	# download log if fail"

rtsp_server:
	adb root
	sleep 3
	adb forward tcp:8900 tcp:8900
	adb shell "gst-rtsp-server -p 8900 -m /live \"( udpsrc name=pay0 port=8554 caps=\"application/x-rtp,media=video,clock-rate=90000,encoding-name=H264,payload=96\" )\"" &
	sleep 3
	adb shell "ps auxw|grep rtsp"
	adb forward --list

upload_files:
	adb push gst-a /data/
	adb push gst-a1 /data/
	adb push gst-a2 /data/
	adb push gst-a3 /data/
	adb push gst-a1.1 /data/
	adb push gst-b1 /data/
	adb push gst-b2 /data/
	adb push gst-b3 /data/
	adb push gst-c1 /data/
	adb push gst-c2.1 /data/
	adb push gst-c2.2 /data/
	adb push gst-c2.2.1 /data/
	adb push gst-c2.2.2 /data/
	adb push gst-c2.2.3 /data/
	adb push gst-c2.3 /data/
	adb push gst-c2.4 /data/
	adb push gst-c3 /data/
	adb push gst-c3.1 /data/
	adb push gst-d1 /data/
	adb push gst-a /data/
	adb push memleak.sh /data/
	adb push gst-event /data/
	adb push logcat.sh /data/
	adb push gst-pipeline-app  /data/
dot_get:
	sleep 30
	adb shell "ls --color=never /data/dot/*PLAYING.dot"|tr -d '\r'| while read f;\
	do \
		adb pull "$$f";\
		dot -Tpng $$(filename $$f) -o  $d/$$(filename $$f).png ;\
	done
#split -l 1000000 -  logcat   --numeric-suffixes=0 -a 1 --additional-suffix=.log
# Selected Usecase to get playing stat
run_it:
	@adb root;sleep 5; mkdir $d
	adb shell "rm /data/gst.GST_STATE_PLAYING*"
	adb shell "rm /data/*.pid"
	adb shell "rm /data/coredump/*"
	adb shell rm /data/gst-event.log
	adb logcat -c;adb shell "timeout -t $(logcat_t0) -s INT logcat > /data/logcat.mk.log" &
	#adb shell "$(run)"  > $d/runit.log &
	adb shell "$(run)" | split -l 200000 -  $d/logcat   --numeric-suffixes=0 -a 3 --additional-suffix=.log &
	adb shell "timeout -t $t -s INT /data/memleak.sh" |tee $d/memleak.log &
	adb shell "timeout -t $t -s INT logcat |grep \"frame_num = 450\"" > $d/frame_num.log &
	adb pull $(run) $d/
	#adb shell /data/logcat.sh &
	cp gst-b2.mk $d/
	echo "run $(run) $t sec" >  $d/run.time
	sleep $t
	#adb pull  /data/logcat.round.log $d/
	adb shell killall gst-pipeline-app
	adb pull /data/logcat.mk.log $d/logcat.mk.log
	-adb pull /data/gst.GST_STATE_PLAYING-last.log $d/
	-adb pull /data/gst.GST_STATE_PLAYING.log $d/
	-adb pull /data/gst.GST_STATE_PLAYING.dmesg $d
	-adb pull /data/gst.GST_STATE_PLAYING-last.dmesg $d
	-adb pull /data/gst-event.log $d/

fail_log_get:
	#[ -d "$d" ] || (echo use $@ d=<dir>; exit 1)
	[ -d "$d" ] || (echo "use $@ d=<dir>";exit 1)
	adb pull /data/logcat.mk.log $d/logcat.mk.log
	-adb pull /data/gst.GST_STATE_PLAYING-last.log $d/
	-adb pull /data/gst.GST_STATE_PLAYING.log $d/
	-adb pull /data/gst.GST_STATE_PLAYING.dmesg $d/
	-adb pull /data/gst.GST_STATE_PLAYING-last.dmesg $d/
	-adb pull /data/gst-event.log $d/
	-adb pull /data/coredump/ $d/

vlc:
	while true; do date; mpv rtsp://127.0.0.1:8900/live; echo "respwan"; sleep 10;done

init_after_reboot: rtsp_server
init_once: upload_files

# Two use case in gst-c2.2.3
#
#   $grep -e ProcessRequest logcat.mk.log|grep 'chiFrameNum: 333'
#
# 2022-05-29-04-02-gst-c2.2.3-10hr-vlc-ok $ grep -e ProcessRequest logcat.mk.log|grep 'chiFrameNum: 333'
# 02-07 06:14:34.727  2474  3342 E CamX    : [REQMAP][CORE   ] camxsession.cpp:2660 ProcessRequest() chiFrameNum: 333  <==>  requestId: 334  <==>  sequenceId: 333  <==> CSLSyncId: 334  -- Preview_0
# 02-07 06:14:34.768  2474  3344 E CamX    : [REQMAP][CORE   ] camxsession.cpp:2660 ProcessRequest() chiFrameNum: 333  <==>  requestId: 334  <==>  sequenceId: 333  <==> CSLSyncId: 334  -- OfflineYUVTOJPEG_0
#
#
# Sensor mode 
#   $ cat logcat.mk.log|grep 'Selected Usecase'
#
#   02-07 06:15:13.843  2530  2530 E CHIUSECASE: [CONFIG ] chxsensorselectmode.cpp:626 FindBestSensorMode() Selected Usecase: 7, SelectedMode W=1920, H=1084, FPS:90, NumBatchedFrames:0, modeIndex:7
#
#
# trace thread:
# /data # ps -T|grep pipeline-app|wc -l
# 23
#
#  $ grep 'wait for output buffer return timed out' * -rB1
#
#  logcat.log-01-26 07:58:54.473  2954  7433 D QC_CORE : OMXCORE: qc_omx_component_fill_this_buffer 0x7f7c0138c8, 0x7f94018000
#  logcat.log:01-26 07:58:55.160  2588  7410 E Camera3Stream: GetBuffer: wait for output buffer return timed out
#  --
#  logcat.log-01-26 07:58:55.160  2588  7410 W RecorderCameraContext: CameraErrorCb: Frame 13 returned with error! Notify all threads waiting for pending frames!!
#  logcat.log:01-26 07:58:56.161  2588  7410 E Camera3Stream: GetBuffer: wait for output buffer return timed out
#  --
#  logcat.log-01-26 07:58:56.161  2588  7410 W RecorderCameraContext: CameraErrorCb: Frame 14 returned with error! Notify all threads waiting for pending frames!!
#  logcat.log:01-26 07:58:57.161  2588  7410 E Camera3Stream: GetBuffer: wait for output buffer return timed out
#
