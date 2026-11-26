import SwiftUI

public struct ProjectEditorSheet: View {
    public enum Mode {
        case create(initialClientId: UUID? = nil)
        case edit(Project)
    }

    public let mode: Mode

    @Environment(PersistenceStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var selectedClientId: UUID? = nil
    @State private var colorHex: String = AppColors.projectColors[0]
    @State private var isArchived: Bool = false
    @State private var hourlyRateText: String = ""
    @State private var isBillableDefault: Bool = false
    @State private var estimatedHoursText: String = ""
    @State private var isCreatingClientInline: Bool = false
    @State private var newClientName: String = ""

    public init(mode: Mode = .create()) {
        self.mode = mode
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var targetProject: Project? {
        if case .edit(let project) = mode { return project }
        return nil
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditMode ? "Edit Project" : "New Project")
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
                    Text("Project Name")
                        .font(AppTypography.label)
                        .foregroundStyle(.secondary)

                    TextField("Project name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .font(AppTypography.body)
                }

                // Client Picker
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    HStack {
                        Text("Client")
                            .font(AppTypography.label)
                            .foregroundStyle(.secondary)
                        Spacer()
                        if !isCreatingClientInline {
                            Button("+ New Client") {
                                isCreatingClientInline = true
                            }
                            .font(AppTypography.caption)
                            .buttonStyle(.plain)
                            .foregroundStyle(AppColors.brandAccent)
                        }
                    }

                    if isCreatingClientInline {
                        HStack(spacing: AppSpacing.sm) {
                            TextField("Client name", text: $newClientName)
                                .textFieldStyle(.roundedBorder)
                                .font(AppTypography.body)

                            Button("Add") {
                                let trimmed = newClientName.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                let newClient = Client(name: trimmed)
                                store.saveClient(newClient)
                                selectedClientId = newClient.id
                                newClientName = ""
                                isCreatingClientInline = false
                            }
                            .disabled(newClientName.trimmingCharacters(in: .whitespaces).isEmpty)

                            Button("Cancel") {
                                newClientName = ""
                                isCreatingClientInline = false
                            }
                            .buttonStyle(.plain)
                            .font(AppTypography.caption)
                        }
                    } else {
                        Picker("Client", selection: $selectedClientId) {
                            Text("None")
                                .tag(Optional<UUID>.none)
                            Divider()
                            ForEach(store.clients) { client in
                                Text(client.name)
                                    .tag(Optional<UUID>.some(client.id))
                            }
                        }
                        .labelsHidden()
                        .pickerStyle(.menu)
                    }
                }

                // Color Swatches
                ColorSwatchPicker(selectedHex: $colorHex)

                // Billing & Estimate Settings
                HStack(spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        let currency = selectedClientId.flatMap { store.client(for: $0)?.currency } ?? "$"
                        Text("Hourly Rate (\(currency)/hr)")
                            .font(AppTypography.label)
                            .foregroundStyle(.secondary)
                        TextField("e.g. 75", text: $hourlyRateText)
                            .textFieldStyle(.roundedBorder)
                            .font(AppTypography.body)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Time Estimate (hours)")
                            .font(AppTypography.label)
                            .foregroundStyle(.secondary)
                        TextField("e.g. 40", text: $estimatedHoursText)
                            .textFieldStyle(.roundedBorder)
                            .font(AppTypography.body)
                    }
                }

                Toggle("Billable by default", isOn: $isBillableDefault)
                    .font(AppTypography.body)
                    .help("Automatically mark new time entries on this project as billable")

                // Archive Toggle (Edit mode only)
                if isEditMode {
                    Toggle("Archive Project", isOn: $isArchived)
                        .font(AppTypography.body)
                        .help("Archived projects are hidden from timer tracking pickers")
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

                Button(isEditMode ? "Save Changes" : "Create Project") {
                    saveProject()
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.brandAccent)
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
        }
        .frame(width: 440)
        .background(AppColors.background)
        .onAppear {
            switch mode {
            case .create(let initialClientId):
                self.selectedClientId = initialClientId
            case .edit(let project):
                self.name = project.name
                self.selectedClientId = project.clientId
                self.colorHex = project.colorHex
                self.isArchived = project.isArchived
                self.isBillableDefault = project.isBillableDefault
                if let rate = project.hourlyRate, rate > 0 {
                    self.hourlyRateText = rate.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(rate))" : String(format: "%.2f", rate)
                }
                if let est = project.estimatedHours, est > 0 {
                    self.estimatedHoursText = est.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(est))" : String(format: "%.2f", est)
                }
            }
        }
    }

    private func saveProject() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let parsedRate = Double(hourlyRateText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        let resolvedRate = (parsedRate ?? 0) > 0 ? parsedRate : nil

        let parsedEst = Double(estimatedHoursText.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
        let resolvedEst = (parsedEst ?? 0) > 0 ? parsedEst : nil

        if let existing = targetProject {
            existing.name = trimmedName
            existing.clientId = selectedClientId
            existing.colorHex = colorHex
            existing.isArchived = isArchived
            existing.hourlyRate = resolvedRate
            existing.isBillableDefault = isBillableDefault
            existing.estimatedHours = resolvedEst
            store.saveProject(existing)
        } else {
            let newProject = Project(
                name: trimmedName,
                colorHex: colorHex,
                isArchived: isArchived,
                hourlyRate: resolvedRate,
                isBillableDefault: isBillableDefault,
                estimatedHours: resolvedEst,
                clientId: selectedClientId
            )
            store.saveProject(newProject)
        }

        dismiss()
    }
}
