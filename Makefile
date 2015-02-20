PROJECT = pinentry-mac
TARGET = pinentry-mac
PRODUCT = pinentry-mac.app
CONFIG = Release

all: $(PRODUCT)

$(PRODUCT): *.m pinentry-mac.xcodeproj
	@xcodebuild -project $(PROJECT).xcodeproj -target $(TARGET) -configuration $(CONFIG) build $(XCCONFIG)

clean:
	rm -rf ./build
