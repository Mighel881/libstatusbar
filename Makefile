TARGET = iphone:9.2
ARCHS = armv7 arm64

#TARGET=iphone:clang:8.1:7.0
CFLAGS = -O2

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = libstatusbar
libstatusbar_FILES = $(wildcard *.xm) $(wildcard *.mm)
libstatusbar_FRAMEWORKS = UIKit
libstatusbar_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
