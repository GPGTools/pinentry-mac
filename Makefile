PROJECT = pinentry-mac
TARGET = pinentry-mac
CONFIG = Release

include Dependencies/GPGTools_Core/make/default

all: compile

update-core:
	@cd Dependencies/GPGTools_Core; git pull origin master; cd -
update-me:
	@git pull origin master

update: update-me update-core

compile:
	@xcodebuild -project $(PROJECT).xcodeproj -target $(TARGET) -configuration $(CONFIG) build

compile_with_ppc:
	@xcodebuild -project $(PROJECT).xcodeproj -target $(TARGET) -configuration "$(CONFIG) with ppc" build

clean:
	@xcodebuild -project $(PROJECT).xcodeproj -target $(TARGET) -configuration $(CONFIG) clean > /dev/null

test: compile
	@echo "nothing to test"

init:
