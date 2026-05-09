CXX ?= clang++
CXXFLAGS ?= -std=c++17 -Wall -Wextra -Wpedantic -O2 -Iinclude
LDFLAGS ?= -framework AppKit -lsqlite3
SWIFTC ?= swiftc
SWIFTFLAGS ?= -O

BUILD_DIR := build
BIN := $(BUILD_DIR)/ditto-mac
OBJECTS := \
	$(BUILD_DIR)/main.o \
	$(BUILD_DIR)/Pasteboard.o \
	$(BUILD_DIR)/HistoryStore.o
APP_NAME := DittoMac
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
APP_CONTENTS := $(APP_DIR)/Contents
APP_MACOS := $(APP_CONTENTS)/MacOS
APP_RESOURCES := $(APP_CONTENTS)/Resources
APP_BIN := $(APP_MACOS)/$(APP_NAME)
APP_SMOKE_BIN := $(BUILD_DIR)/ditto-mac-app-smoke
SWIFT_CORE_SOURCES := \
	app/SQLiteHistoryStore.swift \
	app/PasteboardBridge.swift
SWIFT_APP_SOURCES := \
	app/ClipboardHistoryModel.swift \
	app/GlobalHotKeyController.swift \
	app/PasteExecutor.swift \
	app/ShortcutSettings.swift \
	app/MainWindowAccessor.swift \
	app/AppDelegate.swift \
	app/ContentView.swift \
	app/SettingsView.swift \
	app/DittoMacApp.swift

.PHONY: all app clean cli test test-app test-cli

all: cli app

cli: $(BIN)

app: $(APP_BIN)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(APP_CONTENTS) $(APP_MACOS) $(APP_RESOURCES): | $(BUILD_DIR)
	mkdir -p $@

$(BUILD_DIR)/%.o: src/%.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: src/%.mm | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) -fobjc-arc -c $< -o $@

$(BIN): $(OBJECTS)
	$(CXX) $(OBJECTS) $(LDFLAGS) -o $@

$(APP_CONTENTS)/Info.plist: app/Info.plist | $(APP_CONTENTS)
	cp $< $@

$(APP_BIN): $(SWIFT_CORE_SOURCES) $(SWIFT_APP_SOURCES) $(APP_CONTENTS)/Info.plist | $(APP_MACOS) $(APP_RESOURCES)
	$(SWIFTC) $(SWIFTFLAGS) -framework SwiftUI -framework AppKit -framework Carbon -lsqlite3 $(SWIFT_CORE_SOURCES) $(SWIFT_APP_SOURCES) -o $@

$(APP_SMOKE_BIN): $(SWIFT_CORE_SOURCES) tests/AppSmokeTests.swift | $(BUILD_DIR)
	$(SWIFTC) $(SWIFTFLAGS) -framework AppKit -lsqlite3 $(SWIFT_CORE_SOURCES) tests/AppSmokeTests.swift -o $@

test: test-cli test-app

test-cli: cli
	tests/test_ditto_mac.sh $(BIN)

test-app: cli app $(APP_SMOKE_BIN)
	tests/test_ditto_mac_app.sh $(APP_SMOKE_BIN) $(APP_DIR)

clean:
	rm -rf $(BUILD_DIR)
