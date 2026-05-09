#!/bin/sh
set -eu

SMOKE_BIN="${1:-./build/ditto-mac-app-smoke}"
APP_DIR="${2:-./build/DittoMac.app}"
APP_BIN="$APP_DIR/Contents/MacOS/DittoMac"
INFO_PLIST="$APP_DIR/Contents/Info.plist"

TMP_ROOT="${TMPDIR:-/tmp}"
TEST_DIR="${TMP_ROOT%/}/ditto-mac-app-test-$$"
mkdir -p "$TEST_DIR"

export DITTO_MAC_DB="$TEST_DIR/history.sqlite"
ORIGINAL_PASTEBOARD="$TEST_DIR/original-pasteboard.txt"

if [ -x "./build/ditto-mac" ]; then
	./build/ditto-mac paste > "$ORIGINAL_PASTEBOARD" 2>/dev/null || :
fi

cleanup() {
	if [ -f "$ORIGINAL_PASTEBOARD" ] && [ -x "./build/ditto-mac" ]; then
		./build/ditto-mac copy-stdin < "$ORIGINAL_PASTEBOARD" >/dev/null 2>&1 || :
	fi
	rm -rf "$TEST_DIR"
}
trap cleanup EXIT HUP INT TERM

fail() {
	echo "FAIL: $*" >&2
	exit 1
}

[ -x "$SMOKE_BIN" ] || fail "missing smoke binary: $SMOKE_BIN"
[ -x "$APP_BIN" ] || fail "missing app executable: $APP_BIN"
[ -f "$INFO_PLIST" ] || fail "missing Info.plist"

bundle_executable="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$INFO_PLIST")"
[ "$bundle_executable" = "DittoMac" ] || fail "unexpected CFBundleExecutable: $bundle_executable"

"$SMOKE_BIN"

APP_LOG="$TEST_DIR/app-launch.log"
DITTO_MAC_DB="$TEST_DIR/launch.sqlite" "$APP_BIN" --quit-after-launch > "$APP_LOG" 2>&1 &
app_pid=$!

remaining=80
while kill -0 "$app_pid" 2>/dev/null; do
	if [ "$remaining" -le 0 ]; then
		kill "$app_pid" 2>/dev/null || :
		cat "$APP_LOG" >&2 || :
		fail "app did not quit after launch"
	fi
	remaining=$((remaining - 1))
	sleep 0.25
done

wait "$app_pid" || {
	cat "$APP_LOG" >&2 || :
	fail "app launch returned failure"
}

echo "ditto-mac app tests passed"
