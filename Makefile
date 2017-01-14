TARGET = iphone:9.2
ARCHS = armv7 arm64

CFLAGS = -O2 -fobjc-arc

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = libstatusbar
libstatusbar_FILES = $(wildcard *.xm) $(wildcard *.mm)
libstatusbar_FRAMEWORKS = UIKit
libstatusbar_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
