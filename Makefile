all: compile

update-me:
	@git pull

update: update-me

compile:
	xcodebuild -project pinentry-mac.xcodeproj -target pinentry-mac -configuration Release build

test: compile
	@echo "nothing to test"

clean-pinentry-mac:
	xcodebuild -project pinentry-mac.xcodeproj -target pinentry-mac -configuration Release clean > /dev/null
	xcodebuild -project pinentry-mac.xcodeproj -target pinentry-mac -configuration Debug clean > /dev/null

clean: clean-pinentry-mac
