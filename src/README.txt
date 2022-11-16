1. Setup
cp gst-pipeline-app to /data/
cp gst-event to /data/
cp ../utils/utils.sh /data/
chmod +x /data/gst-pipeline-app /data/gst-event /data/utils.sh

2. Run gst-pipeline-app

  $ cd /data/

	Initial HDMI weston

  $ ./utils.sh

	Run script, ie

  $ ./gst2_emu_mj2_max_4kMJ1S_mixer_fakesink.sh


3. Get information

  a) gst-pipeline-app will exec /data/gst-event each iteration on status change.
     We can easier to collect infomation such as "free" command on gst-event

  b) gst-pipeline-app will dump dot pipeline graphic on /data/dot if "export GST_DEBUG_DUMP_DOT_DIR=/data/dot" is set

  c) by default gst-event, will save log to /data/gst-event.log
