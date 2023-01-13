
CFLAGS ?= -g -O0 -pthread -I/usr/include/gstreamer-1.0 -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include -I/usr/lib/x86_64-linux-gnu/gstreamer-1.0/include/
LDFLAGS ?= -lgstreamer-1.0 -lgobject-2.0 -lglib-2.0

all: gst-tester gst-pipeline-app


gst-tester: gst-tester.c key_file.c
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@

gst-pipeline-app: gst-pipeline-app.c
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@
clean:
	rm -f gst-pipeline-app gst-tester
	rm -rf *o key_file
	rm -rf *exe key_file


#GTK_CFLAGS = $(shell pkg-config gtk+-2.0 --cflags)
#GTK_LIBS = $(shell pkg-config gtk+-2.0 --libs)
GTK_CFLAGS = $(CFLAGS) -D__KEY_FILE_DEBUG__
GTK_LIBS = $(LDFLAGS)


key: key_file

key_file: key_file.o
	gcc -o key_file.exe key_file.o $(GTK_LIBS)

key_file.o: key_file.c
	gcc -c key_file.c -o key_file.o $(GTK_CFLAGS)

