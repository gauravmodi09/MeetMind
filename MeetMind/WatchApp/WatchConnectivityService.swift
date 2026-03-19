import Foundation
import WatchConnectivity
import Combine

// MARK: - WatchConnectivity Service (MM-048)
// Handles bidirectional communication between iPhone and Apple Watch.
// On iOS: sends widget data to Watch, receives audio files and todo updates.
// On watchOS: sends audio recordings and todo completions to iPhone.

/// Message keys for Watch <-> iPhone communication.
enum WatchMessageKey {
    static let todoUpdate = "todoUpdate"
    static let todoId = "todoId"
    static let todoCompleted = "isCompleted"
    static let widgetData = "widgetData"
    static let recordingCommand = "recordingCommand"
}

/// Manages WatchConnectivity session for iPhone <-> Apple Watch communication.
class WatchConnectivityService: NSObject, ObservableObject {
    static let shared = WatchConnectivityService()

    // MARK: - Published State

    @Published var isWatchReachable = false
    @Published var isWatchPaired = false
    @Published var isWatchAppInstalled = false
    @Published var transferProgress: Double = 0

    // MARK: - Notifications

    static let audioFileReceivedNotification = Notification.Name("WatchAudioFileReceived")
    static let todoUpdateReceivedNotification = Notification.Name("WatchTodoUpdateReceived")

    // MARK: - Private

    private var session: WCSession?
    private var activeTransfer: WCSessionFileTransfer?

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Activation

    /// Activates the WCSession. Call this early in app lifecycle (e.g., AppDelegate or App.init).
    func activate() {
        guard WCSession.isSupported() else {
            print("[WatchConnectivity] WCSession not supported on this device")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        self.session = session
    }

    // MARK: - Watch -> iPhone: Audio File Transfer

    /// Transfers a recorded audio file from Watch to iPhone.
    /// Uses file transfer (not message) for large audio files.
    /// - Parameter fileURL: Local URL of the recorded audio file.
    func sendAudioToPhone(fileURL: URL) {
        guard let session = session, session.activationState == .activated else {
            print("[WatchConnectivity] Session not activated, cannot send audio")
            return
        }

        let metadata: [String: Any] = [
            "type": "audioRecording",
            "fileName": fileURL.lastPathComponent,
            "timestamp": Date().timeIntervalSince1970
        ]

        let transfer = session.transferFile(fileURL, metadata: metadata)
        activeTransfer = transfer

        DispatchQueue.main.async {
            self.transferProgress = 0
        }

        // Observe transfer progress
        observeTransferProgress(transfer)
    }

    // MARK: - Watch -> iPhone: Todo Update

    /// Sends a todo completion update from Watch to iPhone.
    /// Uses interactive messaging for immediate sync.
    /// - Parameters:
    ///   - todoId: The UUID of the todo item.
    ///   - isCompleted: Whether the todo is now completed.
    func sendTodoUpdate(todoId: UUID, isCompleted: Bool) {
        guard let session = session, session.isReachable else {
            // Fall back to userInfo transfer if not reachable
            let userInfo: [String: Any] = [
                WatchMessageKey.todoUpdate: true,
                WatchMessageKey.todoId: todoId.uuidString,
                WatchMessageKey.todoCompleted: isCompleted
            ]
            session?.transferUserInfo(userInfo)
            return
        }

        let message: [String: Any] = [
            WatchMessageKey.todoUpdate: true,
            WatchMessageKey.todoId: todoId.uuidString,
            WatchMessageKey.todoCompleted: isCompleted
        ]

        session.sendMessage(message, replyHandler: nil) { error in
            print("[WatchConnectivity] Failed to send todo update: \(error.localizedDescription)")
        }
    }

    // MARK: - iPhone -> Watch: Widget Data

    /// Sends widget/complication data from iPhone to Watch.
    /// - Parameter data: The widget data to display on Watch complications.
    func sendWidgetData(_ data: MeetMindWidgetData) {
        guard let session = session, session.activationState == .activated else {
            print("[WatchConnectivity] Session not activated, cannot send widget data")
            return
        }

        do {
            let encoded = try JSONEncoder().encode(data)
            let userInfo: [String: Any] = [
                WatchMessageKey.widgetData: encoded
            ]

            // Use transferCurrentComplicationUserInfo for complication updates
            // (limited to ~50 per day on watchOS)
            if session.isReachable {
                session.sendMessage(userInfo, replyHandler: nil) { error in
                    print("[WatchConnectivity] Failed to send widget data: \(error.localizedDescription)")
                }
            } else {
                session.transferUserInfo(userInfo)
            }
        } catch {
            print("[WatchConnectivity] Failed to encode widget data: \(error.localizedDescription)")
        }
    }

    // MARK: - Transfer Progress Observation

    private func observeTransferProgress(_ transfer: WCSessionFileTransfer) {
        // KVO on progress
        let observation = transfer.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            DispatchQueue.main.async {
                self?.transferProgress = progress.fractionCompleted
            }
        }
        // Store observation to keep it alive (in production, use a Set<AnyCancellable>)
        objc_setAssociatedObject(transfer, "progressObservation", observation, .OBJC_ASSOCIATION_RETAIN)
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityService: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
            #if os(iOS)
            self.isWatchPaired = session.isPaired
            self.isWatchAppInstalled = session.isWatchAppInstalled
            #endif
        }

        if let error = error {
            print("[WatchConnectivity] Activation failed: \(error.localizedDescription)")
        } else {
            print("[WatchConnectivity] Activated with state: \(activationState.rawValue)")
        }
    }

    // Required on iOS only
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("[WatchConnectivity] Session became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("[WatchConnectivity] Session deactivated, reactivating...")
        session.activate()
    }
    #endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isWatchReachable = session.isReachable
        }
    }

    // MARK: - Receiving Files (Audio from Watch)

    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let metadata = file.metadata ?? [:]
        print("[WatchConnectivity] Received file: \(file.fileURL.lastPathComponent), metadata: \(metadata)")

        // Move the file to a permanent location before this method returns
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = metadata["fileName"] as? String ?? "watch_recording_\(Date().timeIntervalSince1970).m4a"
        let destinationURL = documentsURL.appendingPathComponent(fileName)

        do {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: file.fileURL, to: destinationURL)

            DispatchQueue.main.async {
                self.transferProgress = 1.0
                NotificationCenter.default.post(
                    name: Self.audioFileReceivedNotification,
                    object: nil,
                    userInfo: ["fileURL": destinationURL]
                )
            }
        } catch {
            print("[WatchConnectivity] Failed to save received file: \(error.localizedDescription)")
        }
    }

    // MARK: - Receiving Messages (Todo Updates, etc.)

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message[WatchMessageKey.todoUpdate] as? Bool == true {
            handleTodoUpdate(message)
        }

        if let widgetDataBytes = message[WatchMessageKey.widgetData] as? Data {
            handleWidgetData(widgetDataBytes)
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        if userInfo[WatchMessageKey.todoUpdate] as? Bool == true {
            handleTodoUpdate(userInfo)
        }

        if let widgetDataBytes = userInfo[WatchMessageKey.widgetData] as? Data {
            handleWidgetData(widgetDataBytes)
        }
    }

    // MARK: - Message Handlers

    private func handleTodoUpdate(_ info: [String: Any]) {
        guard let todoIdString = info[WatchMessageKey.todoId] as? String,
              let todoId = UUID(uuidString: todoIdString),
              let isCompleted = info[WatchMessageKey.todoCompleted] as? Bool else {
            return
        }

        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Self.todoUpdateReceivedNotification,
                object: nil,
                userInfo: [
                    "todoId": todoId,
                    "isCompleted": isCompleted
                ]
            )
        }
    }

    private func handleWidgetData(_ data: Data) {
        do {
            let widgetData = try JSONDecoder().decode(MeetMindWidgetData.self, from: data)
            print("[WatchConnectivity] Received widget data: \(widgetData.meetingCount) meetings, \(widgetData.pendingTodoCount) todos")
            // Store for Watch complications / UI updates
        } catch {
            print("[WatchConnectivity] Failed to decode widget data: \(error.localizedDescription)")
        }
    }
}
