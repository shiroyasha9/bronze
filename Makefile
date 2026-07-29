APP := Bronze
BUILD_DIR := $(CURDIR)/.build/xcode
APP_PATH := $(BUILD_DIR)/Build/Products/Debug/$(APP).app

.PHONY: gen build test run clean sign-setup

sign-setup:
	bash scripts/setup-signing.sh

gen:
	xcodegen generate

build: gen
	xcodebuild -project $(APP).xcodeproj -scheme $(APP) -configuration Debug -derivedDataPath $(BUILD_DIR) build

test:
	cd Core && swift test

run: build
	open $(APP_PATH)

clean:
	rm -rf $(APP).xcodeproj $(BUILD_DIR) Core/.build
