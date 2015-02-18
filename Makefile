PROJECT = pinentry-mac
TARGET = pinentry-mac
PRODUCT = pinentry-mac.app
CONFIG = Release
MAKE_DEFAULT = Dependencies/GPGTools_Core/newBuildSystem/Makefile.default

-include $(MAKE_DEFAULT)

.PRECIOUS: $(MAKE_DEFAULT)
$(MAKE_DEFAULT):
	ruby "checksum.rb"

init: $(MAKE_DEFAULT)

$(PRODUCT): *.m pinentry-mac.xcodeproj
	@xcodebuild -project $(PROJECT).xcodeproj -target $(TARGET) -configuration $(CONFIG) build $(XCCONFIG)

compile_with_ppc:
	@xcodebuild -project $(PROJECT).xcodeproj -target $(TARGET) -configuration "$(CONFIG) with ppc" build $(XCCONFIG)

