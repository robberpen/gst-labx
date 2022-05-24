
include upload.inc
# TF: Target file name
TF ?=$(shell filename $T)
# TP: path/dir of target file
TP ?=$(shell dirname $T)

#T=$(TP)/$(TF)
ORIG_DIR=orig

help lib_upload_help:
	@echo "init_once	: backup orignal file and get md5sum"
	@echo "unlock_rw	: adb disable-verity"
	@echo "remount		: adb shell mount -o remount,rw /"
	@echo "upload		: adb push $(TF) $T"
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

__rollback:
	adb push $(ORIG_DIR)/$(TF) $T
	adb shell md5sum $(T)
	cat $(ORIG_DIR)/$(TF).md5sum;
	@echo "make sure md5 is same"
	@echo "Might need reboot; adb reboot;sleep 10;adb root"
	
rollback: remount __rollback
	

