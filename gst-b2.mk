
d:=$(shell date +'%Y-%m-%d-%H-%M')

t?=120

logcat_t0:=$(shell if [ $t -gt 120 ];then echo 120;else echo $t;fi)
run="/data/gst-b2"


gst-b2_help:
	@echo "init_once		# upload  test script"
	@echo "init_after_reboot	# init rtsp server"
	@echo "run_it run=\"/data/gst-b2\" t=43200	# run /data/gst-b2 12hr"
	@echo "logcat_t0: \"$(logcat_t0)\""

rtsp_server:
	adb root
	sleep 3
	adb forward tcp:8900 tcp:8900
	adb shell "gst-rtsp-server -p 8900 -m /live \"( udpsrc name=pay0 port=8554 caps=\"application/x-rtp,media=video,clock-rate=90000,encoding-name=H264,payload=96\" )\"" &
	sleep 3
	adb shell "ps auxw|grep rtsp"
	adb forward --list

upload_files:
	adb push gst-b1 /data/
	adb push gst-b2 /data/
	adb push gst-b3 /data/
	adb push gst-c2.1 /data/
	adb push gst-c2.2 /data/
	adb push gst-c2.2.1 /data/
	adb push gst-c2.3 /data/
	adb push gst-c2.4 /data/
	adb push gst-c3 /data/
	adb push gst-c3.1 /data/
	adb push gst-d1 /data/
	adb push gst-a /data/
	adb push memleak.sh /data/
	adb push logcat.sh /data/
	adb push gst-pipeline-app  /data/
dot_get:
	sleep 30
	adb shell "ls --color=never /data/dot/*PLAYING.dot"|tr -d '\r'| while read f;\
	do \
		adb pull "$$f";\
		dot -Tpng $$(filename $$f) -o  $d/$$(filename $$f).png ;\
	done

# Selected Usecase to get playing stat
run_it:
	@adb root;sleep 5; mkdir $d
	adb logcat -c;adb shell "timeout -t $(logcat_t0) -s INT logcat > /data/logcat.mk.log" &
	adb shell "$(run)"  > $d/runit.log &
	adb shell "timeout -t $t -s INT /data/memleak.sh" |tee $d/memleak.log &
	adb shell "timeout -t $t -s INT logcat |grep \"frame_num = 900\"" > $d/frame_num.log &
	adb pull $(run) $d/
	#adb shell /data/logcat.sh &
	cp gst-b2.mk $d/
	echo "run $(run) $t sec" >  $d/run.time
	sleep $t
	#adb pull  /data/logcat.round.log $d/
	adb shell killall gst-pipeline-app
	adb pull /data/logcat.mk.log $d/logcat.mk.log

vlc:
	while true; do date; mpv rtsp://127.0.0.1:8900/live; echo "respwan"; sleep 10;done

init_after_reboot: rtsp_server
init_once: upload_files
