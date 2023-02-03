--- Files

gst-tester - prebuild executable ELF based on gst-pipeline-app
test.ini   - gst-tester read .ini for runtime change GST BIN(element)
gst-tester-demo.sh - example script.

--- How to test on U301.
1. copy gst-tester test.ini gst-tester-demo.sh to /data/
2. startup weston to HDMI.

  $ export XDG_RUNTIME_DIR=/dev/socket/weston
  $ weston --tty=1 --device=hdmi --idle-time=0 &

3. run script
  $ ./gst-tester-demo.sh

4. Now, We can see "qtivtransform flip-vertical=1" and "qtivtransform flip-vertical=0" was swap each iterator based on test.ini
  $ cat test.init
    ...
  element1=qtivtransform flip-vertical=1 ! waylandsink fullscreen=true sync=false async=true
  element2=qtivtransform flip-vertical=0 ! waylandsink fullscreen=true sync=false async=true

  And also codec "fakesink name=democodec" changed JPEG,OMX264 as well, see test.ini

--- How to configure test.ini ---

Below test.ini, Where keyword
  demosink - mapping element name we want to replace, in this case is fakesink
  parent   - mapping to the parent element we want to replace, in this case is queue
  elementX - mapping to each iteration we want to change
             In this case. BIN element1, element2 linked to "queue name=tester1" each time iteration.

  $ cat test.init
  [demosink]
  parent=tester1
  element1=qtivtransform flip-vertical=1 ! waylandsink fullscreen=true sync=false async=true
  element2=qtivtransform flip-vertical=0 ! waylandsink fullscreen=true sync=false async=true

  $ cat  cat gst-tester-demo.sh
  ...
  qmmf0.video_2 ! $NV_1080P30 ! queue ! videorate ! $FPS_CAPS ! queue name=tester1 ! fakesink name=demosink
  
