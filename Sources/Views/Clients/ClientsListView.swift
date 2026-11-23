import SwiftUI

public struct ClientsListView: View {
    public var onViewEntries: ((EntryFilter) -> Void)? = nil

    @Environment(PersistenceStore.self) private var store

    @State private var searchText: String = ""
    @State private var isCreateSheetPresented: Bool = false
    @State private var clientToEdit: Client? = nil
    @State private var clientToDelete: Client? = nil
    @State private var isDeleteAlertPresented: Bool = false

    public init(onViewEntries: ((EntryFilter) -> Void)? = nil) {
        self.onViewEntries = onViewEntries
    }

    private var filteredClients: [Client] {
        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        guard !query.isEmpty else {
            return store.clients.sorted { $0.createdAt < $1.createdAt }
        }

        return store.clients.filter { client in
            if client.name.lowercased().contains(query) {
                return true
            }
            if let notes = client.notes, notes.lowercased().contains(query) {
                return true
            }
            return false
        }
        .sorted { $0.createdAt < $1.createdAt }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // View Toolbar
            HStack(spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Clients")
                        .font(AppTypography.heading)
                        .foregroundStyle(.primary)

                    Text("\(store.clients.count) clients")
                        .font(AppTypography.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // Search Bar
                HStack(spacing: AppSpacing.xs) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 12))

                    TextField("Search clients...", text: $searchText)
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
                .frame(width: 180)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.radiusSmall))

                // + New Client Button
                Button {
                    isCreateSheetPresented = true
                } label: {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "plus")
                        Text("New Client")
                    }
                    .font(AppTypography.label)
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.brandAccent)
                .help("Create new client profile")
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.md)
            .background(AppColors.background)

            Divider()

            // Clients List or Empty State
            if filteredClients.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: AppSpacing.sm) {
                        ForEach(filteredClients) { client in
                            ClientRowView(
                                client: client,
                                onEdit: {
                                    clientToEdit = client
                                },
                                onDelete: {
                                    clientToDelete = client
                                    isDeleteAlertPresented = true
                                },
                                onViewEntries: onViewEntries
                            )
                        }
                    }
                    .padding(AppSpacing.lg)
                }
            }
        }
        .background(AppColors.background)
        .sheet(isPresented: $isCreateSheetPresented) {
            ClientEditorSheet(mode: .create)
        }
        .sheet(item: $clientToEdit) { client in
            ClientEditorSheet(mode: .edit(client))
        }
        .confirmationDialog(
            "Delete Client “\(clientToDelete?.name ?? "")”?",
            isPresented: $isDeleteAlertPresented,
            titleVisibility: .visible,
            presenting: clientToDelete
        ) { client in
            Button("Delete Client", role: .destructive) {
                store.deleteClient(id: client.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: { client in
            Text("Deleting this client will unlink assigned projects. No projects, tasks, or time entries will be deleted.")
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: AppSpacing.md) {
            Spacer()

            Image(systemName: "person.2")
                .font(.system(size: 44, weight: .light))
                .foregroundStyle(AppColors.brandAccent.opacity(0.8))

            Text("No clients found")
                .font(AppTypography.subheading)
                .foregroundStyle(.primary)

            Text(searchText.isEmpty
                 ? "Create client profiles to organize your projects and analyze tracked hours per client."
                 : "No clients match “\(searchText)”.")
                .font(AppTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

            if searchText.isEmpty {
                Button("+ New Client") {
                    isCreateSheetPresented = true
                }
                .buttonStyle(.borderedProminent)
                .tint(AppColors.brandAccent)
                .padding(.top, AppSpacing.xs)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
    }
}
