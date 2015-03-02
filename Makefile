PROJECT = pinentry-mac
TARGET = pinentry-mac
PRODUCT = build/Release/pinentry-mac.app/Contents/MacOS/pinentry-mac
CONFIG = Release

all: $(PRODUCT)

$(PRODUCT): Source/* Source/pinentry-current/* Source/pinentry-current/*/* Resources/* Resources/*/* pinentry-mac.xcodeproj
	xcodebuild -project $(PROJECT).xcodeproj -target $(TARGET) -configuration $(CONFIG) build $(XCCONFIG)

clean:
	rm -rf ./build
