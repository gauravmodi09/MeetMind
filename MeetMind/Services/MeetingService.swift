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
                title: "Q3 Product Roadmap Review",
                date: Date().addingTimeInterval(-3600 * 2),
                duration: 2700,
                clientName: "Acme Corp",
                status: .complete,
                template: .general,
                briefSummary: """
                # Q3 Product Roadmap Review: Prioritizing Mobile-First Strategy Amid Resource Constraints

                ## Executive Summary

                This planning session focused on defining the product priorities for Q3, with a critical strategic pivot towards a mobile-first approach. The data presented was compelling — **68% of active users** are now accessing the platform via mobile devices, a figure that has grown **15% quarter-over-quarter**. The team made the difficult but necessary decision to defer the API redesign to Q4, acknowledging that the engineering team is operating at full capacity and cannot support both initiatives simultaneously. A significant portion of the discussion centered around the proposed design system investment, which would require **20% of the quarterly budget** but promises to accelerate development velocity by an estimated **40%** in subsequent quarters. Finance approval is still pending for this allocation, creating some uncertainty around the timeline. The meeting concluded with clear ownership assignments and a shared understanding that Q3 is the quarter to win on mobile or risk losing market position.

                ## Meeting Overview

                This quarterly roadmap review brought together the product, engineering, and design leads to align on priorities for the upcoming quarter. The meeting was prompted by recent analytics showing a dramatic shift in user behavior towards mobile, combined with growing pressure from the executive team to demonstrate faster feature delivery. The discussion revealed tensions between ambitious product goals and realistic engineering capacity, ultimately resulting in a pragmatic prioritization framework that focuses resources on the highest-impact initiatives.

                ## The Mobile-First Imperative

                The most significant data point driving the Q3 strategy is the **68% mobile usage figure**. The product team presented a detailed analytics report showing that not only are the majority of users on mobile, but mobile users exhibit **2.3x higher engagement rates** and **35% better retention** compared to desktop users. Despite this, the current mobile experience has been described internally as "adequate but uninspiring." The team discussed several specific improvements including a redesigned navigation pattern for smaller screens, optimized loading times targeting **sub-2-second page loads**, and a new gesture-based interaction model. The design team has already begun prototyping these changes and showed early mockups that received positive feedback. The consensus was clear: if the team doesn't invest heavily in mobile this quarter, competitors who are already mobile-native will continue to erode market share.

                ## Resource Constraints and the Q4 Deferral

                The engineering lead delivered a candid assessment of team capacity. The current team of **12 engineers** is fully allocated across maintenance, bug fixes, and existing feature commitments. Taking on both the mobile redesign and the API overhaul would require either significant overtime or a reduction in quality — neither of which is acceptable. The API redesign, while important for long-term scalability, was deemed less urgent than the mobile initiative because the current API, though not elegant, is functional and stable. The team agreed to use Q3 to complete the mobile work and begin preliminary architecture planning for the API redesign, which would then become the primary focus in Q4 when **two additional senior engineers** are expected to join the team.

                ## Design System Investment Decision

                A heated but productive discussion took place around the proposed investment in a new design system. The design lead made a compelling case that the current ad-hoc approach to UI components is creating inconsistency across the product and slowing down development. Each new feature currently requires **2-3 additional days** of design reconciliation work. The proposed design system would standardize components, establish a shared design language, and enable engineers to build UI **40% faster** once adopted. However, the **20% budget allocation** required has not yet been approved by finance. The team agreed to proceed with planning and component inventory work immediately, while the product lead takes the budget request to the CFO this week. If approved, full implementation would begin mid-quarter.

                ## Key Decisions

                - **Mobile-first is the #1 priority for Q3** — driven by the 68% mobile usage data and competitive pressure. All new feature development will be mobile-first with desktop as secondary.
                - **API redesign deferred to Q4** — a pragmatic decision based on team capacity. Preliminary architecture work will begin in Q3.
                - **Design system budget pending** — the team is proceeding with planning work while the 20% budget allocation awaits finance approval.

                ## Action Items & Next Steps

                - **Product Lead**: Send updated proposal with revised timeline to executive team — this week
                - **Engineering Lead**: Review contract terms with legal for the new hires — by next Friday
                - **Design Lead**: Prepare interactive demo of mobile prototypes for stakeholder review — next week
                - **Product Lead**: Present design system budget request to CFO — this week
                - **Engineering Lead**: Begin preliminary API architecture documentation for Q4 planning — ongoing

                ## Open Questions & Risks

                - When will finance approve the design system budget? Delay could push implementation to Q4.
                - Should the team hire a contractor to supplement mobile redesign capacity?
                - What is the competitive timeline? Are competitors shipping mobile improvements this quarter?
                - Risk: If the design system budget is rejected, the team may face increasing UI inconsistency.
                """,
                briefDecisions: [
                    "Prioritize mobile features for Q3 — 68% of users are on mobile",
                    "Push API redesign to Q4 due to resource constraints",
                    "Allocate 20% of budget to design system"
                ],
                briefActionItems: [
                    ActionItem(text: "Send updated proposal with revised timeline", owner: "Sarah", isMine: true),
                    ActionItem(text: "Review contract terms with legal", owner: "James"),
                    ActionItem(text: "Prepare demo for stakeholder review", owner: "Lisa", dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()), isMine: true)
                ],
                briefKeyTopics: ["Product Roadmap", "Mobile Strategy", "Q3 Planning", "Design System"],
                briefKeyQuotes: [
                    "Sarah: 68% of our users are on mobile — we can't ignore that any longer.",
                    "James: We need to be realistic about what we can deliver this quarter."
                ],
                rawTranscript: "Sarah: Let's start with the Q3 priorities. I've been looking at the data and 68% of our users are now on mobile...",
                createdAt: Date().addingTimeInterval(-3600 * 2)
            ),

            Meeting(
                title: "Engineering Sprint Retrospective",
                date: Date().addingTimeInterval(-86400),
                duration: 1800,
                clientName: nil,
                status: .complete,
                template: .standup,
                briefSummary: """
                # Engineering Sprint Retrospective

                **Attendees:** **James** (Lead), **Priya** (Backend), **Tom** (Frontend)
                **Type:** Standup

                ---

                ## Summary
                Sprint 14 completed with 85% of story points delivered. The team identified deployment pipeline slowdowns as the main blocker. Agreed to invest time in CI/CD improvements next sprint.

                ## Key Decisions
                - **Dedicate 2 days to CI/CD improvements** — decided by **James**
                - **Move to trunk-based development** — agreed by team
                - **Add automated regression tests** — owned by **Priya**

                ## Action Items
                | Task | Owner | Due | Priority |
                |------|-------|-----|----------|
                | Set up automated deployment pipeline | **Tom** | Next sprint | High |
                | Write regression test suite for API | **Priya** | This week | High |
                | Document new branching strategy | **James** | Tomorrow | Medium |

                ## Discussion Notes

                ### What Went Well
                - Delivered the new dashboard feature on time
                - Code review turnaround improved to under 4 hours
                - Zero production incidents this sprint

                ### What Needs Improvement
                - Deployment pipeline takes 45 minutes — needs optimization
                - Test coverage dropped to 72% from 80%

                ## Open Questions
                - Should we switch to a different CI provider?
                - Can we get budget for a staging environment?
                """,
                briefDecisions: [
                    "Dedicate 2 days to CI/CD improvements",
                    "Move to trunk-based development",
                    "Add automated regression tests"
                ],
                briefActionItems: [
                    ActionItem(text: "Set up automated deployment pipeline", owner: "Tom", dueDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())),
                    ActionItem(text: "Write regression test suite for API", owner: "Priya", isMine: true),
                    ActionItem(text: "Document new branching strategy", owner: "James", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()), isMine: true)
                ],
                briefKeyTopics: ["Sprint Retro", "CI/CD", "Deployment", "Testing"],
                createdAt: Date().addingTimeInterval(-86400)
            ),

            Meeting(
                title: "Client Discovery Call — Northwind",
                date: Date().addingTimeInterval(-86400 * 2),
                duration: 3200,
                clientName: "Northwind",
                status: .complete,
                template: .discovery,
                briefSummary: """
                # Client Discovery Call — Northwind Industries

                **Attendees:** **Mark** (Sales), **You** (Solutions), **Rachel** (Northwind CTO)
                **Type:** Discovery Call

                ---

                ## Summary
                Northwind Industries is looking to modernize their data infrastructure. They currently run on legacy systems and need a migration plan. **Rachel** expressed urgency — their current vendor contract expires in 6 months. Budget is approved for up to $500K.

                ## Key Decisions
                - **Proceed with a 2-week assessment** — agreed by **Rachel**
                - **Start with data audit** before proposing architecture
                - **Schedule follow-up for next Tuesday** with their VP of Engineering

                ## Action Items
                | Task | Owner | Due | Priority |
                |------|-------|-----|----------|
                | Send assessment proposal and SOW | **Mark** | Tomorrow | High |
                | Prepare technical questionnaire | **You** | This week | High |
                | Share case studies from similar migrations | **You** | Friday | Medium |

                ## Discussion Notes

                ### Current Pain Points
                - Legacy system crashes 2-3 times per month
                - Data reports take 4+ hours to generate
                - No real-time analytics capability
                - **Rachel** mentioned they lost a major deal because they couldn't provide data fast enough

                ### Requirements
                - Real-time dashboards for executive team
                - Sub-second query performance
                - Integration with their existing Salesforce instance

                ## Open Questions
                - What's their data volume? Need exact numbers.
                - Who are the key stakeholders for sign-off?
                - Are there compliance requirements we need to address?
                """,
                briefDecisions: [
                    "Proceed with 2-week technical assessment",
                    "Start with data audit before architecture proposal",
                    "Follow-up meeting next Tuesday with VP Engineering"
                ],
                briefActionItems: [
                    ActionItem(text: "Send assessment proposal and SOW", owner: "Mark", dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date())),
                    ActionItem(text: "Prepare technical questionnaire for Northwind", owner: "You", isMine: true),
                    ActionItem(text: "Share case studies from similar migrations", owner: "You", dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()), isMine: true)
                ],
                briefKeyTopics: ["Discovery", "Data Migration", "Client Requirements", "Legacy Modernization"],
                briefKeyQuotes: [
                    "Rachel: We lost a major deal because we couldn't pull the data fast enough. That can't happen again."
                ],
                rawTranscript: "Mark: Thanks for joining, Rachel. We're excited to learn more about what Northwind needs...",
                createdAt: Date().addingTimeInterval(-86400 * 2)
            ),

            Meeting(
                title: "Weekly 1:1 — Career Development",
                date: Date().addingTimeInterval(-86400 * 3),
                duration: 1800,
                status: .complete,
                template: .oneOnOne,
                briefSummary: """
                # Weekly 1:1 — Career Development

                **Attendees:** **You**, **David** (Manager)
                **Type:** 1:1

                ---

                ## Summary
                Productive 1:1 covering project updates and career goals. **David** shared positive feedback from the leadership team. Discussed plans for taking on more client-facing responsibilities and pursuing a certification.

                ## Key Decisions
                - **Take lead on next client presentation** — you volunteered
                - **Start certification preparation** this month
                - **Mentor a new team member** joining next week

                ## Action Items
                | Task | Owner | Due | Priority |
                |------|-------|-----|----------|
                | Register for Data Engineering certification | **You** | This week | Medium |
                | Prepare outline for client presentation | **You** | Next Monday | High |
                | Share the project Gantt chart draft | **David** | Friday | Medium |
                """,
                briefDecisions: [
                    "Take lead on next client presentation",
                    "Start certification preparation this month",
                    "Mentor new team member"
                ],
                briefActionItems: [
                    ActionItem(text: "Register for Data Engineering certification", owner: "You", dueDate: Calendar.current.date(byAdding: .day, value: 5, to: Date()), isMine: true),
                    ActionItem(text: "Prepare outline for client presentation", owner: "You", isMine: true),
                    ActionItem(text: "Share project Gantt chart draft", owner: "David")
                ],
                briefKeyTopics: ["Career Growth", "Certification", "Team Leadership", "Client Presentations"],
                createdAt: Date().addingTimeInterval(-86400 * 3)
            ),

            Meeting(
                title: "Team Brainstorm — New Feature Ideas",
                date: Date().addingTimeInterval(-86400 * 5),
                duration: 2400,
                status: .complete,
                template: .brainstorm,
                briefSummary: """
                # Team Brainstorm — New Feature Ideas for Q4

                **Attendees:** **You**, **Priya**, **Tom**, **Lisa**
                **Type:** Brainstorm

                ---

                ## Summary
                The team brainstormed ideas for Q4 features. Top ideas included AI-powered search, a mobile notifications revamp, and a customer health dashboard. The team voted and agreed to prioritize AI search and the notification system.

                ## Key Decisions
                - **AI-powered search is the #1 priority** — unanimous vote
                - **Notification revamp as #2** — critical for user retention
                - **Customer health dashboard moved to Q1** — nice-to-have but not urgent

                ## Action Items
                | Task | Owner | Due | Priority |
                |------|-------|-----|----------|
                | Write PRD for AI search feature | **You** | Next week | High |
                | Research notification frameworks | **Tom** | This week | Medium |
                | Create mockups for search UI | **Lisa** | Next Friday | Medium |
                | Set up demo environment for prototyping | **Priya** | This week | Medium |

                ## Discussion Notes

                ### Ideas Generated
                - AI-powered semantic search across all content
                - Push notification overhaul with smart grouping
                - Customer health score dashboard
                - Automated weekly digest emails
                - Voice command integration

                ### Voting Results
                - AI Search: 4 votes (unanimous)
                - Notifications: 3 votes
                - Health Dashboard: 2 votes
                - Digest Emails: 1 vote

                ## Open Questions
                - Which AI model should we use for search?
                - Do we need a dedicated ML engineer?
                """,
                briefDecisions: [
                    "AI-powered search is #1 priority for Q4",
                    "Notification revamp as #2 priority",
                    "Customer health dashboard moved to Q1"
                ],
                briefActionItems: [
                    ActionItem(text: "Write PRD for AI search feature", owner: "You", isMine: true),
                    ActionItem(text: "Research notification frameworks", owner: "Tom"),
                    ActionItem(text: "Create mockups for search UI", owner: "Lisa"),
                    ActionItem(text: "Set up demo environment for prototyping", owner: "Priya")
                ],
                briefKeyTopics: ["Brainstorm", "AI Search", "Q4 Planning", "Feature Prioritization"],
                briefKeyQuotes: [
                    "Lisa: If we nail the search experience, everything else becomes easier to find.",
                    "Tom: Notifications are broken — users are muting us. We need to fix this."
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

            // Auto-enhance notes if user wrote notepad content
            if meeting.notepadContent != nil || meeting.userNotes != nil {
                Task {
                    await enhanceNotes(for: meeting)
                }
            }

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

    /// Regenerate meeting notes from existing transcript using the latest AI prompt.
    func regenerateNotes(_ meeting: Meeting) async {
        guard let transcript = meeting.rawTranscript, !transcript.isEmpty else {
            print("[MeetingService] Cannot regenerate: no transcript for \(meeting.title)")
            return
        }

        var updatedMeeting = meeting
        updatedMeeting.status = .processing
        updateMeetingInCoreData(updatedMeeting)
        loadMeetings()

        do {
            print("[MeetingService] Regenerating notes for: \(meeting.title)")
            let brief = try await GroqService.shared.generateMeetingBrief(
                transcript: transcript,
                userNotes: meeting.userNotes,
                template: meeting.template
            )

            updatedMeeting.status = .complete
            updatedMeeting.title = extractMarkdownTitle(from: brief.summary) ?? brief.title
            updatedMeeting.briefSummary = brief.summary
            updatedMeeting.briefDecisions = brief.decisions
            updatedMeeting.briefKeyTopics = brief.keyTopics
            updatedMeeting.clientName = brief.clientName ?? meeting.clientName
            updatedMeeting.briefKeyQuotes = brief.keyQuotes ?? []

            let actionItems: [ActionItem] = brief.actionItems.map { item in
                ActionItem(text: item.text, owner: item.owner, dueDate: parseDateString(item.due), isMine: item.isMine)
            }
            updatedMeeting.briefActionItems = actionItems

            updateMeetingInCoreData(updatedMeeting)
            loadMeetings()
            print("[MeetingService] Regenerated notes for: \(updatedMeeting.title)")
        } catch {
            updatedMeeting.status = .complete // Keep old status, don't mark as failed
            updateMeetingInCoreData(updatedMeeting)
            loadMeetings()
            print("[MeetingService] Regeneration failed: \(error)")
        }
    }

    /// Regenerate notes for ALL completed meetings that have transcripts.
    /// Enhance user notes with AI by merging with transcript (Granola-style).
    func enhanceNotes(for meeting: Meeting) async {
        guard let transcript = meeting.rawTranscript, !transcript.isEmpty else {
            print("[MeetingService] Cannot enhance: no transcript for \(meeting.title)")
            return
        }

        let notesToEnhance = meeting.notepadContent ?? meeting.userNotes ?? ""
        guard !notesToEnhance.isEmpty else {
            print("[MeetingService] Cannot enhance: no notes for \(meeting.title)")
            return
        }

        do {
            let blocks = try await NoteEnhancementService.shared.enhanceNotes(
                userNotes: notesToEnhance,
                transcript: transcript,
                template: meeting.template
            )

            var updatedMeeting = meeting
            updatedMeeting.enhancedNotes = blocks
            updateMeetingInCoreData(updatedMeeting)
            loadMeetings()
            print("[MeetingService] Enhanced notes for: \(meeting.title) (\(blocks.count) blocks)")
        } catch {
            print("[MeetingService] Note enhancement failed: \(error)")
        }
    }

    func regenerateAllNotes() async {
        let toRegenerate = meetings.filter { $0.status == .complete && $0.rawTranscript != nil && !($0.rawTranscript ?? "").isEmpty }
        print("[MeetingService] Regenerating notes for \(toRegenerate.count) meetings...")
        for meeting in toRegenerate {
            await regenerateNotes(meeting)
        }
        print("[MeetingService] Done regenerating all notes")
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
        obj.setValue(meeting.notepadContent, forKey: "notepadContent")
        if let enhancedData = try? JSONEncoder().encode(meeting.enhancedNotes) {
            obj.setValue(enhancedData, forKey: "enhancedNotesData")
        }
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

        var enhancedNotes: [EnhancedBlock]?
        if let data = obj.value(forKey: "enhancedNotesData") as? Data {
            enhancedNotes = try? JSONDecoder().decode([EnhancedBlock].self, from: data)
        }
        let notepadContent = obj.value(forKey: "notepadContent") as? String

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
            notepadContent: notepadContent,
            enhancedNotes: enhancedNotes,
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
