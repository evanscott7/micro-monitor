// Lighthouse: shows prototype/screen.html full screen on the Wokyis dock display.
// - Borderless window pinned to the screen named "Wokyis"; re-pins when displays change.
// - No Dock icon. A small menu-bar item offers Reload, Open Capture and Quit.
// - ⌃⌥Space opens Capture from anywhere; saved thoughts append to ~/Inbox/inbox.md.
// - Live agents: Claude Code hooks append to ~/.lighthouse/events.ndjson (see hooks/lighthouse-hook.sh);
//   AgentStore folds those events into one state per session and pushes them to the page.
// - Next event: CalendarFeed reads macOS Calendar (EventKit) for the next timed event starting within the hour.

import AppKit
import Carbon.HIToolbox
import EventKit
import WebKit

let targetScreenName = "Wokyis"

final class KioskWindow: NSWindow {
    override var canBecomeKey: Bool { true }   // borderless windows refuse key status by default; Capture needs typing
    override var canBecomeMain: Bool { true }
}

// MARK: - live agent state

/// Reads ~/.lighthouse/events.ndjson (one JSON object per line) and keeps one state per agent session.
final class AgentStore {
    struct Agent {
        var id: String, src: String, cwd: String
        var state = "idle"          // idle | working | done | needs
        var why = ""
        var since: Double           // when the current state began (unix seconds)
        var last: Double            // last event of any kind
    }

    let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".lighthouse")
    var eventsURL: URL { dir.appendingPathComponent("events.ndjson") }
    var shapesURL: URL { dir.appendingPathComponent("shapes.json") }
    private(set) var agents: [String: Agent] = [:]
    private var offset: UInt64 = 0
    private var shapes: [String: String] = [:]   // project name → shape, kept for life
    private let shapeOrder = ["circle", "tri", "square", "hex", "diamond"]
    var onChange: (() -> Void)?

    init() {
        let fm = FileManager.default
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        if !fm.fileExists(atPath: eventsURL.path) { fm.createFile(atPath: eventsURL.path, contents: nil) }
        if let d = try? Data(contentsOf: shapesURL), let m = try? JSONDecoder().decode([String: String].self, from: d) { shapes = m }
        compactIfLarge()
    }

    /// Keep the log small: past ~1 MB, keep only the newest 3,000 lines.
    private func compactIfLarge() {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: eventsURL.path),
              let size = attrs[.size] as? UInt64, size > 1_000_000,
              let text = try? String(contentsOf: eventsURL, encoding: .utf8) else { return }
        let lines = text.split(separator: "\n").suffix(3000)
        try? (lines.joined(separator: "\n") + "\n").write(to: eventsURL, atomically: true, encoding: .utf8)
    }

    /// Read whatever was appended since last time. Cheap enough to call every second.
    func poll() {
        guard let h = try? FileHandle(forReadingFrom: eventsURL) else { return }
        defer { try? h.close() }
        let end = (try? h.seekToEnd()) ?? 0
        if end < offset { offset = 0; agents = [:] }          // file was rotated or truncated
        guard end > offset else { if prune() { onChange?() }; return }
        try? h.seek(toOffset: offset)
        let data = h.readDataToEndOfFile()
        guard let lastNL = data.lastIndex(of: 0x0A) else { return }  // wait for a full line
        offset += UInt64(lastNL - data.startIndex + 1)
        var changed = false
        for line in data[data.startIndex...lastNL].split(separator: 0x0A) {
            guard let obj = try? JSONSerialization.jsonObject(with: Data(line)) as? [String: Any] else { continue }
            changed = apply(obj) || changed
        }
        changed = prune() || changed
        if changed { onChange?() }
    }

    private func firstLine(_ s: String?) -> String {
        guard let s else { return "" }
        let line = s.split(whereSeparator: \.isNewline).first.map(String.init) ?? s
        return line.trimmingCharacters(in: CharacterSet(charactersIn: " #*`>-"))
    }

    @discardableResult
    private func apply(_ e: [String: Any]) -> Bool {
        guard let sid = e["sid"] as? String, let ev = e["ev"] as? String else { return false }
        let t = e["t"] as? Double ?? Date().timeIntervalSince1970
        let src = e["src"] as? String ?? "claude"
        if ev == "SessionEnd" || ev == "end" { return agents.removeValue(forKey: sid) != nil }
        var a = agents[sid] ?? Agent(id: sid, src: src, cwd: e["cwd"] as? String ?? "", since: t, last: t)
        if a.cwd.isEmpty, let cwd = e["cwd"] as? String { a.cwd = cwd }  // keep the session's first folder; the shell can wander into subfolders
        a.last = t
        func set(_ s: String, _ why: String) { if a.state != s { a.since = t }; a.state = s; if !why.isEmpty { a.why = why } }
        switch ev {
        case "SessionStart": if agents[sid] == nil { set("idle", "Session started") }
        case "UserPromptSubmit": set("working", firstLine(e["prompt"] as? String))
        case "PostToolUse": if a.state != "working" { set("working", "") }
        case "Notification":
            let n = e["n"] as? String ?? ""
            if n == "idle_prompt" { if a.state == "working" { set("done", a.why) } }
            else if ["permission_prompt", "elicitation_dialog", "agent_needs_input"].contains(n) || n.isEmpty { set("needs", firstLine(e["msg"] as? String)) }
        case "Stop": set("done", firstLine(e["last"] as? String))
        // Generic shape for other agents such as Grok Bot: {"src":"grok","ev":"working","sid":"…","why":"…"}
        case "working", "done", "needs", "idle": set(ev, firstLine(e["why"] as? String))
        default: break
        }
        agents[sid] = a
        return true
    }

    /// Drop sessions that have gone quiet: idle after 3 hours, anything after 12.
    @discardableResult
    private func prune() -> Bool {
        let now = Date().timeIntervalSince1970, before = agents.count
        agents = agents.filter { _, a in
            let age = now - a.last
            return age < 12 * 3600 && !(a.state == "idle" && age > 3 * 3600)
        }
        return agents.count != before
    }

    func acknowledge(_ sid: String) {
        guard var a = agents[sid] else { return }
        if a.state == "done" { a.state = "idle"; a.since = Date().timeIntervalSince1970 }
        agents[sid] = a
        onChange?()
    }

    private func project(_ cwd: String) -> String {
        let name = (cwd as NSString).lastPathComponent
        return name.isEmpty ? "AGENT" : name
    }

    private func shape(for project: String) -> String {
        if let s = shapes[project] { return s }
        let used = Dictionary(grouping: shapes.values, by: { $0 }).mapValues(\.count)
        let s = shapeOrder.min { (used[$0] ?? 0) < (used[$1] ?? 0) } ?? "circle"
        shapes[project] = s
        if let d = try? JSONEncoder().encode(shapes) { try? d.write(to: shapesURL) }
        return s
    }

    /// The list the page renders, most urgent first.
    func payload() -> [[String: Any]] {
        let rank = ["needs": 0, "done": 1, "working": 2, "idle": 3]
        let sorted = agents.values.sorted { (rank[$0.state] ?? 9, -$0.since) < (rank[$1.state] ?? 9, -$1.since) }
        var seen: [String: Int] = [:]
        return sorted.map { a in
            let proj = project(a.cwd)
            seen[proj, default: 0] += 1
            let n = seen[proj]!
            let label = String(proj.uppercased().prefix(14)) + (n > 1 ? " \(n)" : "")
            let home = FileManager.default.homeDirectoryForCurrentUser.path
            return ["id": a.id, "name": label, "shape": shape(for: proj),
                    "src": a.src == "grok" ? "Grok Bot" : "Claude Code",
                    "job": a.cwd.replacingOccurrences(of: home, with: "~"),
                    "why": a.why, "state": a.state, "since": a.since * 1000]
        }
    }
}

// MARK: - next calendar event

/// The next timed event (not all-day, not declined) starting within the next hour, from every calendar in macOS Calendar.
final class CalendarFeed {
    let store = EKEventStore()
    private(set) var granted = false
    var onChange: (() -> Void)?
    private var lastSent = ""

    func start() {
        store.requestFullAccessToEvents { [weak self] ok, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.granted = ok
                NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: self.store, queue: .main) { [weak self] _ in self?.refresh(force: true) }
                self.refresh(force: true)
            }
        }
    }

    /// Payload for the page: {title, where, start (ms)} or nil. Ongoing events stay for 5 minutes after they start.
    func next() -> [String: Any]? {
        guard granted else { return nil }
        let now = Date()
        let pred = store.predicateForEvents(withStart: now.addingTimeInterval(-5 * 60), end: now.addingTimeInterval(60 * 60), calendars: nil)
        let ev = store.events(matching: pred)
            .filter { !$0.isAllDay && $0.startDate >= now.addingTimeInterval(-5 * 60) && $0.startDate <= now.addingTimeInterval(60 * 60) }
            .filter { e in e.attendees?.first(where: { $0.isCurrentUser })?.participantStatus != .declined }
            .min { $0.startDate < $1.startDate }
        guard let ev else { return nil }
        let place = (ev.location ?? "").split(separator: "\n").first.map(String.init) ?? ""
        return ["title": ev.title ?? "Event", "where": place, "start": ev.startDate.timeIntervalSince1970 * 1000]
    }

    /// Called every minute and whenever the calendar changes; only notifies when the answer changed.
    func refresh(force: Bool = false) {
        // Accounts added in Internet Accounts don't reach a running store on their own; ask it to look again.
        if granted { store.refreshSourcesIfNecessary() }
        let p = next()
        let key = p.map { "\($0["title"] ?? "")|\($0["start"] ?? "")|\($0["where"] ?? "")" } ?? ""
        if force || key != lastSent { lastSent = key; onChange?() }
    }
}

// MARK: - Grok Bot

/// Grok Bot has no hooks, but its local exec daemon publishes how many tasks are running on this Mac
/// (~/.grokbot/local-exec-daemon.json → inflightCount). Turn changes in that count into Lighthouse events.
/// It only sees work Grok runs locally; thinking that happens in the cloud doesn't show up.
final class GrokWatch {
    let statusURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".grokbot/local-exec-daemon.json")
    let eventsURL: URL
    private var working = false

    init(eventsURL: URL) { self.eventsURL = eventsURL }

    func poll() {
        guard let d = try? Data(contentsOf: statusURL),
              let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any],
              let inflight = obj["inflightCount"] as? Int else { return }
        if inflight > 0 && !working { working = true; emit("working", "Running a task on this Mac") }
        else if inflight == 0 && working { working = false; emit("done", "Finished a task on this Mac") }
    }

    private func emit(_ ev: String, _ why: String) {
        let line = "{\"t\":\(Date().timeIntervalSince1970),\"src\":\"grok\",\"ev\":\"\(ev)\",\"sid\":\"grokbot\",\"cwd\":\"/Applications/Grok Bot\",\"why\":\"\(why)\"}\n"
        if let h = try? FileHandle(forWritingTo: eventsURL) { h.seekToEndOfFile(); h.write(Data(line.utf8)); try? h.close() }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler, WKNavigationDelegate {
    let store = AgentStore()
    lazy var grok = GrokWatch(eventsURL: store.eventsURL)
    let calendar = CalendarFeed()
    var calendarTimer: Timer?
    var pollTimer: Timer?
    var window: KioskWindow!
    var webView: WKWebView!
    var statusItem: NSStatusItem!
    var hotKeyRef: EventHotKeyRef?
    let pageURL: URL

    init(pageURL: URL) { self.pageURL = pageURL }

    func applicationDidFinishLaunching(_ note: Notification) {
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "capture")
        config.userContentController.add(self, name: "agent")
        config.userContentController.add(self, name: "calendar")
        webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")

        window = KioskWindow(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        window.contentView = webView
        window.backgroundColor = NSColor(red: 0x14 / 255, green: 0x10 / 255, blue: 0x17 / 255, alpha: 1)
        window.level = .statusBar                                    // above that display's menu bar
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenNone]
        window.isReleasedWhenClosed = false
        pin()

        webView.loadFileURL(pageURL, allowingReadAccessTo: pageURL.deletingLastPathComponent())

        NotificationCenter.default.addObserver(self, selector: #selector(pin),
            name: NSApplication.didChangeScreenParametersNotification, object: nil)
        setUpStatusItem()
        registerHotKey()

        store.onChange = { [weak self] in self?.pushAgents() }
        store.poll()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.grok.poll(); self?.store.poll() }
        pollTimer?.tolerance = 0.3

        calendar.onChange = { [weak self] in self?.pushEvent() }
        calendar.start()
        calendarTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.calendar.refresh() }
        calendarTimer?.tolerance = 5
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { pushAgents(); pushEvent() }

    /// Send the next event (or null) to the page.
    func pushEvent() {
        let next = calendar.next()
        var json = "null"
        if let p = next, let d = try? JSONSerialization.data(withJSONObject: p), let s = String(data: d, encoding: .utf8) { json = s }
        // What the screen shows, plus which calendars macOS gives us, for debugging.
        let debug: [String: Any] = ["granted": calendar.granted, "event": next ?? NSNull(),
                                    "calendars": calendar.store.calendars(for: .event).map { "\($0.title) (\($0.source?.title ?? ""))" }]
        if let d = try? JSONSerialization.data(withJSONObject: debug, options: [.prettyPrinted]) { try? d.write(to: store.dir.appendingPathComponent("event.json")) }
        webView.evaluateJavaScript("window.lighthouseSetEvent && window.lighthouseSetEvent(\(json), \(calendar.granted))")
    }

    /// Send the current agent list to the page (it switches out of demo data on the first push).
    func pushAgents() {
        guard let data = try? JSONSerialization.data(withJSONObject: store.payload()),
              let json = String(data: data, encoding: .utf8) else { return }
        try? data.write(to: store.dir.appendingPathComponent("state.json"))  // what the screen shows, for debugging
        webView.evaluateJavaScript("window.lighthouseSetAgents && window.lighthouseSetAgents(\(json))")
    }

    /// Put the window on the Wokyis screen, or hide it while that screen is missing.
    @objc func pin() {
        guard let screen = NSScreen.screens.first(where: { $0.localizedName.contains(targetScreenName) }) else {
            window.orderOut(nil); return
        }
        window.setFrame(screen.frame, display: true)
        window.orderFrontRegardless()
    }

    func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "light.beacon.max", accessibilityDescription: "Lighthouse")
        let menu = NSMenu()
        menu.addItem(withTitle: "Open Capture  ⌃⌥Space", action: #selector(openCapture), keyEquivalent: "")
        menu.addItem(withTitle: "Reload Screen", action: #selector(reload), keyEquivalent: "r")
        menu.addItem(withTitle: "Show Inbox in Finder", action: #selector(revealInbox), keyEquivalent: "")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Lighthouse", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    @objc func reload() { webView.reloadFromOrigin() }

    @objc func openCapture() {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(webView)
        webView.evaluateJavaScript("window.lighthouseOpenCapture && window.lighthouseOpenCapture()")
    }

    // MARK: capture → ~/Inbox/inbox.md

    var inboxURL: URL { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Inbox/inbox.md") }

    @objc func revealInbox() {
        ensureInbox()
        NSWorkspace.shared.activateFileViewerSelecting([inboxURL])
    }

    func ensureInbox() {
        let fm = FileManager.default
        try? fm.createDirectory(at: inboxURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        if !fm.fileExists(atPath: inboxURL.path) { fm.createFile(atPath: inboxURL.path, contents: Data("# Inbox\n\n".utf8)) }
    }

    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "calendar" {
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
            return
        }
        if message.name == "agent", let body = message.body as? [String: Any], let sid = body["id"] as? String {
            // "open": bring Claude forward so you can answer it; "ack": you've seen a finished agent.
            if body["action"] as? String == "open",
               let claude = NSRunningApplication.runningApplications(withBundleIdentifier: "com.anthropic.claudefordesktop").first {
                claude.activate()
            }
            store.acknowledge(sid)
            return
        }
        guard message.name == "capture", let text = message.body as? String else { return }
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
        guard !clean.isEmpty else { return }
        ensureInbox()
        let stamp = ISO8601DateFormatter.string(from: Date(), timeZone: .current, formatOptions: [.withFullDate, .withTime, .withColonSeparatorInTime, .withDashSeparatorInDate, .withSpaceBetweenDateAndTime])
        let line = "- [ ] \(clean)  <!-- \(stamp) -->\n"
        if let h = try? FileHandle(forWritingTo: inboxURL) {
            h.seekToEndOfFile(); h.write(Data(line.utf8)); try? h.close()
        }
        // Hand focus back to whatever you were doing.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { NSApp.hide(nil); self.pin() }
    }

    // MARK: global hotkey ⌃⌥Space (Carbon; needs no Accessibility permission)

    func registerHotKey() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let me = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, ctx in
            guard let ctx else { return noErr }
            let d = Unmanaged<AppDelegate>.fromOpaque(ctx).takeUnretainedValue()
            DispatchQueue.main.async { d.openCapture() }
            return noErr
        }, 1, &spec, me, nil)
        let id = EventHotKeyID(signature: OSType(0x4C48_5453), id: 1) // "LHTS"
        RegisterEventHotKey(UInt32(kVK_Space), UInt32(controlKey | optionKey), id, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}

// Page path: first argument, else screen.html next to the app bundle's parent project.
let page: URL = {
    if CommandLine.arguments.count > 1 { return URL(fileURLWithPath: CommandLine.arguments[1]) }
    if let p = Bundle.main.object(forInfoDictionaryKey: "LighthousePage") as? String { return URL(fileURLWithPath: p) }
    return URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent("screen.html")
}()

let app = NSApplication.shared
let delegate = AppDelegate(pageURL: page)
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
