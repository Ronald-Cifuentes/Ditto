import AppKit
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var model: ClipboardHistoryModel

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                toolbar
                Divider()
                contentLayout(width: proxy.size.width)
                Divider()
                footer
            }
        }
        .frame(minWidth: 520, minHeight: 430)
    }

    @ViewBuilder
    private func contentLayout(width: CGFloat) -> some View {
        if width >= 980 {
            HStack(spacing: 0) {
                groupSidebar
                    .frame(minWidth: 150, idealWidth: 180, maxWidth: 220)
                Divider()
                historyList
                    .frame(minWidth: 280, idealWidth: 340, maxWidth: 420)
                Divider()
                detailPane
                    .frame(minWidth: 320, maxWidth: .infinity, maxHeight: .infinity)
            }
        } else if width >= 700 {
            HStack(spacing: 0) {
                VStack(spacing: 0) {
                    groupPicker
                        .padding(.horizontal, 12)
                        .padding(.top, 10)
                    historyList
                }
                .frame(minWidth: 280, idealWidth: 330, maxWidth: 390)
                Divider()
                detailPane
                    .frame(minWidth: 300, maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            VStack(spacing: 0) {
                groupPicker
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                historyList
                    .frame(minHeight: 190, idealHeight: 240, maxHeight: 310)
                Divider()
                detailPane
                    .frame(minHeight: 220, maxHeight: .infinity)
            }
        }
    }

    private var toolbar: some View {
        HStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Button(action: model.captureNow) {
                        Label("Capture", systemImage: "plus")
                    }
                    Button(action: model.copySelected) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .disabled(model.selectedClip == nil)
                    Button(action: model.pasteSelected) {
                        Label("Paste", systemImage: "command")
                    }
                    .disabled(model.selectedClip == nil)
                    Button(action: model.toggleFavoriteSelected) {
                        Label("Favorite", systemImage: model.selectedClip?.isFavorite == true ? "star.fill" : "star")
                    }
                    .disabled(model.selectedClip == nil)
                    Button(action: model.deleteSelected) {
                        Label("Delete", systemImage: "trash")
                    }
                    .disabled(model.selectedClip == nil)
                    Button(action: model.clearHistory) {
                        Label("Clear", systemImage: "xmark.circle")
                    }
                    .disabled(model.clips.isEmpty)
                    Button(action: { model.refresh(status: "Refreshed") }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }

            Spacer()

            Toggle(isOn: $model.isMonitoring) {
                Label("Monitor", systemImage: model.isMonitoring ? "bolt.fill" : "pause.fill")
            }
            .toggleStyle(.switch)
            .fixedSize()
        }
        .buttonStyle(.bordered)
        .padding(12)
    }

    private var groupSidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Groups")
                .font(.headline)
                .padding([.top, .horizontal], 12)

            List(selection: $model.selectedGroup) {
                ForEach(model.groups, id: \.self) { group in
                    Label(group, systemImage: groupIcon(group))
                        .tag(group)
                }
            }
            .listStyle(.sidebar)
        }
    }

    private var groupPicker: some View {
        Picker("Group", selection: $model.selectedGroup) {
            ForEach(model.groups, id: \.self) { group in
                Label(group, systemImage: groupIcon(group))
                    .tag(group)
            }
        }
        .pickerStyle(.menu)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var historyList: some View {
        VStack(spacing: 8) {
            TextField("Search clips", text: $model.searchText)
                .textFieldStyle(.roundedBorder)
                .padding([.top, .horizontal], 12)

            List(selection: $model.selectedID) {
                ForEach(model.filteredClips) { clip in
                    ClipRow(clip: clip)
                        .tag(clip.id)
                }
            }
            .listStyle(.inset)

            HStack(spacing: 6) {
                TextField("Move to group", text: $model.newGroupName)
                    .textFieldStyle(.roundedBorder)
                Button(action: model.createGroupAndMoveSelected) {
                    Image(systemName: "folder.badge.plus")
                }
                .disabled(model.selectedClip == nil)
                .help("Move selected clip to this group")
            }
            .padding([.horizontal, .bottom], 12)
        }
    }

    private var detailPane: some View {
        Group {
            if let clip = model.selectedClip {
                VStack(alignment: .leading, spacing: 12) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top) {
                            clipTitle(clip)
                            Spacer(minLength: 12)
                            detailButtons
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            clipTitle(clip)
                            detailButtons
                        }
                    }

                    ClipDetailBody(clip: clip)
                }
                .padding(16)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 44))
                        .foregroundStyle(.secondary)
                    Text("No Clips")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func clipTitle(_ clip: ClipItem) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: clip.kind.symbolName)
                Text("Clip \(clip.id)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                Text(clip.kind.label)
                    .font(.caption)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                if clip.isFavorite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                }
            }
            Text(clip.createdAt)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            Text(clip.groupName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    private var detailButtons: some View {
        HStack(spacing: 8) {
            Button(action: model.pasteSelected) {
                Label("Paste", systemImage: "command")
            }
            Button(action: model.copySelected) {
                Label("Copy", systemImage: "doc.on.doc")
            }
            Button(action: model.deleteSelected) {
                Label("Delete", systemImage: "trash")
            }
        }
        .buttonStyle(.bordered)
        .fixedSize()
    }

    private var footer: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                Text("\(model.filteredClips.count) shown")
                Text("\(model.clips.count) saved")
                Divider()
                    .frame(height: 16)
                Text(model.statusText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button(action: model.revealDatabase) {
                    Label("Database", systemImage: "folder")
                }
                .buttonStyle(.borderless)
            }
            HStack(spacing: 8) {
                Text("\(model.filteredClips.count)/\(model.clips.count)")
                Text(model.statusText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer()
                Button(action: model.revealDatabase) {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
    }

    private func groupIcon(_ group: String) -> String {
        switch group {
        case "All":
            return "tray.full"
        case "Favorites":
            return "star"
        default:
            return "folder"
        }
    }
}

private struct ClipRow: View {
    let clip: ClipItem

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label("#\(clip.id)", systemImage: clip.kind.symbolName)
                    .font(.caption)
                    .fontWeight(.semibold)
                if clip.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
                Spacer()
                Text(clip.createdAt)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(clip.groupName)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(clip.preview)
                .font(.body)
                .lineLimit(2)
        }
        .padding(.vertical, 5)
    }
}

private struct ClipDetailBody: View {
    let clip: ClipItem

    var body: some View {
        Group {
            if clip.kind == .image, let payload = clip.payload, let image = NSImage(data: payload) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if !clip.metadata.isEmpty {
                        Text(clip.metadata)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(12)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if clip.kind == .files {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(clip.filePaths, id: \.self) { path in
                            Label(path, systemImage: "doc")
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ScrollView {
                    Text(clip.content)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                        .padding(12)
                }
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
    }
}
