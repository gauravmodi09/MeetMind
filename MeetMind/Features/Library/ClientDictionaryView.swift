import SwiftUI

/// MM-032 + MM-033: Client dictionary for managing detected client names.
/// Accessible from Settings. Allows rename, delete (merge to General), and manual add.
struct ClientDictionaryView: View {
    @EnvironmentObject var meetingService: MeetingService
    @EnvironmentObject var todoService: TodoService

    @State private var showAddClient = false
    @State private var newClientName = ""
    @State private var editingClient: String?
    @State private var editedName = ""
    @State private var clientToDelete: String?
    @State private var showDeleteConfirmation = false

    private var clients: [ClientEntry] {
        let clientNames = meetingService.allClientNames
        return clientNames.map { name in
            let meetingCount = meetingService.meetings.filter { $0.clientName == name }.count
            let todoCount = todoService.todos.filter { $0.clientTag == name }.count
            return ClientEntry(name: name, colorHex: colorHex(for: name), meetingCount: meetingCount, todoCount: todoCount)
        }
    }

    var body: some View {
        List {
            if clients.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 32))
                            .foregroundColor(MMColors.textTertiary)
                        Text("No clients detected yet")
                            .font(MMTypography.subheadline)
                            .foregroundColor(MMColors.textSecondary)
                        Text("Clients will appear here after your meetings are processed.")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                }
            } else {
                Section {
                    ForEach(clients, id: \.name) { client in
                        clientRow(client)
                    }
                } header: {
                    Text("\(clients.count) client\(clients.count == 1 ? "" : "s")")
                } footer: {
                    Text("Swipe left to delete (merges into General). Tap to rename.")
                }
            }
        }
        .navigationTitle("Client Dictionary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    newClientName = ""
                    showAddClient = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MMColors.primary)
                }
            }
        }
        .alert("Add Client", isPresented: $showAddClient) {
            TextField("Client name", text: $newClientName)
            Button("Cancel", role: .cancel) {}
            Button("Add") {
                let trimmed = newClientName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                // Create a placeholder meeting to establish the client
                // Or just note: clients come from meetings, so we just add the name to recognition
                // For now, create a minimal approach: store as a manual entry
                // The client will appear when assigned to a meeting
                addManualClient(trimmed)
            }
        } message: {
            Text("Enter a client name to add to the dictionary.")
        }
        .alert("Rename Client", isPresented: Binding(
            get: { editingClient != nil },
            set: { if !$0 { editingClient = nil } }
        )) {
            TextField("New name", text: $editedName)
            Button("Cancel", role: .cancel) { editingClient = nil }
            Button("Rename") {
                guard let oldName = editingClient else { return }
                let newName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !newName.isEmpty, newName != oldName else { return }
                meetingService.renameClient(from: oldName, to: newName)
                // Also rename in todos
                renameTodoClientTag(from: oldName, to: newName)
                editingClient = nil
            }
        } message: {
            if let name = editingClient {
                Text("Rename \"\(name)\" to a new name.")
            }
        }
        .alert("Delete Client", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { clientToDelete = nil }
            Button("Merge to General", role: .destructive) {
                guard let name = clientToDelete else { return }
                meetingService.mergeClientIntoGeneral(name)
                mergeTodoClientTag(name)
                clientToDelete = nil
            }
        } message: {
            if let name = clientToDelete {
                Text("All meetings and todos tagged \"\(name)\" will be moved to General. This cannot be undone.")
            }
        }
    }

    // MARK: - Client Row

    @ViewBuilder
    private func clientRow(_ client: ClientEntry) -> some View {
        HStack(spacing: 12) {
            // Color badge
            ZStack {
                Circle()
                    .fill(Color(hex: client.colorHex).opacity(0.15))
                    .frame(width: 40, height: 40)

                Text(String(client.name.prefix(1)).uppercased())
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: client.colorHex))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(client.name)
                    .font(MMTypography.bodyMedium)
                    .foregroundColor(MMColors.textPrimary)

                HStack(spacing: 12) {
                    Label("\(client.meetingCount) meeting\(client.meetingCount == 1 ? "" : "s")", systemImage: "rectangle.stack")
                        .font(MMTypography.caption1)
                        .foregroundColor(MMColors.textSecondary)

                    if client.todoCount > 0 {
                        Label("\(client.todoCount) todo\(client.todoCount == 1 ? "" : "s")", systemImage: "checkmark.circle")
                            .font(MMTypography.caption1)
                            .foregroundColor(MMColors.textSecondary)
                    }
                }
            }

            Spacer()

            // Edit button
            Button {
                editingClient = client.name
                editedName = client.name
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 14))
                    .foregroundColor(MMColors.textTertiary)
                    .frame(width: 32, height: 32)
                    .background(MMColors.background)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                clientToDelete = client.name
                showDeleteConfirmation = true
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Helpers

    private func colorHex(for name: String) -> String {
        let colors = ["6C5CE7", "FF4757", "00CE9E", "FFA502", "2D98FF", "E84393", "00B894", "FDCB6E"]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    private func addManualClient(_ name: String) {
        // Create a short-lived placeholder meeting to register the client
        // In a real app this would go to a dedicated client store
        // For now, we simply note the client exists by creating an empty meeting
        // Actually, better approach: just make a note. Since MeetingService derives
        // clients from meetings, we need at least one meeting with that client.
        // Let's use a different approach: store in UserDefaults as manual clients
        var manualClients = UserDefaults.standard.stringArray(forKey: "manualClients") ?? []
        if !manualClients.contains(name) {
            manualClients.append(name)
            UserDefaults.standard.set(manualClients, forKey: "manualClients")
        }
    }

    private func renameTodoClientTag(from oldName: String, to newName: String) {
        for i in todoService.todos.indices {
            if todoService.todos[i].clientTag == oldName {
                todoService.todos[i].clientTag = newName
            }
        }
    }

    private func mergeTodoClientTag(_ name: String) {
        for i in todoService.todos.indices {
            if todoService.todos[i].clientTag == name {
                todoService.todos[i].clientTag = nil
            }
        }
    }
}

// MARK: - Client Entry

private struct ClientEntry {
    let name: String
    let colorHex: String
    let meetingCount: Int
    let todoCount: Int
}

// MARK: - Preview

#Preview {
    NavigationStack {
        ClientDictionaryView()
            .environmentObject(MeetingService.shared)
            .environmentObject(TodoService.shared)
    }
}
