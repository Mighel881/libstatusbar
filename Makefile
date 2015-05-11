ARCHS = armv7 armv7s arm64

CFLAGS = -fobjc-arc
TARGET=iphone:clang:8.1:7.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = libstatusbar
libstatusbar_FILES = libstatusbar.xm LibStatusBar8.mm \
	LSStatusBarItem.mm LSStatusBarClient.xm LSStatusBarServer.mm \
	UIStatusBarCustomItem.xm UIStatusBarCustomItemView.xm \
	UIStatusBarTimeItemView.xm

libstatusbar_FRAMEWORKS = UIKit
libstatusbar_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
