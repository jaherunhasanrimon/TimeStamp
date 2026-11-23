import SwiftUI

public struct SkeletonRootView: View {
    @Environment(PersistenceStore.self) private var store

    @State private var newProjectName: String = ""
    @State private var selectedColorHex: String = AppColors.projectColors.first ?? "#5C3BFE"

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Header
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text("Projects")
                            .font(AppTypography.heading)
                            .foregroundStyle(.primary)

                        Text("Phase 1 Walking Skeleton: End-to-end native persistence & UI integration")
                            .font(AppTypography.body)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("\(store.projects.count) Projects")
                        .font(AppTypography.caption)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xs)
                        .background(AppColors.cardBackground)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppColors.subtleBorder, lineWidth: 1))
                }

                // Create Project Card
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("Add New Project")
                        .font(AppTypography.subheading)

                    HStack(spacing: AppSpacing.md) {
                        TextField("Project name (e.g. Client Redesign)", text: $newProjectName)
                            .textFieldStyle(.roundedBorder)
                            .font(AppTypography.body)
                            .frame(minWidth: 220)

                        // Color Swatch Selection
                        HStack(spacing: AppSpacing.xs) {
                            ForEach(AppColors.projectColors, id: \.self) { colorHex in
                                Circle()
                                    .fill(Color(hex: colorHex))
                                    .frame(width: 18, height: 18)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColorHex == colorHex ? 2 : 0)
                                    )
                                    .contentShape(Circle())
                                    .onTapGesture {
                                        selectedColorHex = colorHex
                                    }
                            }
                        }

                        Button(action: addProject) {
                            HStack(spacing: AppSpacing.xs) {
                                Image(systemName: "plus")
                                Text("Add Project")
                            }
                            .font(AppTypography.label)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppColors.brandAccent)
                        .disabled(newProjectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(AppSpacing.md)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
                .overlay(
                    RoundedRectangle(cornerRadius: AppSpacing.radiusCard)
                        .stroke(AppColors.subtleBorder, lineWidth: 1)
                )

                // Project List
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Stored Projects")
                        .font(AppTypography.subheading)

                    if store.projects.isEmpty {
                        VStack(spacing: AppSpacing.sm) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 32))
                                .foregroundStyle(.secondary)
                            Text("No projects yet")
                                .font(AppTypography.body)
                                .foregroundStyle(.secondary)
                            Text("Add your first project above to test local atomic persistence.")
                                .font(AppTypography.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(AppSpacing.xl)
                        .background(AppColors.cardBackground.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
                    } else {
                        VStack(spacing: AppSpacing.xs) {
                            ForEach(store.projects) { project in
                                HStack(spacing: AppSpacing.md) {
                                    Circle()
                                        .fill(Color(hex: project.colorHex))
                                        .frame(width: 12, height: 12)

                                    Text(project.name)
                                        .font(AppTypography.body)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Text(project.createdAt, style: .date)
                                        .font(AppTypography.caption)
                                        .foregroundStyle(.secondary)

                                    Button(role: .destructive) {
                                        store.deleteProject(id: project.id)
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(AppTypography.caption)
                                    }
                                    .buttonStyle(.borderless)
                                    .foregroundStyle(.secondary)
                                    .help("Delete project")
                                }
                                .padding(AppSpacing.sm)
                                .background(AppColors.cardBackground)
                                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppSpacing.radiusSmall)
                                        .stroke(AppColors.subtleBorder, lineWidth: 0.5)
                                )
                            }
                        }
                    }
                }
            }
            .padding(AppSpacing.lg)
        }
    }

    private func addProject() {
        let trimmed = newProjectName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let project = Project(name: trimmed, colorHex: selectedColorHex)
        store.saveProject(project)
        newProjectName = ""
    }
}
