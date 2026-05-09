# macOS Parity Status

This file tracks parity against the Windows Ditto codebase. It is intentionally
strict: a feature is not marked complete unless there is native macOS code and a
test or launch smoke path for it.

## Implemented

- Clipboard capture and history storage.
- Native SwiftUI/AppKit graphical history window.
- Menu-bar item.
- Settings panel.
- Tabbed Settings surface for General, Shortcuts, Quick Paste, Types, Copy
  Buffers, Friends, Database, Parity, and About.
- Shortcut assignment editor surface based on the Windows Quick Paste Keyboard
  model. Assignments are persisted.
- SQLite persistence.
- Search.
- Text clipboard round trip.
- Image clipboard round trip.
- File URL clipboard round trip.
- RTF clipboard storage and restore.
- HTML clipboard storage and restore.
- Duplicate suppression for sequential duplicate captures.
- Global hotkey registration for `Command-Option-V`.
- Groups and favorites.
- Paste-selected action that restores the selected clip and sends `Command-V`.
- Command-line text compatibility target.

## Partial

- Quick-paste behavior: the Mac app has a searchable window, flat groups,
  favorites, and paste action, but not all Windows quick-paste keyboard
  behaviors such as first-ten accelerators, roll-up caption behavior, mouse
  shortcut assignment, sticky clip ordering, or every list-control shortcut.
- Options/control panel: the Mac Settings window now exposes a tab for each
  major Windows option category, but many controls are parity placeholders
  until the underlying feature exists.
- Shortcut creation: the Mac app now exposes a persisted shortcut editor, but
  most action assignments are not yet connected to runtime dispatch. The
  currently wired commands are the app-level menu shortcuts and the
  `Command-Option-V` global activation hotkey.
- Clipboard formats: common macOS types are handled. Windows-specific CF_*
  formats and delayed-rendering OLE behavior do not have one-to-one macOS
  equivalents.

## Not Implemented

- Windows DLL add-in binary compatibility.
- ChaiScript add-in execution pipeline.
- Network friends/send-receive clip sharing.
- QR export.
- Multi-selection paste aggregation.
- Hierarchical group tree with cut/copy/move internal clipboard semantics.
- Full database import/export compatibility with every historical Windows
  schema.
- Theme engine parity with the Windows custom non-client painting code.
- UAC/elevated-app paste behavior; macOS has a different permissions model.

## Windows Resource Audit

The following Windows menus are defined in `CP_Main.rc` and are only partially
represented in the Mac app:

- `IDR_MENU` tray/system menu:
  - Show Quick Paste
  - Options
  - Show Startup Message
  - Global Hot Keys
  - Delete Clip Data
  - Delete All Non Used Clips
  - Backup Database
  - Restore Database
  - Import Clip(s)
  - New Clip
  - Help
  - Connect To Clipboard
  - Save Current Clipboard
  - Exit
- `IDR_QUICK_PASTE` context menu:
  - Groups: View Groups, New Group, New Group Selection, Move to Group,
    Toggle Last Group Toggle
  - Send To: Friend 1 through Friend 15
  - View Full Description
  - Special Paste: plain text, case transforms, invert case, trim whitespace,
    CamelCase, ASCII text only, line feed transforms, current time,
    multi-image horizontal/vertical, paste without changing order,
    Typoglycemia, Slugify
  - Compare: select left/right, compare
  - Filter on selected clip
  - Delete Entry
  - Edit Clip
  - New Clip
  - Properties
  - Quick Properties: never auto delete, auto delete, remove hot key,
    remove quick paste
  - Clip Order: move top/up/down/last, sticky clip operations
  - Import/Export: import/export clips, QR, text/image export, Google
    Translate, import copied file contents, email/Gmail, set drag file name
- `IDR_MENU_SEARCH`:
  - Search Description
  - Search Full Text
  - Search Quick Paste
  - Contains Text Search
  - Regular Expression Search
  - Wildcard Search
- `IDR_DESC_OPTIONS_MENU`:
  - Remember window position
  - Size window to content
  - Scale images to fit window
  - Hide description window on mouse clip selection
  - Wrap text
  - Always on top
  - View as Text, RTF, HTML, Image
- `IDR_MENU_GROUPS`:
  - New Sub Group
  - Delete Group
  - Properties
- `IDR_QUICK_PASTE_SYSTEM_MENU`:
  - Options
  - Search Options
  - Quick Options: lines per clip, transparency, positioning, caption side,
    always on top, auto roll-up, font, thumbnails, RTF drawing
  - Global Hot Keys, delete data, backup/restore, import, new clip, help,
    connect clipboard, save clipboard, exit

The Windows Options property sheet is built in `OptionsSheet.cpp` from these
pages:

- General (`OptionsGeneral.cpp`)
- Supported Types (`OptionsTypes.cpp`)
- Keyboard Shortcuts (`OptionsKeyBoard.cpp`)
- Copy Buffers (`OptionsCopyBuffers.cpp`)
- Quick Paste Keyboard (`QuickPasteKeyboard.cpp`)
- Friends (`OptionFriends.cpp`, conditional)
- Stats (`OptionsStats.cpp`)
- About (`About.cpp`)
- Advanced options (`AdvGeneral.cpp`, opened from General)

Important dialogs also present in `CP_Main.rc` but not implemented as native Mac
dialogs:

- `IDD_ADD_TYPE`
- `IDD_COPY_PROPERTIES`
- `IDD_GROUP_NAME`
- `IDD_MOVE_TO_GROUP`
- `IDD_DIALOG_REMOTE_FILE`
- `IDD_GLOBAL_CLIPS`
- `IDD_DELETE_CLIP_DATA`
- `IDD_SCRIPT_EDITOR`

## Shortcut Audit

The Windows `OptionsKeyBoard.cpp` page manages:

- Three activation hotkeys for showing Ditto.
- Ten positional paste hotkeys.
- Text-only paste hotkey.
- Save current clipboard hotkey.
- Copy-and-save clipboard hotkey.
- Send-paste-on-first-ten behavior.
- Move-clips-on-global-10 behavior.
- Use-UI-selected-group-for-last-ten behavior.
- Conflict detection and rollback.

The Windows `QuickPasteKeyboard.cpp` page manages user-configurable shortcuts
for `ActionEnums`, including keyboard and mouse assignments, first/second
shortcut slots, add/remove/reset, and script shortcut rows.

The Mac shortcut editor now exposes the main commands and persists editable
assignments, but it does not yet implement the Windows conflict model, mouse
shortcut model, script rows, or runtime dispatch for every `ActionEnums`
command.

## Current Test Coverage

- `make -C macos test`
- `make -C macos test CXXFLAGS='-std=c++17 -Wall -Wextra -Wpedantic -Werror -O2 -Iinclude' SWIFTFLAGS='-O -warnings-as-errors'`

These tests cover CLI compatibility, app launch, SQLite schema migration,
groups, favorites, text/image/file/HTML payloads, pasteboard round trips,
delete, clear, and embedded-NUL text preservation.
