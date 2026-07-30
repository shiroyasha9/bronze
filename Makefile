APP := Bronze
BUILD_DIR := $(CURDIR)/.build/xcode
APP_PATH := $(BUILD_DIR)/Build/Products/Debug/$(APP).app

RELEASE_DIR := $(CURDIR)/.build/release
RELEASE_APP := $(RELEASE_DIR)/Build/Products/Release/$(APP).app
DIST_DIR := $(CURDIR)/dist
SIGN_IDENTITY ?= Developer ID Application: Mubin Ansari (7U6G55576W)
TEAM_ID ?= 7U6G55576W
NOTARY_PROFILE ?= bronze-notary
VERSION := $(shell awk '/MARKETING_VERSION:/ {print $$2}' project.yml)
SPARKLE_BIN := $(BUILD_DIR)/SourcePackages/artifacts/sparkle/Sparkle/bin

.PHONY: gen build test run clean sign-setup release notarize dmg appcast

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

release: gen
	xcodebuild -project $(APP).xcodeproj -scheme $(APP) -configuration Release \
		-derivedDataPath $(RELEASE_DIR) \
		CODE_SIGN_IDENTITY="$(SIGN_IDENTITY)" \
		DEVELOPMENT_TEAM="$(TEAM_ID)" \
		CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
		OTHER_CODE_SIGN_FLAGS="--timestamp" \
		build

notarize: release
	mkdir -p $(DIST_DIR)
	ditto -c -k --keepParent "$(RELEASE_APP)" "$(DIST_DIR)/$(APP).zip"
	xcrun notarytool submit "$(DIST_DIR)/$(APP).zip" --keychain-profile $(NOTARY_PROFILE) --wait
	xcrun stapler staple "$(RELEASE_APP)"
	ditto -c -k --keepParent "$(RELEASE_APP)" "$(DIST_DIR)/$(APP).zip"

dmg: notarize
	rm -f "$(DIST_DIR)/$(APP).dmg"
	hdiutil create -volname $(APP) -srcfolder "$(RELEASE_APP)" -ov -format UDZO "$(DIST_DIR)/$(APP).dmg"
	codesign --force --sign "$(SIGN_IDENTITY)" "$(DIST_DIR)/$(APP).dmg"

appcast: dmg
	rm -rf $(DIST_DIR)/appcast && mkdir -p $(DIST_DIR)/appcast
	cp "$(DIST_DIR)/$(APP).dmg" "$(DIST_DIR)/appcast/$(APP)-$(VERSION).dmg"
	$(SPARKLE_BIN)/generate_appcast \
		--download-url-prefix "https://github.com/shiroyasha9/bronze/releases/download/v$(VERSION)/" \
		-o "$(DIST_DIR)/appcast/appcast.xml" \
		"$(DIST_DIR)/appcast"

clean:
	rm -rf $(APP).xcodeproj $(BUILD_DIR) $(RELEASE_DIR) $(DIST_DIR) Core/.build
