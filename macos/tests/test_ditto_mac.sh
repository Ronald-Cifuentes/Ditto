#!/bin/sh
set -eu

BIN="${1:-./build/ditto-mac}"
TMP_ROOT="${TMPDIR:-/tmp}"
TEST_DIR="${TMP_ROOT%/}/ditto-mac-test-$$"
mkdir -p "$TEST_DIR"

export DITTO_MAC_DB="$TEST_DIR/history.sqlite"
ORIGINAL_PASTEBOARD="$TEST_DIR/original-pasteboard.txt"

"$BIN" paste > "$ORIGINAL_PASTEBOARD" 2>/dev/null || :

cleanup() {
	if [ -f "$ORIGINAL_PASTEBOARD" ]; then
		"$BIN" copy-stdin < "$ORIGINAL_PASTEBOARD" >/dev/null 2>&1 || :
	fi
	rm -rf "$TEST_DIR"
}
trap cleanup EXIT HUP INT TERM

fail() {
	echo "FAIL: $*" >&2
	exit 1
}

assert_eq() {
	expected="$1"
	actual="$2"
	label="$3"
	if [ "$expected" != "$actual" ]; then
		fail "$label: expected '$expected', got '$actual'"
	fi
}

"$BIN" version >/dev/null
"$BIN" help >/dev/null

actual_db_path="$("$BIN" db-path)"
assert_eq "$DITTO_MAC_DB" "$actual_db_path" "db-path"

"$BIN" clear >/dev/null
assert_eq "0" "$("$BIN" count)" "initial count"

FIRST="$TEST_DIR/first.txt"
SECOND="$TEST_DIR/second.txt"
NUL_TEXT="$TEST_DIR/nul-text.txt"
ACTUAL="$TEST_DIR/actual.txt"

printf 'first item\nline two' > "$FIRST"
"$BIN" copy-stdin < "$FIRST"
"$BIN" paste > "$ACTUAL"
cmp "$FIRST" "$ACTUAL" >/dev/null || fail "copy-stdin/paste round trip"

"$BIN" capture >/dev/null
assert_eq "1" "$("$BIN" count)" "count after first capture"

"$BIN" capture >/dev/null
assert_eq "1" "$("$BIN" count)" "duplicate capture should not insert"

printf 'nul\000inside' > "$NUL_TEXT"
"$BIN" copy-stdin < "$NUL_TEXT"
"$BIN" paste > "$ACTUAL"
cmp "$NUL_TEXT" "$ACTUAL" >/dev/null || fail "copy-stdin/paste with embedded NUL"

printf 'second item' > "$SECOND"
"$BIN" copy-stdin < "$SECOND"
"$BIN" listen --once --interval-ms 1 >/dev/null
assert_eq "2" "$("$BIN" count)" "count after listen --once"

"$BIN" show latest > "$ACTUAL"
cmp "$SECOND" "$ACTUAL" >/dev/null || fail "show latest"

line_count="$("$BIN" list --limit 1 | wc -l | tr -d ' ')"
assert_eq "1" "$line_count" "list --limit"

oldest_id="$("$BIN" list --limit 10 | awk 'END {print $1}')"
[ -n "$oldest_id" ] || fail "could not read oldest id from list"

"$BIN" show "$oldest_id" > "$ACTUAL"
cmp "$FIRST" "$ACTUAL" >/dev/null || fail "show by id"

"$BIN" copy "$oldest_id" >/dev/null
"$BIN" paste > "$ACTUAL"
cmp "$FIRST" "$ACTUAL" >/dev/null || fail "copy by id"

if "$BIN" show 999999 >/dev/null 2>&1; then
	fail "missing id should fail"
fi

"$BIN" clear >/dev/null
assert_eq "0" "$("$BIN" count)" "count after clear"

echo "ditto-mac tests passed"
