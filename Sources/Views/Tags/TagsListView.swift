import SwiftUI

/// Dedicated Tag Management View under MANAGE in the sidebar.
/// Supports creating, renaming, deleting tags, inspecting tag usage metrics,
/// and jumping to filtered entries.
public struct TagsListView: View {
    public var onViewEntries: ((EntryFilter) -> Void)? = nil

    @Environment(PersistenceStore.self) private var store

    @State private var searchText: String = ""
    @State private var newTagName: String = ""
    @State private var newTagColorHex: String = AppColors.projectColors[1]
    @State private var tagToRename: Tag? = nil
    @State private var renameText: String = ""
    @State private var renameColorHex: String = AppColors.projectColors[1]
    @State private var tagToDelete: Tag? = nil
    @State private var isDeleteAlertPresented: Bool = false
    @State private var validationMessage: String? = nil

    public init(onViewEntries: ((EntryFilter) -> Void)? = nil) {
        self.onViewEntries = onViewEntries
    }

    private var filteredTags: [Tag] {
        let sorted = store.tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else { return sorted }
        return sorted.filter { $0.name.lowercased().contains(query) }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Toolbar Header
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tags")
                        .font(AppTypography.heading)
                        .foregroundStyle(.primary)

                    Text("\(store.tags.count) \(store.tags.count == 1 ? "tag" : "tags")")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))

                    TextField("Search tags...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(AppTypography.body)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, AppSpacing.sm)
                .padding(.vertical, 5)
                .frame(width: 200)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)

            Divider()

            // Inline Create Tag Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: AppSpacing.sm) {
                    Circle()
                        .fill(Color(hex: newTagColorHex))
                        .frame(width: 10, height: 10)

                    TextField("Create a new tag name...", text: $newTagName)
                        .textFieldStyle(.roundedBorder)
                        .font(AppTypography.body)
                        .onSubmit {
                            createTag()
                        }

                    Menu {
                        ForEach(AppColors.projectColors, id: \.self) { hex in
                            Button {
                                newTagColorHex = hex
                            } label: {
                                Text(hex)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color(hex: newTagColorHex))
                                .frame(width: 10, height: 10)
                            Text("Color")
                                .font(AppTypography.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()

                    Button {
                        createTag()
                    } label: {
                        Label("Add Tag", systemImage: "plus")
                            .font(AppTypography.label)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.brandAccent)
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                if let validationMessage {
                    Text(validationMessage)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.destructive)
                }
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.cardBackground.opacity(0.45))

            Divider()

            // Tags List
            if filteredTags.isEmpty {
                VStack(spacing: AppSpacing.md) {
                    Spacer()
                    Image(systemName: "tag")
                        .font(.system(size: 36))
                        .foregroundStyle(.secondary.opacity(0.6))
                    Text(store.tags.isEmpty ? "No tags created yet" : "No tags match “\(searchText)”")
                        .font(AppTypography.heading)
                        .foregroundStyle(.primary)
                    Text("Tags help slice reports and categorize sessions across projects.")
                        .font(AppTypography.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredTags) { tag in
                            tagRow(tag)
                        }
                    }
                    .padding(AppSpacing.lg)
                }
            }
        }
        .background(AppColors.background)
        .sheet(item: $tagToRename) { tag in
            renameTagSheet(tag)
        }
        .confirmationDialog(
            "Delete Tag “#\(tagToDelete?.name ?? "")”?",
            isPresented: $isDeleteAlertPresented,
            titleVisibility: .visible,
            presenting: tagToDelete
        ) { tag in
            Button("Delete Tag", role: .destructive) {
                store.deleteTag(id: tag.id)
                tagToDelete = nil
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Deleting this tag permanently removes it and unlinks it from historical time entries without affecting logged durations.")
        }
    }

    @ViewBuilder
    private func tagRow(_ tag: Tag) -> some View {
        let matchingEntries = store.timeEntries.filter { $0.tagIds.contains(tag.id) }
        let totalDuration = matchingEntries.reduce(0.0) { $0 + $1.effectiveDuration }

        HStack(spacing: AppSpacing.md) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color(hex: tag.colorHex))
                    .frame(width: 8, height: 8)
                Text("#\(tag.name)")
                    .font(AppTypography.heading)
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(hex: tag.colorHex).opacity(0.12))
            .clipShape(Capsule())

            Spacer()

            Text("\(matchingEntries.count) \(matchingEntries.count == 1 ? "entry" : "entries")")
                .font(AppTypography.caption)
                .foregroundStyle(.secondary)

            if totalDuration > 0 {
                Text(DateHelper.formatHumanDuration(totalDuration))
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, AppSpacing.xs)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
            }

            Button {
                onViewEntries?(.tag(tag.id))
            } label: {
                Image(systemName: "clock")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("View entries with this tag")

            Button {
                renameText = tag.name
                renameColorHex = tag.colorHex
                tagToRename = tag
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Rename tag")

            Button {
                tagToDelete = tag
                isDeleteAlertPresented = true
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.destructive)
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.plain)
            .help("Delete tag")
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                .stroke(AppColors.border.opacity(0.6), lineWidth: 1)
        )
        .contextMenu {
            Button {
                onViewEntries?(.tag(tag.id))
            } label: {
                Label("View Entries", systemImage: "clock")
            }

            Button {
                renameText = tag.name
                renameColorHex = tag.colorHex
                tagToRename = tag
            } label: {
                Label("Rename Tag...", systemImage: "pencil")
            }

            Divider()

            Button(role: .destructive) {
                tagToDelete = tag
                isDeleteAlertPresented = true
            } label: {
                Label("Delete Tag...", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private func renameTagSheet(_ tag: Tag) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("Edit Tag")
                .font(AppTypography.heading)

            TextField("Tag name", text: $renameText)
                .textFieldStyle(.roundedBorder)

            ColorSwatchPicker(selectedHex: $renameColorHex)

            HStack {
                Button("Cancel") {
                    tagToRename = nil
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Save") {
                    let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    let conflict = store.tags.contains {
                        $0.id != tag.id && $0.name.caseInsensitiveCompare(trimmed) == .orderedSame
                    }
                    guard !conflict else { return }
                    tag.name = trimmed
                    tag.colorHex = renameColorHex
                    store.saveTag(tag)
                    tagToRename = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.brandAccent)
                .keyboardShortcut(.defaultAction)
                .disabled(renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(AppSpacing.lg)
        .frame(width: 340)
        .background(AppColors.background)
    }

    private func createTag() {
        let trimmed = newTagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if store.tags.contains(where: { $0.name.caseInsensitiveCompare(trimmed) == .orderedSame }) {
            validationMessage = "Tag “\(trimmed)” already exists."
            return
        }
        validationMessage = nil
        let tag = Tag(name: trimmed, colorHex: newTagColorHex)
        store.saveTag(tag)
        newTagName = ""
    }
}
