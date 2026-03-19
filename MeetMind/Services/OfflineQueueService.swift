import Foundation
import Network
import Combine

// MARK: - Queued Recording Item

struct QueuedRecording: Codable, Identifiable {
    let id: UUID
    let audioURL: URL
    let userNotes: String?
    let enqueuedAt: Date

    init(audioURL: URL, userNotes: String?) {
        self.id = UUID()
        self.audioURL = audioURL
        self.userNotes = userNotes
        self.enqueuedAt = Date()
    }
}

// MARK: - Offline Queue Service

@MainActor
class OfflineQueueService: ObservableObject {
    static let shared = OfflineQueueService()

    @Published var isOnline: Bool = true
    @Published var queuedCount: Int = 0
    @Published var isProcessingQueue: Bool = false

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.meetmind.networkmonitor")
    private let queueKey = "meetmind_offline_queue"
    private let maxQueueSize = 10

    private var cancellables = Set<AnyCancellable>()

    private init() {
        queuedCount = getQueuedItems().count
        startMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Network Monitoring

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let wasOffline = !self.isOnline
                self.isOnline = path.status == .satisfied

                // When connectivity returns, process the queue
                if wasOffline && self.isOnline {
                    await self.processQueue()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Enqueue Recording

    /// Adds a recording to the offline queue for later processing.
    /// Returns `true` if the item was enqueued, `false` if the queue is full.
    @discardableResult
    func enqueueRecording(audioURL: URL, userNotes: String?) -> Bool {
        var items = getQueuedItems()

        guard items.count < maxQueueSize else {
            print("[OfflineQueue] Queue is full (\(maxQueueSize) items). Cannot enqueue.")
            return false
        }

        let item = QueuedRecording(audioURL: audioURL, userNotes: userNotes)
        items.append(item)
        saveQueue(items)
        queuedCount = items.count

        print("[OfflineQueue] Enqueued recording: \(audioURL.lastPathComponent). Queue size: \(items.count)")
        return true
    }

    // MARK: - Process Queue

    /// Processes queued recordings one by one when connectivity is available.
    func processQueue() async {
        guard isOnline else {
            print("[OfflineQueue] Still offline. Skipping queue processing.")
            return
        }

        guard !isProcessingQueue else {
            print("[OfflineQueue] Already processing queue.")
            return
        }

        isProcessingQueue = true
        defer { isProcessingQueue = false }

        var items = getQueuedItems()

        while !items.isEmpty && isOnline {
            let item = items[0]
            print("[OfflineQueue] Processing: \(item.audioURL.lastPathComponent)")

            do {
                try await uploadRecording(item)
                // Remove the successfully processed item
                items.removeFirst()
                saveQueue(items)
                queuedCount = items.count
                print("[OfflineQueue] Successfully processed. Remaining: \(items.count)")
            } catch {
                print("[OfflineQueue] Failed to process \(item.audioURL.lastPathComponent): \(error.localizedDescription)")
                // Stop processing on failure; will retry when connectivity changes
                break
            }
        }

        if items.isEmpty {
            print("[OfflineQueue] Queue is empty. All items processed.")
        }
    }

    // MARK: - Get Queued Items

    func getQueuedItems() -> [QueuedRecording] {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([QueuedRecording].self, from: data)
        } catch {
            print("[OfflineQueue] Failed to decode queue: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Remove Item

    func removeItem(id: UUID) {
        var items = getQueuedItems()
        items.removeAll { $0.id == id }
        saveQueue(items)
        queuedCount = items.count
    }

    // MARK: - Clear Queue

    func clearQueue() {
        saveQueue([])
        queuedCount = 0
        print("[OfflineQueue] Queue cleared.")
    }

    // MARK: - Private Helpers

    private func saveQueue(_ items: [QueuedRecording]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: queueKey)
        } catch {
            print("[OfflineQueue] Failed to save queue: \(error.localizedDescription)")
        }
    }

    /// Uploads a single recording to the backend.
    /// This is a placeholder that integrates with the existing pipeline.
    private func uploadRecording(_ item: QueuedRecording) async throws {
        // Verify the audio file still exists on disk
        guard FileManager.default.fileExists(atPath: item.audioURL.path) else {
            print("[OfflineQueue] Audio file no longer exists: \(item.audioURL.path). Skipping.")
            return
        }

        // TODO: Integrate with MeetingPipeline or GroqService to process the recording
        // For now, post a notification so the app layer can handle the upload
        NotificationCenter.default.post(
            name: .offlineQueueItemReady,
            object: nil,
            userInfo: [
                "audioURL": item.audioURL,
                "userNotes": item.userNotes as Any,
                "queuedItemId": item.id
            ]
        )

        // Simulate processing delay to avoid overwhelming the server
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let offlineQueueItemReady = Notification.Name("offlineQueueItemReady")
}
