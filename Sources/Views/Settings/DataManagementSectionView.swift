import SwiftUI

public struct DataManagementSectionView: View {
    @Environment(PersistenceStore.self) private var store

    @State private var showResetAlert = false
    @State private var showSampleDataToast = false

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Data Management")
                    .font(AppTypography.heading)
                Text("Manage local workspace records and testing data.")
                    .font(AppTypography.caption)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: AppSpacing.md) {
                // Load Sample Data
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Load Sample Data")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                        Text("Populates your workspace with example projects, tasks, and time entries.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(action: loadSampleData) {
                        Label("Load Demo Data", systemImage: "cylinder.split.1x2")
                            .font(AppTypography.label)
                    }
                    .buttonStyle(.bordered)
                }

                if showSampleDataToast {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppColors.success)
                        Text("Sample data loaded successfully!")
                            .font(AppTypography.caption)
                            .foregroundStyle(AppColors.success)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Divider()

                // Reset All Data
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Reset to Clean State")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.destructive)
                        Text("Creates a timestamped backup, then resets your workspace to a clean state with zero tracked time.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(role: .destructive, action: { showResetAlert = true }) {
                        Label("Backup & Reset...", systemImage: "trash.fill")
                            .font(AppTypography.label)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppColors.destructive)
                }
            }
        }
        .padding(AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
        .overlay(
            RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                .stroke(AppColors.border, lineWidth: 0.5)
        )
        .alert("Backup and Reset Workspace?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Create Backup & Reset", role: .destructive) {
                _ = store.resetToCleanState(createBackup: true)
            }
        } message: {
            Text("A timestamped backup of your current data will be saved to your Application Support folder before resetting to a fresh, clean workspace.")
        }
    }

    private func loadSampleData() {
        PreviewContainer.seedSampleData(store: store)
        showSampleDataToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            showSampleDataToast = false
        }
    }
}
