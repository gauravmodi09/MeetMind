import Foundation

@MainActor
class SpaceService: ObservableObject {
    static let shared = SpaceService()

    @Published var spaces: [Space] = []

    private let key = "meetmind_spaces"

    init() { loadSpaces() }

    func loadSpaces() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([Space].self, from: data) {
            spaces = decoded
        }
        // Ensure default space exists
        if !spaces.contains(where: { $0.isDefault }) {
            spaces.insert(Space.defaultSpace, at: 0)
            saveSpaces()
        }
    }

    func addSpace(_ space: Space) {
        spaces.append(space)
        saveSpaces()
    }

    func deleteSpace(_ space: Space) {
        guard !space.isDefault else { return }
        spaces.removeAll { $0.id == space.id }
        saveSpaces()
    }

    func addMeeting(_ meetingId: UUID, to spaceId: UUID) {
        guard let idx = spaces.firstIndex(where: { $0.id == spaceId }) else { return }
        if !spaces[idx].meetingIds.contains(meetingId) {
            spaces[idx].meetingIds.append(meetingId)
            saveSpaces()
        }
    }

    func removeMeeting(_ meetingId: UUID, from spaceId: UUID) {
        guard let idx = spaces.firstIndex(where: { $0.id == spaceId }) else { return }
        spaces[idx].meetingIds.removeAll { $0 == meetingId }
        saveSpaces()
    }

    func space(for meetingId: UUID) -> Space? {
        spaces.first { $0.meetingIds.contains(meetingId) }
    }

    private func saveSpaces() {
        if let data = try? JSONEncoder().encode(spaces) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
