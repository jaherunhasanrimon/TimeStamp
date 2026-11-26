import SwiftUI

public struct ActivityAutotrackerSettingsView: View {
    @Environment(ActivityTrackerManager.self) private var activityManager
    @Environment(PersistenceStore.self) private var store

    @State private var newRuleKeyword: String = ""
    @State private var newRuleProjectId: UUID? = nil
    @State private var newRuleBillable: Bool = false
    @State private var newExclusionBundle: String = ""
    @State private var isPurgeAlertPresented: Bool = false

    public init() {}

    public var body: some View {
        @Bindable var bindActivity = activityManager

        ScrollView {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                // Opt-in Recorder Privacy Card
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Label("Local Activity Recorder (Opt-In)", systemImage: "timeline.selection")
                        .font(AppTypography.subheading)

                    Toggle("Record frontmost application focus spans (>10s)", isOn: $bindActivity.isEnabled)
                        .font(AppTypography.body)

                    Text("Privacy notice: Disabled by default. Records only app name and duration locally on disk — never keystrokes, screenshots, clipboard contents, or passwords. (Window title inspection would require Accessibility permissions and is omitted by design.)")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        Picker("Retain local history", selection: $bindActivity.retentionDays) {
                            Text("7 days").tag(7)
                            Text("14 days").tag(14)
                            Text("30 days").tag(30)
                        }
                        .frame(width: 220)

                        Spacer()

                        Button(role: .destructive) {
                            isPurgeAlertPresented = true
                        } label: {
                            Label("Delete All Activity Data", systemImage: "trash")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))

                // Exclusions
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Excluded App Bundle IDs")
                        .font(AppTypography.subheading)

                    HStack(spacing: 8) {
                        TextField("e.g. com.apple.Passwords", text: $newExclusionBundle)
                            .textFieldStyle(.roundedBorder)
                        Button("Exclude") {
                            activityManager.addExclusion(bundleId: newExclusionBundle)
                            newExclusionBundle = ""
                        }
                        .disabled(newExclusionBundle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }

                    ForEach(activityManager.excludedBundleIds, id: \.self) { bid in
                        HStack {
                            Text(bid)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                activityManager.removeExclusion(bundleId: bid)
                            } label: {
                                Image(systemName: "xmark.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))

                // Autotracker Rules
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Label("Autotracker Rules", systemImage: "wand.and.stars")
                        .font(AppTypography.subheading)

                    Toggle("Automatically start timer when an enabled rule matches while idle", isOn: $bindActivity.autoStartOnRuleMatch)
                        .font(AppTypography.body)

                    HStack(spacing: 8) {
                        TextField("App keyword (e.g. Xcode, Figma)", text: $newRuleKeyword)
                            .textFieldStyle(.roundedBorder)

                        Picker("Project", selection: $newRuleProjectId) {
                            Text("No Project").tag(Optional<UUID>.none)
                            ForEach(store.projects.filter { !$0.isArchived }) { p in
                                Text(p.name).tag(Optional<UUID>.some(p.id))
                            }
                        }
                        .labelsHidden()
                        .frame(width: 140)

                        Toggle("$", isOn: $newRuleBillable)
                            .toggleStyle(.checkbox)

                        Button("Add Rule") {
                            let kw = newRuleKeyword.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !kw.isEmpty else { return }
                            activityManager.addRule(AutotrackerRule(
                                keyword: kw,
                                projectId: newRuleProjectId,
                                isBillable: newRuleBillable
                            ))
                            newRuleKeyword = ""
                            newRuleProjectId = nil
                            newRuleBillable = false
                        }
                        .disabled(newRuleKeyword.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    if activityManager.rules.isEmpty {
                        Text("No Autotracker rules configured yet.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(activityManager.rules) { rule in
                            HStack {
                                Text("Contains “\(rule.keyword)”")
                                    .font(AppTypography.body)
                                if let pid = rule.projectId, let proj = store.project(for: pid) {
                                    Text("→ \(proj.name)")
                                        .font(AppTypography.caption)
                                        .foregroundStyle(Color(hex: proj.colorHex))
                                }
                                Spacer()
                                Button {
                                    activityManager.deleteRule(id: rule.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(AppColors.destructive)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))

                // Recorded Local Timeline Spans Preview
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Recent Activity Timeline (\(activityManager.spans.count))")
                        .font(AppTypography.subheading)

                    if activityManager.spans.isEmpty {
                        Text(activityManager.isEnabled ? "Listening cleanly for app switches (>10s)..." : "Enable the Local Activity Recorder above to see app activity blocks.")
                            .font(AppTypography.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(activityManager.spans.prefix(15)) { span in
                            HStack {
                                Text(span.appName)
                                    .font(AppTypography.label)
                                Spacer()
                                Text(DateHelper.formatTimeRange(start: span.startDate, end: span.endDate))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                Text(TimeCalculator.formatCompactDuration(span.duration))
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .frame(width: 58, alignment: .trailing)
                            }
                            .padding(.vertical, 3)
                        }
                    }
                }
                .padding(AppSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusCard))
            }
            .padding(AppSpacing.lg)
        }
        .confirmationDialog(
            "Delete All Local Activity History?",
            isPresented: $isPurgeAlertPresented,
            titleVisibility: .visible
        ) {
            Button("Delete All Activity Data", role: .destructive) {
                activityManager.deleteAllActivityData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears all locally recorded application focus spans immediately. Your tracked Time Entries are preserved.")
        }
    }
}
