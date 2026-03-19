import Foundation
import Network
import Combine

// MARK: - Queued Meeting Item

struct QueuedMeeting: Codable, Identifiable {
    let id: UUID
    let meetingId: UUID
    let audioPath: String
    let enqueuedAt: Date

    init(meetingId: UUID, audioURL: URL) {
        self.id = UUID()
        self.meetingId = meetingId
        self.audioPath = audioURL.path
        self.enqueuedAt = Date()
    }

    var audioURL: URL {
        URL(fileURLWithPath: audioPath)
    }
}

// MARK: - Offline Queue Service

@MainActor
class OfflineQueueService: ObservableObject {
    static let shared = OfflineQueueService()

    // MARK: - Published State

    @Published var isOnline: Bool = true
    @Published var queuedCount: Int = 0
    @Published var isProcessingQueue: Bool = false

    // MARK: - Private

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.meetmind.networkmonitor")
    private let queueKey = "meetmind_offline_queue"
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    private init() {
        queuedCount = loadQueue().count
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

                print("[OfflineQueue] Network status: \(self.isOnline ? "online" : "offline")")

                // When connectivity returns, automatically process the queue
                if wasOffline && self.isOnline && self.queuedCount > 0 {
                    await self.processQueue()
                }
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - Enqueue

    /// Adds a meeting to the offline queue for processing when connectivity returns.
    func enqueue(meetingId: UUID, audioURL: URL) {
        var items = loadQueue()
        // Don't double-enqueue the same meeting
        guard !items.contains(where: { $0.meetingId == meetingId }) else {
            print("[OfflineQueue] Meeting \(meetingId) already in queue. Skipping.")
            return
        }

        let item = QueuedMeeting(meetingId: meetingId, audioURL: audioURL)
        items.append(item)
        saveQueue(items)
        queuedCount = items.count

        print("[OfflineQueue] Enqueued meeting \(meetingId). Queue size: \(items.count)")
    }

    // MARK: - Process Queue

    /// Processes all queued meetings sequentially. Called automatically when network returns.
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

        var items = loadQueue()

        while !items.isEmpty && isOnline {
            let item = items[0]
            print("[OfflineQueue] Processing queued meeting: \(item.meetingId)")

            // Verify audio file still exists
            guard FileManager.default.fileExists(atPath: item.audioPath) else {
                print("[OfflineQueue] Audio file missing: \(item.audioPath). Removing from queue.")
                items.removeFirst()
                saveQueue(items)
                queuedCount = items.count
                continue
            }

            // Post notification so MeetingService can run the pipeline
            NotificationCenter.default.post(
                name: .offlineQueueItemReady,
                object: nil,
                userInfo: [
                    "meetingId": item.meetingId,
                    "audioURL": item.audioURL
                ]
            )

            // Small delay to let the pipeline pick up the item
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            // Remove the item from queue (pipeline handles success/failure)
            items.removeFirst()
            saveQueue(items)
            queuedCount = items.count

            // Post completion notification
            NotificationCenter.default.post(
                name: .offlineQueueItemCompleted,
                object: nil,
                userInfo: ["meetingId": item.meetingId]
            )

            print("[OfflineQueue] Dequeued meeting \(item.meetingId). Remaining: \(items.count)")
        }

        if items.isEmpty {
            print("[OfflineQueue] Queue fully processed.")
        }
    }

    // MARK: - Queue Management

    func getQueuedItems() -> [QueuedMeeting] {
        loadQueue()
    }

    func removeItem(meetingId: UUID) {
        var items = loadQueue()
        items.removeAll { $0.meetingId == meetingId }
        saveQueue(items)
        queuedCount = items.count
    }

    func clearQueue() {
        saveQueue([])
        queuedCount = 0
        print("[OfflineQueue] Queue cleared.")
    }

    // MARK: - Persistence (UserDefaults JSON)

    private func loadQueue() -> [QueuedMeeting] {
        guard let data = UserDefaults.standard.data(forKey: queueKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([QueuedMeeting].self, from: data)
        } catch {
            print("[OfflineQueue] Failed to decode queue: \(error.localizedDescription)")
            return []
        }
    }

    private func saveQueue(_ items: [QueuedMeeting]) {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: queueKey)
        } catch {
            print("[OfflineQueue] Failed to save queue: \(error.localizedDescription)")
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let offlineQueueItemReady = Notification.Name("offlineQueueItemReady")
    static let offlineQueueItemCompleted = Notification.Name("offlineQueueItemCompleted")
}
