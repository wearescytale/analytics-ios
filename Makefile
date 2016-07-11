SDK ?= "iphonesimulator"
DESTINATION ?= "platform=iOS Simulator,name=iPhone 6"
WORKSPACE := Analytics
XC_ARGS := -scheme libAnalytics -workspace $(WORKSPACE).xcworkspace -sdk $(SDK) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO

bootstrap:
	.buildscript/bootstrap.sh

install:
	pod install --project-directory=Examples/CocoapodsExample

lint:
	pod lib lint

carthage:
	carthage build --no-skip-current

archive:
	carthage archive Analytics

clean:
	xcodebuild $(XC_ARGS) clean

build:
	xcodebuild $(XC_ARGS)
	
build-examples: build-cocoapods-example build-carthage-example build-manual-example
	
build-cocoapods-example:
	pod install --project-directory=Examples/CocoapodsExample
	xcodebuild -scheme CocoapodsExample -workspace Examples/CocoapodsExample/CocoapodsExample.xcworkspace -sdk $(SDK) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO
	
build-carthage-example:
	carthage update --project-directory ./Examples/CarthageExample
	xcodebuild -scheme CarthageExample -project Examples/CarthageExample/CarthageExample.xcodeproj -sdk $(SDK) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO

build-manual-example:
	xcodebuild -scheme ManualExample -project Examples/ManualExample/ManualExample.xcodeproj -sdk $(SDK) -destination $(DESTINATION) ONLY_ACTIVE_ARCH=NO

test:
	xcodebuild test $(XC_ARGS)

clean-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) clean | xcpretty

build-pretty:
	set -o pipefail && xcodebuild $(XC_ARGS) | xcpretty

test-pretty:
	set -o pipefail && xcodebuild test $(XC_ARGS) | xcpretty --report junit
	
test-pretty-travis:
	set -o pipefail && xcodebuild test $(XC_ARGS) | xcpretty --report junit -f `xcpretty-travis-formatter`

xcbuild:
	xctool $(XC_ARGS)

xctest:
	xctool test $(XC_ARGS)

.PHONY: bootstrap lint carthage archive test xctest build xcbuild clean
