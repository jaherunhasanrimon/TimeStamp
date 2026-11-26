import SwiftUI

/// Non-focus-stealing Description Autocomplete dropdown matching Toggl Track macOS (toggl_macos_autocomplete.jpg).
/// Displays matching RECENT ENTRIES and PROJECTS with highlighted search substring and client labels.
public struct AutocompletePopoverView: View {
    @Environment(PersistenceStore.self) private var store

    public let query: String
    public let highlightedIndex: Int
    public let onSelectEntry: (TimeEntry) -> Void
    public let onSelectProject: (Project, Task?) -> Void
    public let onDismiss: () -> Void

    public init(
        query: String,
        highlightedIndex: Int = 0,
        onSelectEntry: @escaping (TimeEntry) -> Void,
        onSelectProject: @escaping (Project, Task?) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.query = query
        self.highlightedIndex = highlightedIndex
        self.onSelectEntry = onSelectEntry
        self.onSelectProject = onSelectProject
        self.onDismiss = onDismiss
    }

    public static func buildSuggestions(
        query: String,
        store: PersistenceStore
    ) -> (entries: [TimeEntry], projects: [Project]) {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("@"), !trimmed.hasPrefix("#") else {
            return ([], [])
        }
        let entries = store.recentUniqueEntries(matching: trimmed, limit: 4)
        let q = trimmed.lowercased()
        let matchingProjects = store.projects
            .filter { !$0.isArchived }
            .filter { proj in
                if proj.name.lowercased().contains(q) { return true }
                if let cId = proj.clientId, let client = store.client(for: cId),
                   client.name.lowercased().contains(q) {
                    return true
                }
                return false
            }
            .prefix(8)
        return (entries, Array(matchingProjects))
    }

    public var body: some View {
        let suggestions = Self.buildSuggestions(query: query, store: store)
        if !suggestions.entries.isEmpty || !suggestions.projects.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        if !suggestions.entries.isEmpty {
                            Text("RECENT ENTRIES")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.top, 8)
                                .padding(.bottom, 3)

                            ForEach(Array(suggestions.entries.enumerated()), id: \.element.id) { idx, entry in
                                entrySuggestionRow(entry, isHighlighted: idx == highlightedIndex)
                            }
                        }

                        if !suggestions.projects.isEmpty {
                            Text("PROJECTS")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 12)
                                .padding(.top, suggestions.entries.isEmpty ? 8 : 6)
                                .padding(.bottom, 3)

                            ForEach(Array(suggestions.projects.enumerated()), id: \.element.id) { idx, project in
                                let flatIndex = suggestions.entries.count + idx
                                projectSuggestionRow(project, isHighlighted: flatIndex == highlightedIndex)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 290)
            }
            .frame(maxWidth: 420, alignment: .leading)
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.35), radius: 14, y: 6)
        }
    }

    @ViewBuilder
    private func entrySuggestionRow(_ entry: TimeEntry, isHighlighted: Bool) -> some View {
        let project = entry.projectId.flatMap { store.project(for: $0) }
        let client = project?.clientId.flatMap { store.client(for: $0) }

        Button(action: { onSelectEntry(entry) }) {
            HStack(spacing: 8) {
                highlightedText(entry.entryDescription, query: query, baseColor: Color.primary)
                    .font(.system(size: 12.5, weight: .medium))
                    .lineLimit(1)

                if let project = project {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: project.colorHex))
                            .frame(width: 7, height: 7)
                        Text(project.name)
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: project.colorHex))
                        if let client = client {
                            Text("· \(client.name)")
                                .font(.system(size: 11.5))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .lineLimit(1)
                }

                Spacer()

                if entry.isBillable {
                    Text("$")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(AppColors.billable)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isHighlighted ? AppColors.secondaryCardBackground : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func projectSuggestionRow(_ project: Project, isHighlighted: Bool) -> some View {
        let client = project.clientId.flatMap { store.client(for: $0) }

        Button(action: { onSelectProject(project, nil) }) {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(hex: project.colorHex))
                    .frame(width: 8, height: 8)

                highlightedText(
                    project.name,
                    query: query,
                    baseColor: Color(hex: project.colorHex)
                )
                .font(.system(size: 12.5, weight: .medium))
                .lineLimit(1)

                if let client = client {
                    Text("· \(client.name)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isHighlighted ? AppColors.secondaryCardBackground : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }

    private func highlightedText(_ source: String, query: String, baseColor: Color) -> Text {
        var attr = AttributedString(source)
        attr.foregroundColor = baseColor
        let q = query.trimmingCharacters(in: .whitespaces)
        if !q.isEmpty, let range = attr.range(of: q, options: .caseInsensitive) {
            attr[range].backgroundColor = Color.primary.opacity(0.14)
            attr[range].inlinePresentationIntent = .stronglyEmphasized
        }
        return Text(attr)
    }
}
