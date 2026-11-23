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
                        Text("Reset All Data")
                            .font(AppTypography.body)
                            .fontWeight(.medium)
                            .foregroundStyle(AppColors.destructive)
                        Text("Permanently deletes all projects, clients, tasks, and time entries.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Button(role: .destructive, action: { showResetAlert = true }) {
                        Label("Reset All Data...", systemImage: "trash.fill")
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
        .alert("Reset All Data?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset Everything", role: .destructive) {
                store.clearAll()
            }
        } message: {
            Text("This will permanently delete all projects, clients, tasks, and time entries. This action cannot be undone.")
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
