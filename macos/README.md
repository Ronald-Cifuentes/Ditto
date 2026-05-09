# Ditto macOS targets

This directory contains native macOS clipboard-history targets:

- `build/ditto-mac`: a command-line tool for scripting and tests.
- `build/DittoMac.app`: a SwiftUI/AppKit graphical app with a history window,
  menu-bar item, Settings panel, SQLite storage, pasteboard monitoring, and a
  Command-Option-V global hotkey.

The graphical app stores and restores text, images, file URLs, RTF, and HTML.
It also supports groups, favorites, and a paste-selected action that sends
Command-V to the foreground app after restoring the selected clip.
This is still not a direct port of the existing Windows MFC UI. The Windows
project remains tightly coupled to Win32, MFC, COM/OLE clipboard formats, and
the Windows add-in/control-panel architecture.

See `PARITY.md` for a strict feature matrix.

## Build

```sh
make -C macos
```

Outputs:

```text
macos/build/ditto-mac
macos/build/DittoMac.app
```

Build only the graphical app:

```sh
make -C macos app
```

## Test

```sh
make -C macos test
```

The tests use temporary SQLite databases through `DITTO_MAC_DB` and modify the
macOS text pasteboard while they run. They restore the prior text pasteboard
content on a best-effort basis. The app test also launches
`DittoMac.app/Contents/MacOS/DittoMac --quit-after-launch`.

Run the app:

```sh
open macos/build/DittoMac.app
```

## Commands

```sh
macos/build/ditto-mac capture
macos/build/ditto-mac listen [--interval-ms N] [--once]
macos/build/ditto-mac list [--limit N]
macos/build/ditto-mac show <id|latest>
macos/build/ditto-mac copy <id|latest>
macos/build/ditto-mac copy-stdin
macos/build/ditto-mac paste
macos/build/ditto-mac count
macos/build/ditto-mac clear
macos/build/ditto-mac db-path
```

By default the database is stored at:

```text
~/Library/Application Support/DittoMac/history.sqlite
```

Set `DITTO_MAC_DB=/path/to/history.sqlite` to override it.
