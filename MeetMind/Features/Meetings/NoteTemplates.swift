import SwiftUI

struct NoteTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var sections: [String]
    var isBuiltIn: Bool

    init(id: UUID = UUID(), name: String, sections: [String], isBuiltIn: Bool = false) {
        self.id = id
        self.name = name
        self.sections = sections
        self.isBuiltIn = isBuiltIn
    }

    var formattedContent: String {
        sections.map { "## \($0)\n\n" }.joined(separator: "\n")
    }

    static let custom = NoteTemplate(name: "Custom", sections: [], isBuiltIn: true)
}

struct NoteTemplateManager {
    private static let storageKey = "customNoteTemplates"

    static func loadCustomTemplates() -> [NoteTemplate] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let templates = try? JSONDecoder().decode([NoteTemplate].self, from: data) else {
            return []
        }
        return templates
    }

    static func saveCustomTemplates(_ templates: [NoteTemplate]) {
        if let data = try? JSONEncoder().encode(templates) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    static func addCustomTemplate(_ template: NoteTemplate) {
        var templates = loadCustomTemplates()
        templates.append(template)
        saveCustomTemplates(templates)
    }

    static func deleteCustomTemplate(id: UUID) {
        var templates = loadCustomTemplates()
        templates.removeAll { $0.id == id }
        saveCustomTemplates(templates)
    }
}

struct NoteTemplatePicker: View {
    let meetingTemplate: MeetingTemplate
    @Binding var selectedNoteTemplate: NoteTemplate?
    @State private var customTemplates: [NoteTemplate] = []
    @State private var showCreateSheet = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Default: use meeting template sections
                templateChip(
                    name: meetingTemplate.rawValue,
                    icon: meetingTemplate.icon,
                    isSelected: selectedNoteTemplate == nil
                ) {
                    selectedNoteTemplate = nil
                }

                // Custom templates
                ForEach(customTemplates) { template in
                    templateChip(
                        name: template.name,
                        icon: "doc.text",
                        isSelected: selectedNoteTemplate?.id == template.id
                    ) {
                        selectedNoteTemplate = template
                    }
                }

                // Add custom button
                Button {
                    showCreateSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Custom")
                            .font(MMTypography.caption1Medium)
                    }
                    .foregroundColor(MMColors.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(MMColors.primary.opacity(0.08))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 16)
        }
        .onAppear {
            customTemplates = NoteTemplateManager.loadCustomTemplates()
        }
        .sheet(isPresented: $showCreateSheet) {
            CreateNoteTemplateSheet { template in
                NoteTemplateManager.addCustomTemplate(template)
                customTemplates = NoteTemplateManager.loadCustomTemplates()
                selectedNoteTemplate = template
            }
            .presentationDetents([.medium])
        }
    }

    private func templateChip(name: String, icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(name)
                    .font(MMTypography.caption1Medium)
            }
            .foregroundColor(isSelected ? .white : .white.opacity(0.5))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? MMColors.primary.opacity(0.2) : Color.white.opacity(0.05))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? MMColors.primary.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

struct CreateNoteTemplateSheet: View {
    let onSave: (NoteTemplate) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var sectionsText = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Template Name") {
                    TextField("e.g., Weekly Review", text: $name)
                }

                Section {
                    TextField("One section per line\ne.g., Updates\nBlockers\nAction Items", text: $sectionsText, axis: .vertical)
                        .lineLimit(5...10)
                } header: {
                    Text("Sections")
                } footer: {
                    Text("Enter one section name per line. These become ## headings in your notepad.")
                }
            }
            .navigationTitle("New Template")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let sections = sectionsText
                            .components(separatedBy: "\n")
                            .map { $0.trimmingCharacters(in: .whitespaces) }
                            .filter { !$0.isEmpty }
                        let template = NoteTemplate(name: name, sections: sections)
                        onSave(template)
                        dismiss()
                    }
                    .disabled(name.isEmpty || sectionsText.isEmpty)
                }
            }
        }
    }
}
