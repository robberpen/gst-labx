
include upload.inc
# TF: Target file name
TF ?=$(shell filename $T)
# TP: path/dir of target file
TP ?=$(shell dirname $T)

#T=$(TP)/$(TF)
ORIG_DIR=orig
SO=SO
help lib_upload_help:
	@echo "init_once	: backup orignal file and get md5sum"
	@echo "unlock_rw	: adb disable-verity"
	@echo "remount		: adb shell mount -o remount,rw /"
	@echo "upload		: adb push $(TF) $T"
	@echo "init_oncex	: multiple .so back and md5sum, eg: make -f upload.mk init_oncex SO=SO/"
	@echo "uploadx		: multiple .so to /usr/lib, eg: make -f upload.mk uploadx SO=SO/"
	@echo "rollback		: adb push $(ORIG_DIR)/$(TF) $T"
	@echo "for example: make -f upload.mk init_once T=/usr/lib/camera/components/com.qti.offline.jpeg.so"
	@echo "for example: make -f upload.mk upload T=/usr/lib/camera/components/com.qti.offline.jpeg.so"
info:
	@echo "T:$T"
	@echo "TP:$(TP)"
	@echo "TF:$(TF)"

# back up orignal file
init_once:
	mkdir -p $(ORIG_DIR)
	@if [ -f "$(ORIG_DIR)/$(TF)" ];then \
		echo "$(ORIG_DIR)/$(TF) already exist"; \
	else \
		adb pull $T $(ORIG_DIR)/$(TF);	\
		md5sum $(ORIG_DIR)/$(TF) > $(ORIG_DIR)/$(TF).md5sum;\
		md5sum -c  $(ORIG_DIR)/$(TF).md5sum;\
	fi
	md5sum $(TF) > $(TF).md5sum
	#@md5sum -c  $(TF).md5sum

unlock_rw:
	sudo adb root;sleep 10;
	adb disable-verity; adb reboot; sleep 10
remount:
	@sudo adb root; sleep 5
	@adb shell mount -o remount,rw /
	@sleep 3
md5sum:
	sudo adb shell md5sum $(T)
	md5sum $(ORIG_DIR)/$(TF)
	md5sum $(TF)
__upload:
	@adb push $(TF) $T
	@echo "make sure md5 is same"
	@adb shell md5sum $(T)
	@cat $(TF).md5sum
	@echo "Might need reboot; adb reboot;sleep 10;adb root"

upload: remount  __upload

init_oncex:
	find "$(SO)/" -name "*.so" | while read x; do \
		b=$$(basename $$x); echo $$b;	\
		t=$$(adb shell find /usr/lib -name $$b |tr -d '\r') ;\
		echo "$$b at $$t"; \
		if [ "$$t" = "" ] ;then echo "Not found"; continue; fi;\
		adb shell find /usr/lib/ -name $$b | tr -d '\r' | xargs -i adb pull {} $$x.orig; \
		md5sum $$x.orig > $$x.orig.md5sum; \
	done

uploadx:
	find $(SO) -name "*.so" | while read x; do \
		b=$$(basename $$x); \
		t=$$(adb shell find /usr/lib -name $$b |tr -d '\r') ;\
		echo "$$b at $$t"; \
		if [ "$$t" = "" ] ;then echo "Not found"; continue; fi;\
		adb push $$x $$t ;\
		md5sum $$x > $$x.md5sum ;\
	done
		#adb shell find /usr/lib/ -name $$b || echo $$b no found && continue; | tr -d '\r' | xargs -i echo adb push $$x  {}; \
		#md5sum $$x > $$x.md5sum;	\
		#
__rollback:
	adb push $(ORIG_DIR)/$(TF) $T
	adb shell md5sum $(T)
	cat $(ORIG_DIR)/$(TF).md5sum;
	@echo "make sure md5 is same"
	@echo "Might need reboot; adb reboot;sleep 10;adb root"
	
rollback: remount __rollback
	

