import Foundation

/// Manages audio file retention and disk usage tracking.
@MainActor
class StorageManagementService: ObservableObject {
    static let shared = StorageManagementService()

    @Published var totalAudioSize: Int64 = 0  // bytes
    @Published var processedFileCount: Int = 0

    private let fileManager = FileManager.default

    enum RetentionPolicy: String, CaseIterable {
        case sevenDays = "7 days"
        case fourteenDays = "14 days"
        case thirtyDays = "30 days"
        case never = "Never"

        var days: Int? {
            switch self {
            case .sevenDays: return 7
            case .fourteenDays: return 14
            case .thirtyDays: return 30
            case .never: return nil
            }
        }
    }

    private init() {
        calculateDiskUsage()
    }

    // MARK: - Cleanup

    /// Delete audio files older than the given retention policy.
    func cleanupOldAudioFiles(policy: RetentionPolicy) {
        guard let retentionDays = policy.days else {
            print("[Storage] Retention policy is 'Never' — skipping cleanup.")
            return
        }

        let cutoffDate = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? Date()
        let audioFiles = findAudioFiles()
        var deletedCount = 0

        for fileURL in audioFiles {
            guard let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
                  let creationDate = attrs[.creationDate] as? Date else {
                continue
            }

            if creationDate < cutoffDate {
                do {
                    try fileManager.removeItem(at: fileURL)
                    deletedCount += 1
                    print("[Storage] Deleted old audio: \(fileURL.lastPathComponent)")
                } catch {
                    print("[Storage] Failed to delete \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
        }

        print("[Storage] Cleanup complete. Deleted \(deletedCount) file(s).")
        calculateDiskUsage()
    }

    // MARK: - Disk Usage

    /// Scan the Documents directory for .m4a files and update published properties.
    func calculateDiskUsage() {
        let audioFiles = findAudioFiles()
        var totalSize: Int64 = 0
        var count = 0

        for fileURL in audioFiles {
            if let attrs = try? fileManager.attributesOfItem(atPath: fileURL.path),
               let fileSize = attrs[.size] as? Int64 {
                totalSize += fileSize
                count += 1
            }
        }

        totalAudioSize = totalSize
        processedFileCount = count
        print("[Storage] Disk usage: \(formatSize(totalSize)), \(count) file(s)")
    }

    // MARK: - Delete All Processed Audio

    /// One-tap cleanup: removes all .m4a audio files from the Documents directory.
    func deleteAllProcessedAudio() {
        let audioFiles = findAudioFiles()
        var deletedCount = 0

        for fileURL in audioFiles {
            do {
                try fileManager.removeItem(at: fileURL)
                deletedCount += 1
            } catch {
                print("[Storage] Failed to delete \(fileURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        print("[Storage] Deleted all processed audio: \(deletedCount) file(s).")
        calculateDiskUsage()
    }

    // MARK: - Format Size

    /// Formats bytes into a human-readable string (e.g., "23.5 MB").
    func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        formatter.includesUnit = true
        formatter.isAdaptive = true
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Warning Threshold

    /// Returns `true` when total audio usage exceeds 500 MB.
    var isStorageWarning: Bool {
        totalAudioSize > 500 * 1_024 * 1_024
    }

    // MARK: - Private Helpers

    /// Finds all .m4a files in the app's Documents directory.
    private func findAudioFiles() -> [URL] {
        guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return []
        }

        do {
            let contents = try fileManager.contentsOfDirectory(
                at: documentsURL,
                includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
                options: [.skipsHiddenFiles]
            )
            return contents.filter { $0.pathExtension.lowercased() == "m4a" }
        } catch {
            print("[Storage] Failed to enumerate Documents directory: \(error.localizedDescription)")
            return []
        }
    }
}
