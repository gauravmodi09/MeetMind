import Foundation
import CoreData
import Combine
import UserNotifications
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

@MainActor
class MeetingService: ObservableObject {
    static let shared = MeetingService()

    // MARK: - Published State

    @Published var meetings: [Meeting] = []
    @Published var currentRecording: Meeting?
    @Published var processingState: MeetingPipeline.ProcessingState = .idle

    // MARK: - Dependencies

    private let recorder = AudioRecordingService.shared
    private let pipeline = MeetingPipeline()
    private let persistence = PersistenceController.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    private init() {
        // Forward pipeline state
        pipeline.$processingState
            .receive(on: DispatchQueue.main)
            .assign(to: &$processingState)

        // Listen for max-duration events
        NotificationCenter.default.addObserver(
            forName: AudioRecordingService.maxDurationReachedNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.stopRecording()
            }
        }

        loadMeetings()

        // Seed sample data for demo/walkthrough
        if meetings.isEmpty {
            seedSampleMeetings()
        }
    }

    // MARK: - Sample Data

    private func seedSampleMeetings() {
        let samples: [Meeting] = [
            Meeting(
                title: "Strategic Planning — Meyer Account",
                date: Date().addingTimeInterval(-3600 * 2),
                duration: 2700,
                clientName: "Meyer",
                status: .complete,
                template: .salesCall,
                briefSummary: """
                # Strategic Planning for Meyer Account: POC Readout and Transformation Roadmap

                **Attendees:** **Mitchell** (Databricks), **Gaurav** (Celebal)
                **Type:** Sales Call

                ---

                ## TL;DR
                **Maju** wants to expand the Celebal team with 6 more engineers. The Metrics View POC is progressing well but blocked on table access. Team agreed on a hybrid approach — keep UI filters in Power BI while migrating core transformations to Databricks. Final POC readout targeted for week of **March 26th**.

                ## Key Decisions
                - **Adopt hybrid POC approach** — decided by **Mitchell** and **Gaurav**. Keep presentation-layer logic in Power BI, core metrics in Databricks.
                - **Use self-service workspace for testing** — decided by **Gaurav**. Bypass production deployment bottleneck.
                - **Target POC readout for March 26th** — pending resolution of table access blocker.

                ## Action Items
                | Task | Owner | Due | Priority |
                |------|-------|-----|----------|
                | Create summary presentation for David | **Gaurav** | Tomorrow | High |
                | Talk to Pankaj about self-service workspace | **Gaurav** | This week | High |
                | Send self-service workspace role name | **Mitchell** | This week | Medium |
                | Follow up on remaining table access | **Gaurav** | ASAP | High |
                | Schedule whiteboarding session | **Mitchell** | Next week | Medium |

                ## Discussion Notes

                ### POC Progress and Client Feedback
                - **Maju** gave overwhelmingly positive feedback and wants to expand Celebal team with **6 additional engineers**
                - Successfully converted many measures into Metric Views
                - Stuck waiting for access to **4-5 more tables** — stalled for over a week
                - Testing uses sample data which often results in zero records after filters

                ### Technical Debt in AAS Models
                - **Gaurav** was transparent with **Maju** about poor design in existing AAS models
                - Multi-level dependencies creating complexity
                - **Maju** acknowledged and agreed with the assessment

                ### Presentation Planning
                - **Gaurav** to create summary presentation using GenSpark
                - Key messages: POC successful, AAS issues uncovered, hybrid model recommended

                ## Open Questions
                - What is the full scope of Teradata migration without profile analyzer data?
                - How will COBOL mainframe applications be handled in the migration?
                - When will the remaining 4-5 tables be accessible?

                ## Blockers & Risks
                - **Table Access**: Primary blocker — 4-5 remaining tables needed to complete development
                - **Production Push Process**: Formal CRQ process creates multi-day deployment delays
                - **Legacy Tech Debt**: COBOL applications on mainframe pumping data directly into Teradata
                """,
                briefDecisions: [
                    "Adopt hybrid POC approach — keep UI filters in Power BI, core metrics in Databricks",
                    "Use self-service workspace for testing to bypass production deployment bottleneck",
                    "Target final POC readout for week of March 26th",
                    "Gaurav to own summary presentation development"
                ],
                briefActionItems: [
                    ActionItem(text: "Create summary presentation for David by tomorrow", owner: "Gaurav", isMine: true),
                    ActionItem(text: "Talk to Pankaj about self-service workspace access", owner: "Gaurav", isMine: true),
                    ActionItem(text: "Send self-service workspace role name", owner: "Mitchell"),
                    ActionItem(text: "Follow up on remaining table access", owner: "Gaurav", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), isMine: true),
                    ActionItem(text: "Schedule in-person whiteboarding session", owner: "Mitchell")
                ],
                briefKeyTopics: ["Meyer Account", "Metrics View POC", "Databricks Migration", "Azure Analysis Services", "Teradata Profiling"],
                briefKeyQuotes: [
                    "Mitchell: That's the biggest compliment I think you can get — they want Celebal engineers embedded in every team.",
                    "Gaurav: I was transparent with Maju — your AAS models are not up to the mark. He agreed.",
                    "Mitchell: I don't want to sign up for things we can't actually deliver."
                ],
                rawTranscript: "Mitchell: Hey Gaurav. You and I are becoming good friends. Gaurav: Yeah, we're connecting on a daily basis...",
                createdAt: Date().addingTimeInterval(-3600 * 2)
            ),

            Meeting(
                title: "Databricks Cost Optimization — ART Sync",
                date: Date().addingTimeInterval(-86400),
                duration: 2400,
                clientName: "Databricks",
                status: .complete,
                template: .general,
                briefSummary: """
                MEETING TITLE
                ART Weekly Sync — Databricks Cost Optimization Results

                EXECUTIVE SUMMARY
                The ART team reviewed the results of a major cost optimization effort for the Databricks platform. The team identified $370,000 in annualized list price savings by eliminating sloppy compute behaviors and right-sizing clusters. While this temporarily impacts consumption numbers, it strengthens the partnership and credibility with the client.

                KEY DISCUSSION POINTS

                Optimization Results
                The team found approximately $370,000 of list price annualized Databricks savings. Realistically, this translates to a couple hundred dollars per day in reduced spend in the near term. The savings came from identifying and eliminating inefficient compute patterns.

                Impact on Consumption
                The optimization has hit consumption numbers slightly, but the team views this positively. It demonstrates willingness to sacrifice short-term revenue for long-term partnership health.

                KEY DECISIONS
                1. Continue monitoring consumption post-optimization to track impact
                2. Document the optimization methodology for reuse with other clients
                3. Present savings to client as a trust-building exercise

                ACTION ITEMS
                - Gaurav: Send spot instance config doc by Thursday
                - Alex: Lead capacity testing for the new cluster configurations
                - Team: Prepare weekly consumption report with optimization impact overlay
                """,
                briefDecisions: [
                    "Continue monitoring consumption post-optimization",
                    "Document optimization methodology for reuse",
                    "Present savings to client as trust-building exercise"
                ],
                briefActionItems: [
                    ActionItem(text: "Send spot instance config doc", owner: "Gaurav", dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()), isMine: true),
                    ActionItem(text: "Lead capacity testing for new cluster configurations", owner: "Alex"),
                    ActionItem(text: "Prepare weekly consumption report", owner: "Team", isMine: true)
                ],
                briefKeyTopics: ["Cost Optimization", "Spot Instances", "Cluster Configuration", "Consumption Metrics"],
                briefKeyQuotes: [
                    "Mitchell: We found $370K of annualized Databricks savings — that's credibility you can't buy."
                ],
                createdAt: Date().addingTimeInterval(-86400)
            ),

            Meeting(
                title: "Meijer BTEQ Migration — Technical Deep Dive",
                date: Date().addingTimeInterval(-86400 * 2),
                duration: 3600,
                clientName: "Meijer",
                status: .complete,
                template: .discovery,
                briefSummary: """
                MEETING TITLE
                Meijer BTEQ Migration — Technical Architecture Review

                EXECUTIVE SUMMARY
                The team conducted a deep dive into Meijer's BTEQ to Databricks migration. DML operations dominate the current workload. The team discussed the profiling approach and identified key challenges around legacy mainframe COBOL applications that pump data directly into Teradata.

                KEY DISCUSSION POINTS

                Current State Analysis
                Meijer's Teradata environment is heavily dependent on BTEQ scripts with complex DML operations. The inventory analysis shows significant technical debt accumulated over 20 years of incremental changes.

                Migration Challenges
                Adam Fenton from Meijer highlighted that critical business logic sits in COBOL applications on the mainframe, pumping data directly into Teradata. This adds complexity beyond what was initially scoped.

                KEY DECISIONS
                1. Prioritize DML-heavy operations for first migration wave
                2. COBOL dependency analysis required before committing to timeline
                3. Profile analyzer deployment must happen before detailed planning

                ACTION ITEMS
                - Gaurav: Complete inventory analysis of remaining BTEQ scripts
                - Pankaj: Set up profile analyzer in Meijer's environment
                - Team: Document COBOL-to-Teradata data flows for impact assessment
                """,
                briefDecisions: [
                    "Prioritize DML-heavy operations for first migration wave",
                    "COBOL dependency analysis required before timeline commitment",
                    "Profile analyzer deployment must precede detailed planning"
                ],
                briefActionItems: [
                    ActionItem(text: "Complete inventory analysis of remaining BTEQ scripts", owner: "Gaurav", isMine: true),
                    ActionItem(text: "Set up profile analyzer in Meijer environment", owner: "Pankaj"),
                    ActionItem(text: "Document COBOL-to-Teradata data flows", owner: "Team", isMine: true)
                ],
                briefKeyTopics: ["BTEQ Migration", "Teradata", "COBOL", "Profile Analyzer", "DML Operations"],
                createdAt: Date().addingTimeInterval(-86400 * 2)
            ),

            Meeting(
                title: "Weekly 1:1 — Career Growth Discussion",
                date: Date().addingTimeInterval(-86400 * 3),
                duration: 1800,
                status: .complete,
                template: .oneOnOne,
                briefSummary: """
                MEETING TITLE
                Weekly 1:1 with David — Career Growth and Project Updates

                EXECUTIVE SUMMARY
                A productive 1:1 covering project updates and career development. David shared positive feedback from client meetings and discussed plans for team expansion. The conversation also covered professional development goals for the next quarter.

                KEY DISCUSSION POINTS

                Project Updates
                All current projects are on track. The Meyer POC is progressing well despite table access delays. The Databricks optimization work received positive client feedback.

                Career Development
                Discussed goals for the next quarter including taking on more client-facing leadership roles and potentially mentoring new team members. David encouraged pursuing the Databricks certification.

                KEY DECISIONS
                1. Take lead on the next client presentation
                2. Start Databricks certification preparation
                3. Mentor Sakshi during her onboarding

                ACTION ITEMS
                - Gaurav: Register for Databricks Data Engineer certification
                - Gaurav: Prepare outline for Meyer client presentation
                - David: Share the Gantt chart draft for review
                """,
                briefDecisions: [
                    "Take lead on next client presentation",
                    "Start Databricks certification preparation",
                    "Mentor Sakshi during onboarding"
                ],
                briefActionItems: [
                    ActionItem(text: "Register for Databricks Data Engineer certification", owner: "Gaurav", dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date()), isMine: true),
                    ActionItem(text: "Prepare outline for Meyer client presentation", owner: "Gaurav", isMine: true),
                    ActionItem(text: "Share Gantt chart draft for review", owner: "David")
                ],
                briefKeyTopics: ["Career Growth", "Databricks Certification", "Team Expansion", "Client Leadership"],
                createdAt: Date().addingTimeInterval(-86400 * 3)
            ),

            Meeting(
                title: "Data Science Hackathon Planning",
                date: Date().addingTimeInterval(-86400 * 5),
                duration: 2100,
                clientName: "Databricks",
                status: .complete,
                template: .brainstorm,
                briefSummary: """
                MEETING TITLE
                Data Science Hackathon Planning — Office Hours and Submission Requirements

                EXECUTIVE SUMMARY
                Mitchell is hosting 10 hours of office hours for an upcoming data science hackathon at the client site. A key requirement for hackathon submission is meeting with Mitchell first, which demonstrates the strength of the Databricks partnership. The team discussed logistics, judging criteria, and how to maximize the hackathon's impact.

                KEY DISCUSSION POINTS

                Hackathon Structure
                The hackathon is next week with 10 hours of office hours on Mitchell's calendar. The requirement to meet with Mitchell before submitting is unusual and shows deep client trust.

                Judging Criteria
                Projects will be evaluated on innovation, technical implementation, business impact, and presentation quality. Teams must use Databricks platform features.

                KEY DECISIONS
                1. Mitchell to host all 10 hours of office hours
                2. Focus office hours on helping teams leverage advanced Databricks features
                3. Document successful patterns for future hackathons

                ACTION ITEMS
                - Mitchell: Prepare office hours agenda and example notebooks
                - Gaurav: Create a quick-start guide for common Databricks patterns
                - Team: Set up demo environment for hackathon participants
                """,
                briefDecisions: [
                    "Mitchell to host all 10 hours of office hours",
                    "Focus on helping teams leverage advanced Databricks features",
                    "Document successful patterns for future hackathons"
                ],
                briefActionItems: [
                    ActionItem(text: "Create quick-start guide for common Databricks patterns", owner: "Gaurav", isMine: true),
                    ActionItem(text: "Set up demo environment for hackathon participants", owner: "Team", isMine: true),
                    ActionItem(text: "Prepare office hours agenda and example notebooks", owner: "Mitchell")
                ],
                briefKeyTopics: ["Hackathon", "Data Science", "Office Hours", "Databricks Platform"],
                briefKeyQuotes: [
                    "Mitchell: How often does a company say go talk to the vendor before you participate? That's super cool."
                ],
                createdAt: Date().addingTimeInterval(-86400 * 5)
            )
        ]

        for meeting in samples {
            saveMeetingToCoreData(meeting)
        }
        loadMeetings()
        print("[MeetingService] Seeded \(samples.count) sample meetings")
    }

    // MARK: - Recording

    func startRecording() throws {
        let url = try recorder.startRecording()

        let meeting = Meeting(
            title: "New Meeting",
            date: Date(),
            audioFilePath: url.lastPathComponent,
            status: .recording
        )
        currentRecording = meeting
    }

    func stopRecording() async {
        guard var meeting = currentRecording else {
            print("[MeetingService] stopRecording: No currentRecording found!")
            return
        }

        // Audio already stopped by RecordingView — get URL from meeting
        let audioURL: URL
        if let path = meeting.audioFilePath {
            let fullPathURL = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: fullPathURL.path) {
                audioURL = fullPathURL
                print("[MeetingService] Audio file found at full path: \(fullPathURL.path)")
            } else {
                // Try just the filename in Documents
                let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let docsURL = docs.appendingPathComponent(fullPathURL.lastPathComponent)
                if FileManager.default.fileExists(atPath: docsURL.path) {
                    audioURL = docsURL
                    print("[MeetingService] Audio file found in Documents: \(docsURL.path)")
                } else {
                    print("[MeetingService] Audio file NOT found at: \(fullPathURL.path) or \(docsURL.path)")
                    meeting.status = .failed
                    currentRecording = nil
                    saveMeetingToCoreData(meeting)
                    loadMeetings()
                    return
                }
            }
        } else {
            print("[MeetingService] No audioFilePath on meeting!")
            meeting.status = .failed
            currentRecording = nil
            return
        }

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: audioURL.path)[.size] as? Int) ?? 0
        print("[MeetingService] Processing audio: \(audioURL.lastPathComponent) (\(fileSize / 1024)KB)")

        meeting.status = .processing
        currentRecording = nil

        // Persist the meeting immediately as processing
        saveMeetingToCoreData(meeting)
        loadMeetings()

        // Run the AI pipeline
        do {
            print("[MeetingService] Starting AI pipeline...")
            let brief = try await pipeline.process(
                audioURL: audioURL,
                userNotes: meeting.userNotes,
                template: meeting.template
            )
            print("[MeetingService] Pipeline complete! Title: \(brief.title)")

            // Update meeting with brief results
            meeting.status = .complete
            // Prefer the # title from the markdown summary (more descriptive than JSON extraction)
            meeting.title = extractMarkdownTitle(from: brief.summary) ?? brief.title
            meeting.briefSummary = brief.summary
            meeting.briefDecisions = brief.decisions
            meeting.briefKeyTopics = brief.keyTopics
            meeting.clientName = brief.clientName
            meeting.briefKeyQuotes = brief.keyQuotes ?? []
            meeting.rawTranscript = pipeline.lastRawTranscript

            let actionItems: [ActionItem] = brief.actionItems.map { item in
                ActionItem(
                    text: item.text,
                    owner: item.owner,
                    dueDate: parseDateString(item.due),
                    isMine: item.isMine
                )
            }
            meeting.briefActionItems = actionItems
            print("[MeetingService] \(actionItems.count) action items, client: \(brief.clientName ?? "none")")

            // Schedule follow-up reminders for my action items with due dates
            scheduleActionItemReminders(items: actionItems, meetingTitle: meeting.title)

            // Auto-delete audio if setting is enabled
            if UserDefaults.standard.bool(forKey: "autoDeleteAudioAfterProcessing") {
                if let path = meeting.audioFilePath {
                    let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = docsURL.appendingPathComponent(URL(fileURLWithPath: path).lastPathComponent)
                    try? FileManager.default.removeItem(at: fileURL)
                    meeting.audioFilePath = nil
                    print("[MeetingService] Auto-deleted audio: \(fileURL.lastPathComponent)")
                }
            }

            updateMeetingInCoreData(meeting)
            loadMeetings()

            sendBriefReadyNotification(meeting: meeting)

        } catch {
            meeting.status = .failed
            updateMeetingInCoreData(meeting)
            loadMeetings()
            print("[MeetingService] Pipeline FAILED: \(error)")
            print("[MeetingService] Error details: \(error.localizedDescription)")
        }

        pipeline.reset()
    }

    func cancelRecording() {
        if let url = recorder.stopRecording() {
            try? FileManager.default.removeItem(at: url)
        }
        currentRecording = nil
    }

    /// Reprocess a failed meeting — retries the entire AI pipeline from the existing audio file.
    func reprocessMeeting(_ meeting: Meeting) async {
        guard meeting.status == .failed, let path = meeting.audioFilePath else {
            print("[MeetingService] Cannot reprocess: status=\(meeting.status.rawValue), audioPath=\(meeting.audioFilePath ?? "nil")")
            return
        }

        // Find the audio file
        let audioURL: URL
        let fullPathURL = URL(fileURLWithPath: path)
        if FileManager.default.fileExists(atPath: fullPathURL.path) {
            audioURL = fullPathURL
        } else {
            let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let docsURL = docs.appendingPathComponent(fullPathURL.lastPathComponent)
            if FileManager.default.fileExists(atPath: docsURL.path) {
                audioURL = docsURL
            } else {
                print("[MeetingService] Audio file not found for reprocessing")
                return
            }
        }

        var updatedMeeting = meeting
        updatedMeeting.status = .processing
        updateMeetingInCoreData(updatedMeeting)
        loadMeetings()

        do {
            print("[MeetingService] Reprocessing: \(meeting.title)...")
            let brief = try await pipeline.process(
                audioURL: audioURL,
                userNotes: meeting.userNotes,
                template: meeting.template
            )

            updatedMeeting.status = .complete
            updatedMeeting.title = extractMarkdownTitle(from: brief.summary) ?? brief.title
            updatedMeeting.briefSummary = brief.summary
            updatedMeeting.briefDecisions = brief.decisions
            updatedMeeting.briefKeyTopics = brief.keyTopics
            updatedMeeting.clientName = brief.clientName
            updatedMeeting.briefKeyQuotes = brief.keyQuotes ?? []
            updatedMeeting.rawTranscript = pipeline.lastRawTranscript

            let actionItems: [ActionItem] = brief.actionItems.map { item in
                ActionItem(text: item.text, owner: item.owner, dueDate: parseDateString(item.due), isMine: item.isMine)
            }
            updatedMeeting.briefActionItems = actionItems

            // Auto-delete audio if setting is enabled
            if UserDefaults.standard.bool(forKey: "autoDeleteAudioAfterProcessing") {
                if let path = updatedMeeting.audioFilePath {
                    let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let fileURL = docsURL.appendingPathComponent(URL(fileURLWithPath: path).lastPathComponent)
                    try? FileManager.default.removeItem(at: fileURL)
                    updatedMeeting.audioFilePath = nil
                    print("[MeetingService] Auto-deleted audio: \(fileURL.lastPathComponent)")
                }
            }

            updateMeetingInCoreData(updatedMeeting)
            loadMeetings()
            sendBriefReadyNotification(meeting: updatedMeeting)
        } catch {
            updatedMeeting.status = .failed
            updateMeetingInCoreData(updatedMeeting)
            loadMeetings()
            print("[MeetingService] Reprocessing FAILED: \(error)")
        }

        pipeline.reset()
    }

    // MARK: - CRUD

    func loadMeetings() {
        let ctx = persistence.container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDMeeting")
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]

        do {
            let results = try ctx.fetch(request)
            meetings = results.compactMap { meetingFromManagedObject($0) }
        } catch {
            print("[MeetingService] Fetch error: \(error)")
            meetings = []
        }
    }

    func deleteMeeting(_ meeting: Meeting) {
        // Delete audio file
        if let path = meeting.audioFilePath {
            let docsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = docsURL.appendingPathComponent(path)
            try? FileManager.default.removeItem(at: fileURL)
        }

        // Delete from Core Data
        let ctx = persistence.container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDMeeting")
        request.predicate = NSPredicate(format: "id == %@", meeting.id as CVarArg)

        if let results = try? ctx.fetch(request), let obj = results.first {
            ctx.delete(obj)
            persistence.save()
        }

        loadMeetings()
    }

    func copyBrief(_ meeting: Meeting) {
        // The summary now contains the full rich markdown document (Genspark-level)
        // Just copy it directly — it's already formatted for email/Slack
        var text = ""

        if let summary = meeting.briefSummary, !summary.isEmpty {
            text = summary
        } else {
            // Fallback to structured format if no rich summary
            text = "# \(meeting.title)\n"
            text += "\(formattedDate(meeting.date)) | \(formattedDuration(meeting.duration))\n\n"

            if !meeting.briefDecisions.isEmpty {
                text += "## Decisions\n"
                for decision in meeting.briefDecisions {
                    text += "- \(decision)\n"
                }
                text += "\n"
            }

            if !meeting.briefActionItems.isEmpty {
                text += "## Action Items\n"
                for item in meeting.briefActionItems {
                    let mine = item.isMine ? " [MINE]" : ""
                    let owner = item.owner.isEmpty ? "" : " (\(item.owner))"
                    text += "- \(item.text)\(owner)\(mine)\n"
                }
                text += "\n"
            }
        }

        if !meeting.briefKeyTopics.isEmpty {
            text += "\n## Key Topics\n"
            for topic in meeting.briefKeyTopics {
                text += "- \(topic)\n"
            }
        }

        #if canImport(UIKit)
        UIPasteboard.general.string = text
        #elseif canImport(AppKit)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }

    // MARK: - Client Folders

    func getClientFolders() -> [Client] {
        let clientNames = Set(meetings.compactMap { $0.clientName })
        return clientNames.sorted().map { name in
            let clientMeetings = meetings.filter { $0.clientName == name }
            return Client(
                name: name,
                meetingCount: clientMeetings.count,
                lastMeetingDate: clientMeetings.first?.date
            )
        }
    }

    func meetings(for client: Client) -> [Meeting] {
        meetings.filter { $0.clientName == client.name }
    }

    // MARK: - Action Item Tracking

    /// All action items across all meetings, paired with their source meeting.
    var allActionItems: [(item: ActionItem, meeting: Meeting)] {
        meetings.flatMap { meeting in
            meeting.briefActionItems.map { (item: $0, meeting: meeting) }
        }
    }

    /// Toggle the completion state of an action item within a meeting.
    func toggleActionItemCompletion(meetingId: UUID, actionItemId: UUID) {
        guard let meetingIndex = meetings.firstIndex(where: { $0.id == meetingId }),
              let itemIndex = meetings[meetingIndex].briefActionItems.firstIndex(where: { $0.id == actionItemId }) else {
            return
        }
        meetings[meetingIndex].briefActionItems[itemIndex].isCompleted.toggle()
        updateMeetingInCoreData(meetings[meetingIndex])
    }

    // MARK: - Client Management (MM-032/MM-033)

    func updateMeetingClient(_ meeting: Meeting, newClient: String?) {
        guard let index = meetings.firstIndex(where: { $0.id == meeting.id }) else { return }
        meetings[index].clientName = newClient
        updateMeetingInCoreData(meetings[index])
    }

    func renameClient(from oldName: String, to newName: String) {
        for i in meetings.indices {
            if meetings[i].clientName == oldName {
                meetings[i].clientName = newName
                updateMeetingInCoreData(meetings[i])
            }
        }
    }

    func mergeClientIntoGeneral(_ clientName: String) {
        for i in meetings.indices {
            if meetings[i].clientName == clientName {
                meetings[i].clientName = nil
                updateMeetingInCoreData(meetings[i])
            }
        }
        loadMeetings()
    }

    var allClientNames: [String] {
        var names = Set(meetings.compactMap { $0.clientName })
        let manual = UserDefaults.standard.stringArray(forKey: "manualClients") ?? []
        names.formUnion(manual)
        return names.sorted()
    }

    // MARK: - Action Item Reminders (MM-078)

    private func scheduleActionItemReminders(items: [ActionItem], meetingTitle: String) {
        let center = UNUserNotificationCenter.current()

        for item in items where item.isMine && item.dueDate != nil {
            guard let dueDate = item.dueDate else { continue }
            let calendar = Calendar.current

            // 1) Reminder 1 day before due date
            if let dayBefore = calendar.date(byAdding: .day, value: -1, to: dueDate),
               dayBefore > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Reminder: Due Tomorrow"
                content.body = "\(item.text) -- due tomorrow (from \(meetingTitle))"
                content.sound = .default
                content.categoryIdentifier = "ACTION_ITEM_REMINDER"

                var components = calendar.dateComponents([.year, .month, .day], from: dayBefore)
                components.hour = 9
                components.minute = 0
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                let id = "action-item-dayBefore-\(item.id.uuidString)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request) { error in
                    if let error {
                        print("[MeetingService] Failed to schedule day-before reminder: \(error)")
                    }
                }
            }

            // 2) Reminder on the morning of the due date
            if dueDate > Date() {
                let content = UNMutableNotificationContent()
                content.title = "Due Today"
                content.body = "\(item.text) (from \(meetingTitle))"
                content.sound = .default
                content.categoryIdentifier = "ACTION_ITEM_DUE"

                var components = calendar.dateComponents([.year, .month, .day], from: dueDate)
                components.hour = 8
                components.minute = 30
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

                let id = "action-item-dueDay-\(item.id.uuidString)"
                let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                center.add(request) { error in
                    if let error {
                        print("[MeetingService] Failed to schedule due-day reminder: \(error)")
                    }
                }
            }
        }
    }

    // MARK: - Core Data Helpers

    private func saveMeetingToCoreData(_ meeting: Meeting) {
        let ctx = persistence.container.viewContext
        let obj = NSEntityDescription.insertNewObject(forEntityName: "CDMeeting", into: ctx)

        applyMeetingValues(meeting, to: obj)
        persistence.save()
    }

    private func updateMeetingInCoreData(_ meeting: Meeting) {
        let ctx = persistence.container.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "CDMeeting")
        request.predicate = NSPredicate(format: "id == %@", meeting.id as CVarArg)

        guard let results = try? ctx.fetch(request), let obj = results.first else {
            saveMeetingToCoreData(meeting)
            return
        }

        applyMeetingValues(meeting, to: obj)
        persistence.save()
    }

    private func applyMeetingValues(_ meeting: Meeting, to obj: NSManagedObject) {
        obj.setValue(meeting.id, forKey: "id")
        obj.setValue(meeting.title, forKey: "title")
        obj.setValue(meeting.date, forKey: "date")
        obj.setValue(meeting.duration, forKey: "duration")
        obj.setValue(meeting.audioFilePath, forKey: "audioFilePath")
        obj.setValue(meeting.clientName, forKey: "clientName")
        obj.setValue(meeting.status.rawValue, forKey: "status")
        obj.setValue(meeting.briefSummary, forKey: "briefSummary")
        obj.setValue(meeting.rawTranscript, forKey: "rawTranscript")
        obj.setValue(meeting.userNotes, forKey: "userNotes")
        obj.setValue(meeting.createdAt, forKey: "createdAt")

        if let decisionsData = try? JSONEncoder().encode(meeting.briefDecisions) {
            obj.setValue(decisionsData, forKey: "briefDecisionsData")
        }
        if let actionData = try? JSONEncoder().encode(meeting.briefActionItems) {
            obj.setValue(actionData, forKey: "briefActionItemsData")
        }
        if let topicsData = try? JSONEncoder().encode(meeting.briefKeyTopics) {
            obj.setValue(topicsData, forKey: "briefKeyTopicsData")
        }
        if let quotesData = try? JSONEncoder().encode(meeting.briefKeyQuotes) {
            obj.setValue(quotesData, forKey: "briefKeyQuotesData")
        }
        obj.setValue(meeting.template.rawValue, forKey: "templateRaw")
    }

    private func meetingFromManagedObject(_ obj: NSManagedObject) -> Meeting? {
        guard let id = obj.value(forKey: "id") as? UUID,
              let title = obj.value(forKey: "title") as? String,
              let date = obj.value(forKey: "date") as? Date,
              let createdAt = obj.value(forKey: "createdAt") as? Date else {
            return nil
        }

        let statusRaw = obj.value(forKey: "status") as? String ?? "recording"
        let status = MeetingStatus(rawValue: statusRaw) ?? .recording

        var decisions: [String] = []
        if let data = obj.value(forKey: "briefDecisionsData") as? Data {
            decisions = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }

        var actionItems: [ActionItem] = []
        if let data = obj.value(forKey: "briefActionItemsData") as? Data {
            actionItems = (try? JSONDecoder().decode([ActionItem].self, from: data)) ?? []
        }

        var keyTopics: [String] = []
        if let data = obj.value(forKey: "briefKeyTopicsData") as? Data {
            keyTopics = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }

        var keyQuotes: [String] = []
        if let data = obj.value(forKey: "briefKeyQuotesData") as? Data {
            keyQuotes = (try? JSONDecoder().decode([String].self, from: data)) ?? []
        }

        let templateRaw = obj.value(forKey: "templateRaw") as? String ?? MeetingTemplate.general.rawValue
        let template = MeetingTemplate(rawValue: templateRaw) ?? .general

        return Meeting(
            id: id,
            title: title,
            date: date,
            duration: obj.value(forKey: "duration") as? TimeInterval ?? 0,
            audioFilePath: obj.value(forKey: "audioFilePath") as? String,
            clientName: obj.value(forKey: "clientName") as? String,
            status: status,
            template: template,
            briefSummary: obj.value(forKey: "briefSummary") as? String,
            briefDecisions: decisions,
            briefActionItems: actionItems,
            briefKeyTopics: keyTopics,
            briefKeyQuotes: keyQuotes,
            rawTranscript: obj.value(forKey: "rawTranscript") as? String,
            userNotes: obj.value(forKey: "userNotes") as? String,
            createdAt: createdAt
        )
    }

    // MARK: - Notifications

    private func sendBriefReadyNotification(meeting: Meeting) {
        #if canImport(UIKit)
        let state = UIApplication.shared.applicationState
        guard state != .active else { return }
        #endif

        let content = UNMutableNotificationContent()
        content.title = "Meeting Brief Ready"
        content.body = "\(meeting.title) — tap to view"
        content.sound = .default
        content.userInfo = ["meetingId": meeting.id.uuidString, "deepLink": "meetmind://meeting/\(meeting.id)"]

        let request = UNNotificationRequest(
            identifier: "brief-\(meeting.id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("[MeetingService] Notification error: \(error)")
            }
        }
    }

    // MARK: - Formatting Helpers

    private func parseDateString(_ string: String?) -> Date? {
        guard let string, !string.isEmpty, string != "null" else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }

    /// Extracts the # title from markdown summary (first line starting with "# ")
    private func extractMarkdownTitle(from summary: String) -> String? {
        let lines = summary.components(separatedBy: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") && !trimmed.hasPrefix("## ") {
                let title = trimmed.replacingOccurrences(of: "# ", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !title.isEmpty && title.count > 5 {
                    return title
                }
            }
        }
        return nil
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        let s = Int(seconds) % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
