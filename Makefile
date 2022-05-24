# 20210716 peter
# 210820 - update
# 211203 - update
# (make weston &);sleep 30;(make preview &);sleep 30;adb reboot
WAYLAND_DEBUG?=0
build_dir=/media/peter/Dockers/QCS610_r119/qcs610-le-1-0_ap_standard_oem-r00119.2-ef6233c298dfa074d01f96a739663c242fe56bb6/apps_proc/build-qti-distro-fullstack-debug/tmp-glibc/
GST_DEBUG=?0
help:
	@echo "disable	- prepare remount filesystem"
	@echo "remount	- remount filesystem"
	@echo "weston	- start weston, eg, make weston WAYLAND_DEBUG=2"
	@echo "playback	- start playback, eg, make playback WAYLAND_DEBUG=2"
	@echo "preview	- start preview, eg, make preview WAYLAND_DEBUG=2 GST_DEBUG=qtiqmmfsrc:7"
	@echo "trace_run - audo capture systrace log"
	@echo "dot_cmd	f=<cmd>	- Gen dot where gst command from \$$f, eg, make dot_cmd f=cmd"
	@echo "kill_gst - kill gst"
	@echo "mjpeg_4k30_720p30 mjpeg_1080p  WAYLAND_DEBUG=1  GST_DEBUG=qtiqmmfsrc:6"
remount:
	#adb disable-verity
	adb root
	sleep 3
	adb shell mount -o remount,rw /
disable_verify:
	adb root
	adb disable-verity
	adb reboot
upload:
	#cp /media/peter/Dockers/QCS610_r119/qcs610-le-1-0_ap_standard_oem-r00119.2-ef6233c298dfa074d01f96a739663c242fe56bb6/apps_proc/build-qti-distro-fullstack-debug/tmp-glibc/work/aarch64-oe-linux/wayland/1.9.0-r0/build/.libs/libwayland-client.so.0.3.0 libwayland-client.so.0.3.0.master
	#sudo adb push libwayland-client.so.0.3.0.master /usr/lib/libwayland-client.so.0.3.0
	#cp /media/peter/Dockers/QCS610_r119/qcs610-le-1-0_ap_standard_oem-r00119.2-ef6233c298dfa074d01f96a739663c242fe56bb6/apps_proc/build-qti-distro-fullstack-debug/tmp-glibc/work/aarch64-oe-linux/wayland/1.9.0-r0/build/.libs/libwayland-server.so.0.1.0  libwayland-server.so.0.1.0.master
	#sudo adb push libwayland-server.so.0.1.0.master /usr/lib/libwayland-server.so.0.1.0
	cp  $(build_dir)/tmp-glibc/work/aarch64-oe-linux/weston/1.9.0-r0/build/.libs/drm-backend.so drm-backend.so.master 
	sudo adb push drm-backend.so.master /usr/lib/weston/drm-backend.so
	cp $(build_dir)/tmp-glibc/work/aarch64-oe-linux/weston/1.9.0-r0/build/weston westen.master
	sudo adb push  westen.master /usr/bin/weston

weston:
	adb root
	sleep 6
	#sudo adb shell "XDG_RUNTIME_DIR=/dev/socket/weston WAYLAND_DEBUG=$(WAYLAND_DEBUG) weston --tty=1 --device=hdmi --idle-time=0" &
	adb shell "XDG_RUNTIME_DIR=/dev/socket/weston WAYLAND_DEBUG=$(WAYLAND_DEBUG) weston --tty=1 --device=hdmi --idle-time=0" &
	#adb shell "XDG_RUNTIME_DIR=/dev/socket/weston weston --tty=1 --device==displaydummy --idle-time=0" &

playback: kill_gst
	sudo adb shell "XDG_RUNTIME_DIR=/dev/socket/weston \
	WAYLAND_DEBUG=$(WAYLAND_DEBUG) GST_DEBUG=$(GST_DEBUG) \
	gst-launch-1.0 -e filesrc location=/data/mux_avc.mp4 ! \
	qtdemux name=demux demux. ! queue ! h264parse ! qtivdec ! \
	video/x-raw\(memory:GBM\),compression=ubwc ! \
	waylandsink fullscreen=true 2>&1" |tee wayland.master.log

preview:
	adb shell 'XDG_RUNTIME_DIR=/dev/socket/weston \
	gst-launch-1.0 -e qtiqmmfsrc name=qmmf ! \
	"video/x-raw(memory:GBM),format=NV12,camera=0,width=1920,height=1080,framerate=30/1" ! \
	waylandsink sync=false fullscreen=true'
preview.orig: kill_gst
	sudo adb shell 'XDG_RUNTIME_DIR=/dev/socket/weston \
	WAYLAND_DEBUG=$(WAYLAND_DEBUG) GST_DEBUG=$(GST_DEBUG) \
	gst-launch-1.0 -e qtiqmmfsrc name=qmmf ! \
	"video/x-raw(memory:GBM),format=NV12,camera=0,width=1920,height=1080,framerate=30/1" ! \
	waylandsink sync=false fullscreen=true'

preview_720p: kill_gst
	sudo adb shell 'XDG_RUNTIME_DIR=/dev/socket/weston \
	WAYLAND_DEBUG=$(WAYLAND_DEBUG) GST_DEBUG=$(GST_DEBUG) \
	gst-launch-1.0 -e qtiqmmfsrc name=qmmf ! \
	"video/x-raw(memory:GBM),format=NV12,camera=0,width=1280,height=720,framerate=30/1" ! \
	waylandsink sync=false fullscreen=true'


preview_zoom:kill_gst
	sudo adb shell 'XDG_RUNTIME_DIR=/dev/socket/weston \
	WAYLAND_DEBUG=$(WAYLAND_DEBUG) GST_DEBUG=$(GST_DEBUG) \
	gst-launch-1.0 -e qtiqmmfsrc zoom=\<0,0,640,480\> name=qmmf ! \
	"video/x-raw(memory:GBM),format=NV12,camera=0,width=1920,height=1080,framerate=30/1" ! \
	waylandsink sync=false fullscreen=true'

omx264_zoom: kill_gst
	sudo adb shell 'XDG_RUNTIME_DIR=/dev/socket/weston \
	WAYLAND_DEBUG=$(WAYLAND_DEBUG) GST_DEBUG=$(GST_DEBUG) \
	gst-launch-1.0 -e qtiqmmfsrc zoom=\<0,0,640,480\> ! video/x-raw\(memory:GBM\),format=NV12,width=1920,height=1080,framerate=30/1 \
	! queue ! omxh264enc ! \
	h264parse ! mp4mux ! filesink location="/data/mux_avc.mp4"'
omx264: kill_gst
	sudo adb shell 'XDG_RUNTIME_DIR=/dev/socket/weston \
	WAYLAND_DEBUG=$(WAYLAND_DEBUG) GST_DEBUG=$(GST_DEBUG) \
	gst-launch-1.0 -e qtiqmmfsrc ! video/x-raw\(memory:GBM\),format=NV12,width=1920,height=1080,framerate=30/1 \
	! queue ! omxh264enc ! \
	h264parse ! mp4mux ! filesink location="/data/mux_avc.mp4"'
omx264_orig:
	sudo adb shell 'XDG_RUNTIME_DIR=/dev/socket/weston \
	WAYLAND_DEBUG=$(WAYLAND_DEBUG) GST_DEBUG=$(GST_DEBUG) \
	gst-launch-1.0 -e qtiqmmfsrc ! video/x-raw\(memory:GBM\),format=NV12,width=1920,height=1080,framerate=30/1 \
	! queue ! omxh264enc control-rate=max-bitrate interval-intraframes=29 periodicity-idr=1 ! \
	queue ! h264parse ! mp4mux ! queue ! filesink location="/data/mux_avc.mp4"'

omx264_r126: kill_gst
	gst-launch-1.0 -e qtiqmmfsrc ! \
	video/x-raw\(memory:GBM\),format=NV12,width=1920,height=1080,framerate=30/1 ! \
	omxh264enc target-bitrate=32000000 control-rate=2 interval-intraframes=299 ! \
	h264parse ! mp4mux ! queue ! filesink location="/data/mux.mp4"

omx264_1440p: kill_gst
	sudo adb shell 'XDG_RUNTIME_DIR=/dev/socket/weston \
	WAYLAND_DEBUG=$(WAYLAND_DEBUG) GST_DEBUG=$(GST_DEBUG) \
	gst-launch-1.0 -e qtiqmmfsrc ! \
	video/x-raw\(memory:GBM\),format=NV12,width=2560,height=1440,framerate=30/1 ! \
	omxh264enc ! \
	h264parse ! mp4mux ! queue ! filesink location="/data/mux.mp4"'

mjpeg_1080p: kill_gst
	sudo adb shell 'XDG_RUNTIME_DIR=/dev/socket/weston \
	WAYLAND_DEBUG=$(WAYLAND_DEBUG) GST_DEBUG=$(GST_DEBUG) \
	gst-launch-1.0 -e qtiqmmfsrc name=qmmf image_1::mode=continuous image_1::quality=100 ! \
	"video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! \
	fakesink qmmf. ! "image/jpeg, width=1920, height=1080, framerate=30/1" ! \
	queue ! avimux ! filesink location=/data/mjpeg.avi sync=true async=false'

mjpeg_1080p_zoom: kill_gst
	sudo adb shell 'XDG_RUNTIME_DIR=/dev/socket/weston \
	WAYLAND_DEBUG=$(WAYLAND_DEBUG) GST_DEBUG=$(GST_DEBUG) \
	gst-launch-1.0 -e qtiqmmfsrc zoom=\<0,0,640,480\> name=qmmf image_1::mode=continuous image_1::quality=100 ! \
	"video/x-raw(memory:GBM),format=NV12,width=1920,height=1080,framerate=30/1" ! \
	fakesink qmmf. ! "image/jpeg, width=1920, height=1080, framerate=30/1" ! \
	queue ! avimux ! filesink location=/data/mjpeg.avi sync=true async=false'

mjpeg_4k30_720p30:
	sudo adb shell 'XDG_RUNTIME_DIR=/dev/socket/weston \
	WAYLAND_DEBUG=$(WAYLAND_DEBUG) GST_DEBUG=$(GST_DEBUG) \
	gst-launch-1.0 -e qtiqmmfsrc ! \
	image/jpeg,format=NV12,width=3840,height=2160,framerate=30/1 ! \
	avimux ! queue ! filesink location="/data/mux_4k.mp4" sync=true async=false'

.PHONE: logcat

logcat:
	adb logcat -c;adb shell "timeout -t 20 -s INT logcat > /data/logcat.mk.log"
	#adb logcat -c;adb shell "timeout -t 90 -s INT logcat |tee /data/logcat.mk.log|grep PTM"
	adb pull /data/logcat.mk.log

test_trap:
	trap "echo ptm"; cat 


trace_en__:
	#adb shell "echo 1 > sys/kernel/debug/tracing/events/sched/enable"
	adb shell "echo 1 >/sys/kernel/debug/tracing/tracing_on"
	sleep 1
	adb shell "echo 1 > sys/kernel/debug/tracing/events/sde/enable"
	adb shell "echo 1 > sys/kernel/debug/tracing/events/kgsl/enable"

trace_dis__:
	adb shell "echo 0 >/sys/kernel/debug/tracing/tracing_on"
	sleep 1
	adb shell "echo 0 > sys/kernel/debug/tracing/events/sde/enable"
	adb shell "echo 0 > sys/kernel/debug/tracing/events/kgsl/enable"
	@echo "make sure messages queue empty"
	adb shell "timeout -t 2 -s INT cat /sys/kernel/debug/tracing/trace_pipe > /dev/null"

trace_reset: trace_dis__ trace_en__

trace_run__:
	adb shell "timeout -t 90 -s INT cat /sys/kernel/debug/tracing/trace_pipe > /data/trace.txt"
	sleep 1
	adb pull /data/trace.txt ./trace$(shell date +%y%m%d).txt
	cp ./trace$(shell date +%y%m%d).txt /tmp/

__sleep:
	sleep 1

trace_run: trace_reset __sleep trace_run__

__dot:
	adb shell killall gst-launch-1.0
	adb shell mkdir -p /data/dot/
	sleep 3

dot_cmd_preview: __dot
	adb shell GST_DEBUG_DUMP_DOT_DIR=/data/dot XDG_RUNTIME_DIR=/dev/socket/weston \
	gst-launch-1.0 -e qtiqmmfsrc name=qmmf ! \
	"video/x-raw(memory:GBM),format=NV12,camera=0,width=1920,height=1080,framerate=30/1" ! \
	qtioverlay overlay-text="Qualcomm Intelligence" ! waylandsink sync=false fullscreen=true

dot_cmd_omx264: __dot
	adb shell GST_DEBUG_DUMP_DOT_DIR=/data/dot XDG_RUNTIME_DIR=/dev/socket/weston \
	gst-launch-1.0  -e qtiqmmfsrc name=qmmf camera=0 ! \
		       "video/x-raw, format=NV12,width=1920,height=1080,framerate=30/1" ! \
		       omxh264enc target-bitrate=50000000 control-rate=2 interval-intraframes=150 ! \
		       "video/x-h264,profile=(string)baseline, level=(string)4.1" ! \
		       h264parse ! mp4mux ! queue ! filesink location="/data/mux.mp4"
dot_cmd: __dot
	cmd=`cat $$f`; adb shell "GST_DEBUG_DUMP_DOT_DIR=/data/dot  XDG_RUNTIME_DIR=/dev/socket/weston  $${cmd}"

# stop with SIGINT to exit otherwise recording omx264 will abnormal.
kill_gst:
	adb shell killall -INT gst-launch-1.0
	sleep 1
	adb shell killall -INT gst-pipeline-app
	sleep 1

dot_pull:
	adb shell "ls --color=never /data/dot/*PLAYING.dot"|tr -d '\r'| while read f;\
	do \
		adb pull "$$f";\
		dot -Tpng $$(filename $$f) -o  /tmp/$$(filename $$f).png ;\
	done


usecase:
	adb logcat -c;adb logcat |grep -v audio| tee usecase.log| \
		grep chxadvancedcamerausecase.cpp | \
		grep -e Initialize -e PipelineCreated |cut -d ' ' -f 12-
