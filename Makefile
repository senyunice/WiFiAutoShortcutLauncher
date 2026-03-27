THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222

ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = WiFiAutoShortcutLauncher
$(TWEAK_NAME)_FILES = \
	Tweak.x \
	RootViewController.mm \
	WiFiRuleCell.mm \
	SchedulePickerViewController.mm \
	WiFiWatcher.mm \
	ShortcutsRunner.mm \
	WIFIRule.mm \
	ScheduleManager.mm \
	ConfigManager.mm

$(TWEAK_NAME)_OBJCXX_FILES = $(filter %.mm, $($(TWEAK_NAME)_FILES))
$(TWEAK_NAME)_FRAMEWORKS = UIKit Foundation Preferences UserNotifications
$(TWEAK_NAME)_PRIVATE_FRAMEWORKS = Preferences

# 添加本地entitlements
$(TWEAK_NAME)_ENTITLEMENTS = WiFiAutoShortcutLauncher.entitlements

include $(THEOS)/makefiles/tweak.mk
include $(THEOS)/makefiles/rules.mk

after-install::
	install.exec "killall -9 SpringBoard"
