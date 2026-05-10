import SwiftUI

struct ShortcutAssignmentRow: View {
    @Binding var assignment: ShortcutAssignment

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                title
                Spacer(minLength: 8)
                shortcutFields
                    .frame(maxWidth: 320)
            }
            VStack(alignment: .leading, spacing: 8) {
                title
                shortcutFields
            }
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(assignment.commandName)
                .fontWeight(.medium)
                .lineLimit(2)
            Text(assignment.scope)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var shortcutFields: some View {
        HStack(spacing: 8) {
            TextField("Primary", text: $assignment.primary)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 90, maxWidth: 150)
            TextField("Secondary", text: $assignment.secondary)
                .textFieldStyle(.roundedBorder)
                .frame(minWidth: 90, maxWidth: 150)
        }
    }
}
