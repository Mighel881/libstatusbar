TARGET = iphone:9.2
ARCHS = armv7 arm64

CFLAGS = -O2 

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = libstatusbar
libstatusbar_FILES = $(wildcard *.xm) $(wildcard *.mm)
libstatusbar_FRAMEWORKS = UIKit
libstatusbar_PRIVATE_FRAMEWORKS = AppSupport
libstatusbar_LIBRARIES = rocketbootstrap

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
