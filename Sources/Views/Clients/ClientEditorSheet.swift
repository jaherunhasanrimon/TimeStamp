import SwiftUI

public struct ClientEditorSheet: View {
    public enum Mode {
        case create
        case edit(Client)
    }

    public let mode: Mode

    @Environment(PersistenceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var selectedProjectIds: Set<UUID> = []

    public init(mode: Mode = .create) {
        self.mode = mode
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var targetClient: Client? {
        if case .edit(let client) = mode { return client }
        return nil
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditMode ? "Edit Client" : "New Client")
                    .font(AppTypography.heading)
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.top, AppSpacing.lg)
            .padding(.bottom, AppSpacing.md)

            Divider()

            // Form Content
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // Name Field
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Client Name")
                        .font(AppTypography.label)
                        .foregroundStyle(.secondary)

                    TextField("Client name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(AppTypography.body)
                }

                // Notes Field
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Notes / Contact (Optional)")
                        .font(AppTypography.label)
                        .foregroundStyle(.secondary)

                    TextField("Notes or contact info...", text: $notes, axis: .vertical)
                        .lineLimit(3...5)
                        .textFieldStyle(.roundedBorder)
                        .font(AppTypography.body)
                }

                // Assigned Projects Checklist
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Assigned Projects")
                        .font(AppTypography.label)
                        .foregroundStyle(.secondary)

                    if store.projects.isEmpty {
                        Text("No projects available to assign")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                            .padding(.vertical, 4)
                    } else {
                        ScrollView {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                ForEach(store.projects) { project in
                                    let isSelected = selectedProjectIds.contains(project.id)
                                    Button {
                                        if isSelected {
                                            selectedProjectIds.remove(project.id)
                                        } else {
                                            selectedProjectIds.insert(project.id)
                                        }
                                    } label: {
                                        HStack(spacing: AppSpacing.sm) {
                                            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                                .foregroundStyle(isSelected ? AppColors.brandAccent : .secondary)

                                            Circle()
                                                .fill(Color(hex: project.colorHex))
                                                .frame(width: 8, height: 8)

                                            Text(project.name)
                                                .font(AppTypography.body)
                                                .foregroundStyle(.primary)

                                            Spacer()
                                        }
                                        .padding(.vertical, 3)
                                        .padding(.horizontal, 4)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .frame(maxHeight: 120)
                        .padding(AppSpacing.xs)
                        .background(Color.secondary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                    }
                }
            }
            .padding(AppSpacing.lg)

            Divider()

            // Footer Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditMode ? "Save Changes" : "Create Client") {
                    saveClient()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.brandAccent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
        .frame(width: 400)
        .background(AppColors.background)
        .onAppear {
            if let client = targetClient {
                self.name = client.name
                self.notes = client.notes ?? ""
                let associated = store.projects.filter { $0.clientId == client.id }.map { $0.id }
                self.selectedProjectIds = Set(associated)
            }
        }
    }

    private func saveClient() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)
        let resolvedNotes = trimmedNotes.isEmpty ? nil : trimmedNotes

        let clientToSave: Client
        if let existing = targetClient {
            existing.name = trimmedName
            existing.notes = resolvedNotes
            store.saveClient(existing)
            clientToSave = existing
        } else {
            let newClient = Client(name: trimmedName, notes: resolvedNotes)
            store.saveClient(newClient)
            clientToSave = newClient
        }

        // Update project associations
        for project in store.projects {
            if selectedProjectIds.contains(project.id) {
                project.clientId = clientToSave.id
                store.saveProject(project)
            } else if project.clientId == clientToSave.id {
                project.clientId = nil
                store.saveProject(project)
            }
        }

        dismiss()
    }
}
