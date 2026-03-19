import BackgroundTasks
import Foundation

/// Manages BGTaskScheduler to process queued recordings in the background.
/// Register in AppDelegate's `didFinishLaunching` or the App's `init`.
///
/// Info.plist must include:
///   BGTaskSchedulerPermittedIdentifiers -> [com.meetmind.processRecording]
class BackgroundTaskService {
    static let shared = BackgroundTaskService()
    static let processingTaskId = "com.meetmind.processRecording"

    private var pipeline: MeetingPipeline?

    private init() {}

    // MARK: - Registration

    /// Call once at app launch (e.g., in MeetMindApp.init or AppDelegate).
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.processingTaskId,
            using: nil
        ) { task in
            guard let processingTask = task as? BGProcessingTask else { return }
            self.handleProcessingTask(processingTask)
        }
        print("[BackgroundTask] Registered task: \(Self.processingTaskId)")
    }

    // MARK: - Scheduling

    /// Schedule a BGProcessingTask to drain the offline queue.
    /// Safe to call multiple times — the system deduplicates by identifier.
    func scheduleProcessing() {
        let request = BGProcessingTaskRequest(identifier: Self.processingTaskId)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        // Allow the system to pick an optimal time within the next hour
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BackgroundTask] Scheduled processing task.")
        } catch {
            print("[BackgroundTask] Failed to schedule: \(error.localizedDescription)")
        }
    }

    // MARK: - Task Handling

    /// Processes queued recordings one-by-one.
    /// Handles expiration gracefully: saves progress and reschedules.
    private func handleProcessingTask(_ task: BGProcessingTask) {
        print("[BackgroundTask] Processing task started.")

        // Reschedule so we keep processing if there are remaining items
        scheduleProcessing()

        let processingTask = Task {
            await processQueuedItems()
        }

        // If the system signals expiration, cancel in-flight work and reschedule
        task.expirationHandler = {
            print("[BackgroundTask] Task expiring — cancelling in-flight work.")
            processingTask.cancel()
            // Reschedule is already done above
        }

        Task {
            // Wait for completion (or cancellation)
            _ = await processingTask.result
            let remaining = await MainActor.run {
                OfflineQueueService.shared.getQueuedItems().count
            }
            let success = remaining == 0
            task.setTaskCompleted(success: success)
            print("[BackgroundTask] Task completed. Remaining items: \(remaining)")
        }
    }

    // MARK: - Queue Processing

    /// Pulls items from OfflineQueueService and runs them through MeetingPipeline.
    private func processQueuedItems() async {
        let items = await MainActor.run {
            OfflineQueueService.shared.getQueuedItems()
        }

        guard !items.isEmpty else {
            print("[BackgroundTask] No queued items to process.")
            return
        }

        for item in items {
            // Check for cancellation between items
            guard !Task.isCancelled else {
                print("[BackgroundTask] Cancelled — stopping after partial processing.")
                return
            }

            // Verify the audio file still exists
            guard FileManager.default.fileExists(atPath: item.audioURL.path) else {
                print("[BackgroundTask] Audio file missing, removing from queue: \(item.audioURL.lastPathComponent)")
                await MainActor.run {
                    OfflineQueueService.shared.removeItem(meetingId: item.meetingId)
                }
                continue
            }

            do {
                // Process through the full pipeline (compress -> transcribe -> structure)
                let p = await MainActor.run { MeetingPipeline() }
                let brief = try await p.process(audioURL: item.audioURL, userNotes: nil)

                // Remove successfully processed item from queue
                await MainActor.run {
                    OfflineQueueService.shared.removeItem(meetingId: item.meetingId)
                }

                print("[BackgroundTask] Processed: \(item.audioURL.lastPathComponent) -> \(brief.title)")

                // Post notification so the app layer can persist the meeting
                NotificationCenter.default.post(
                    name: .backgroundProcessingCompleted,
                    object: nil,
                    userInfo: [
                        "queuedItemId": item.id,
                        "brief": brief,
                        "audioURL": item.audioURL
                    ]
                )

            } catch {
                print("[BackgroundTask] Failed to process \(item.audioURL.lastPathComponent): \(error.localizedDescription)")
                // Stop on first failure — will retry on next scheduled run
                break
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let backgroundProcessingCompleted = Notification.Name("backgroundProcessingCompleted")
}
