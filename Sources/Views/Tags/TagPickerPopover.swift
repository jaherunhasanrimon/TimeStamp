import SwiftUI

/// Toggl Track Authentic Tag Picker Popover.
/// Features:
/// - Real-time tag search with auto-focus
/// - Inline tag creation: "+ Create tag \"...\"" if not found
/// - Multi-tag selection with checkmarks
/// - Delete tag capability with automatic historical cleanup
/// - Dark plum popover styling (#2A223A) matching Toggl Track
public struct TagPickerPopover: View {
    @Environment(PersistenceStore.self) private var store
    @Binding public var selectedTagIds: [UUID]
    public var onDismiss: (() -> Void)?

    @State private var searchText: String = ""
    @State private var hoveredTagId: UUID? = nil

    public init(
        selectedTagIds: Binding<[UUID]>,
        onDismiss: (() -> Void)? = nil
    ) {
        self._selectedTagIds = selectedTagIds
        self.onDismiss = onDismiss
    }

    private var trimmedSearch: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredTags: [Tag] {
        if trimmedSearch.isEmpty {
            return store.tags
        } else {
            return store.tags.filter { $0.name.localizedCaseInsensitiveContains(trimmedSearch) }
        }
    }

    private var canCreateTag: Bool {
        guard !trimmedSearch.isEmpty else { return false }
        return !store.tags.contains { $0.name.caseInsensitiveCompare(trimmedSearch) == .orderedSame }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Text("Tags")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.primary)

                Spacer()

                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Search Bar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                TextField("Find or create tags...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(AppColors.insetBackground)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(AppColors.border, lineWidth: 1)
            )

            // Inline Create Button if no exact match
            if canCreateTag {
                Button(action: createNewTag) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.togglMagenta)

                        Text("Create tag \"\(trimmedSearch)\"")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(AppColors.togglMagenta)
                            .lineLimit(1)

                        Spacer()
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(AppColors.togglMagenta.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
            }

            // Tag List
            ScrollView {
                VStack(spacing: 2) {
                    if filteredTags.isEmpty && !canCreateTag {
                        VStack(spacing: 4) {
                            Text("No tags found")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                            Text("Type above to create a new tag")
                                .font(.system(size: 10))
                                .foregroundStyle(.secondary.opacity(0.8))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    } else {
                        ForEach(filteredTags) { tag in
                            tagRow(tag)
                        }
                    }
                }
            }
            .frame(maxHeight: 180)

            Divider()
                .overlay(AppColors.border)

            // Footer
            HStack {
                Text("\(selectedTagIds.count) selected")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)

                Spacer()

                if !selectedTagIds.isEmpty {
                    Button("Clear all") {
                        selectedTagIds.removeAll()
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(AppColors.destructive)
                    .buttonStyle(.plain)
                }

                if let onDismiss = onDismiss {
                    Button("Done") {
                        onDismiss()
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppColors.togglMagenta)
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .frame(width: 250)
        .background(AppColors.popoverBackground)
    }

    @ViewBuilder
    private func tagRow(_ tag: Tag) -> some View {
        let isSelected = selectedTagIds.contains(tag.id)
        let isHovered = hoveredTagId == tag.id

        HStack(spacing: 8) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .font(.system(size: 12))
                .foregroundStyle(isSelected ? AppColors.togglMagenta : Color.secondary)

            Text("#\(tag.name)")
                .font(.system(size: 12))
                .foregroundStyle(Color.primary)
                .lineLimit(1)

            Spacer()

            if isHovered {
                Button(action: {
                    deleteTag(tag)
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.destructive)
                }
                .buttonStyle(.plain)
                .help("Delete tag")
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(isHovered ? AppColors.secondaryCardBackground : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .contentShape(Rectangle())
        .onHover { hovering in
            hoveredTagId = hovering ? tag.id : nil
        }
        .onTapGesture {
            toggleTag(tag.id)
        }
        .contextMenu {
            Button("Delete tag", role: .destructive) {
                deleteTag(tag)
            }
        }
    }

    private func toggleTag(_ id: UUID) {
        if let index = selectedTagIds.firstIndex(of: id) {
            selectedTagIds.remove(at: index)
        } else {
            selectedTagIds.append(id)
        }
    }

    private func createNewTag() {
        guard canCreateTag else { return }
        let newTag = Tag(name: trimmedSearch, colorHex: "#E54583")
        store.saveTag(newTag)
        if !selectedTagIds.contains(newTag.id) {
            selectedTagIds.append(newTag.id)
        }
        searchText = ""
    }

    private func deleteTag(_ tag: Tag) {
        selectedTagIds.removeAll { $0 == tag.id }
        store.deleteTag(id: tag.id)
    }
}
