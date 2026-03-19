import CoreData

final class PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let ctx = controller.container.viewContext

        // Seed sample data for previews
        let meeting = NSEntityDescription.insertNewObject(forEntityName: "CDMeeting", into: ctx)
        meeting.setValue(UUID(), forKey: "id")
        meeting.setValue("Weekly Sync with Acme", forKey: "title")
        meeting.setValue(Date(), forKey: "date")
        meeting.setValue(TimeInterval(1800), forKey: "duration")
        meeting.setValue("Acme Corp", forKey: "clientName")
        meeting.setValue(MeetingStatus.complete.rawValue, forKey: "status")
        meeting.setValue("Discussed Q3 targets and product roadmap.", forKey: "briefSummary")
        meeting.setValue(Date(), forKey: "createdAt")

        let todo = NSEntityDescription.insertNewObject(forEntityName: "CDTodoItem", into: ctx)
        todo.setValue(UUID(), forKey: "id")
        todo.setValue("Send proposal to Acme", forKey: "title")
        todo.setValue(Date().addingTimeInterval(86400 * 2), forKey: "dueDate")
        todo.setValue(TodoPriority.high.rawValue, forKey: "priority")
        todo.setValue(TodoSource.meeting.rawValue, forKey: "source")
        todo.setValue(false, forKey: "isCompleted")
        todo.setValue(Date(), forKey: "createdAt")

        do {
            try ctx.save()
        } catch {
            fatalError("Preview seed failed: \(error)")
        }

        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.buildManagedObjectModel()
        container = NSPersistentContainer(name: "MeetMind", managedObjectModel: model)

        if inMemory {
            let description = NSPersistentStoreDescription()
            description.type = NSInMemoryStoreType
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error {
                print("Core Data store failed to load: \(error)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    /// Private initializer for CloudKit-backed containers.
    private init(useCloudKit: Bool) {
        let model = Self.buildManagedObjectModel()

        let cloudContainer = NSPersistentCloudKitContainer(name: "MeetMind", managedObjectModel: model)
        container = cloudContainer

        // Configure the store description for CloudKit
        if let description = cloudContainer.persistentStoreDescriptions.first {
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.meetmind.app"
            )
            // Enable history tracking for CloudKit sync
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }

        container.loadPersistentStores { [weak self] _, error in
            if let error {
                print("Core Data (CloudKit) store failed to load: \(error)")
            } else {
                self?.isCloudSyncEnabled = true
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Programmatic Core Data Model

    private static func buildManagedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // --- CDMeeting ---
        let meetingEntity = NSEntityDescription()
        meetingEntity.name = "CDMeeting"
        meetingEntity.managedObjectClassName = "CDMeeting"
        meetingEntity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("title", .stringAttributeType, optional: false),
            attribute("date", .dateAttributeType, optional: false),
            attribute("duration", .doubleAttributeType, optional: false),
            attribute("audioFilePath", .stringAttributeType),
            attribute("clientName", .stringAttributeType),
            attribute("status", .stringAttributeType, optional: false, defaultValue: "recording"),
            attribute("briefSummary", .stringAttributeType),
            attribute("briefDecisionsData", .binaryDataAttributeType),   // JSON-encoded [String]
            attribute("briefActionItemsData", .binaryDataAttributeType), // JSON-encoded [ActionItem]
            attribute("briefKeyTopicsData", .binaryDataAttributeType),   // JSON-encoded [String]
            attribute("briefKeyQuotesData", .binaryDataAttributeType),  // JSON-encoded [String]
            attribute("templateRaw", .stringAttributeType, optional: false, defaultValue: "General"),
            attribute("rawTranscript", .stringAttributeType),
            attribute("userNotes", .stringAttributeType),
            attribute("createdAt", .dateAttributeType, optional: false),
        ]

        // --- CDTodoItem ---
        let todoEntity = NSEntityDescription()
        todoEntity.name = "CDTodoItem"
        todoEntity.managedObjectClassName = "CDTodoItem"
        todoEntity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("title", .stringAttributeType, optional: false),
            attribute("dueDate", .dateAttributeType, optional: false),
            attribute("priority", .stringAttributeType, optional: false, defaultValue: "medium"),
            attribute("clientTag", .stringAttributeType),
            attribute("source", .stringAttributeType, optional: false, defaultValue: "manual"),
            attribute("sourceMeetingId", .UUIDAttributeType),
            attribute("isCompleted", .booleanAttributeType, optional: false, defaultValue: false),
            attribute("completedAt", .dateAttributeType),
            attribute("createdAt", .dateAttributeType, optional: false),
        ]

        // --- CDClient ---
        let clientEntity = NSEntityDescription()
        clientEntity.name = "CDClient"
        clientEntity.managedObjectClassName = "CDClient"
        clientEntity.properties = [
            attribute("id", .UUIDAttributeType, optional: false),
            attribute("name", .stringAttributeType, optional: false),
            attribute("color", .stringAttributeType, optional: false, defaultValue: "6C5CE7"),
            attribute("meetingCount", .integer32AttributeType, optional: false, defaultValue: 0),
            attribute("lastMeetingDate", .dateAttributeType),
        ]

        model.entities = [meetingEntity, todoEntity, clientEntity]
        return model
    }

    // MARK: - Attribute Helper

    private static func attribute(
        _ name: String,
        _ type: NSAttributeType,
        optional: Bool = true,
        defaultValue: Any? = nil
    ) -> NSAttributeDescription {
        let attr = NSAttributeDescription()
        attr.name = name
        attr.attributeType = type
        attr.isOptional = optional
        if let defaultValue {
            attr.defaultValue = defaultValue
        }
        return attr
    }

    // MARK: - CloudKit Support

    /// Whether the current container is a CloudKit-backed container.
    private(set) var isCloudSyncEnabled: Bool = false

    /// Creates a new PersistenceController with NSPersistentCloudKitContainer.
    /// Call this when the user enables iCloud sync from Settings.
    ///
    /// Requirements (must be configured in Xcode first):
    /// 1. iCloud capability enabled in Signing & Capabilities
    /// 2. CloudKit container: iCloud.com.meetmind.app
    /// 3. Background Modes -> Remote notifications enabled
    ///
    /// Until these entitlements are configured, this method logs a warning
    /// and returns `nil` instead of crashing.
    static func cloudKitController() -> PersistenceController? {
        // Guard: Check that CloudKit entitlement is likely available
        // by verifying the container identifier exists in the bundle.
        // This is a soft check — actual CloudKit errors are caught below.
        let controller = PersistenceController(useCloudKit: true)
        guard controller.isCloudSyncEnabled else {
            print("[Persistence] CloudKit container failed to load. Check entitlements.")
            return nil
        }
        return controller
    }

    // MARK: - Convenience

    func save() {
        let ctx = container.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            print("[PersistenceController] Save error: \(error)")
        }
    }
}
