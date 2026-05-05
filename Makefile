SHELL := /bin/bash
ROOT := $(CURDIR)
PROJECT := $(ROOT)/KeyLaunch.xcodeproj
SCHEME := KeyLaunch
CONFIGURATION ?= Debug
CODE_SIGNING_ALLOWED ?= YES
CODE_SIGNING_REQUIRED ?= YES
DERIVED_DATA := $(ROOT)/.build/DerivedData
APP_PATH := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)/KeyLaunch.app
ARCHIVE_PATH := $(ROOT)/dist/KeyLaunch.xcarchive

.PHONY: build-app archive run clean

build-app:
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-sdk macosx \
		-derivedDataPath "$(DERIVED_DATA)" \
		CODE_SIGNING_ALLOWED="$(CODE_SIGNING_ALLOWED)" \
		CODE_SIGNING_REQUIRED="$(CODE_SIGNING_REQUIRED)" \
		build

archive:
	mkdir -p "$(ROOT)/dist"
	xcodebuild archive \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration Release \
		-sdk macosx \
		-derivedDataPath "$(DERIVED_DATA)" \
		-archivePath "$(ARCHIVE_PATH)" \
		CODE_SIGNING_ALLOWED="$(CODE_SIGNING_ALLOWED)" \
		CODE_SIGNING_REQUIRED="$(CODE_SIGNING_REQUIRED)"

run: build-app
	open "$(APP_PATH)"

clean:
	rm -rf "$(ROOT)/.build" "$(ROOT)/dist"
