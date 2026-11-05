import SwiftUI
import Observation

enum ChooseTarget: Equatable {
    case current
    case next(Int)      // 0 is the left task 1 is the right one
}

struct CompletedTask: Identifiable {
    let id = UUID()
    let item: Item          // general work
    let points: Int
    let date: Date          // when it was completed
}

// The id of an Item changes every session, so we store the data itself
private struct CompletedRecord: Codable {
    var photo: String
    var name: String
    var author: String
    var year: String
    var details: String
    var rating: String
    var points: Int
    var date: Date
    // New fields are optional so history saved by the old version still loads
    var imageURL: String?
    var kind: String?
    var countryCode: String?
    var externalID: String?
}

@Observable
class TaskStore {
    private static let historyKey = "completedTasksHistory"
    private static let legacyPointsKey = "totalPoints"
    private static let dataVersionKey = "dataVersion"

    // Raise this number to delete , once , previous testing data
    private static let currentDataVersion = 2

    // history it starts empty and completed tasks get appended
    var completedTasks: [CompletedTask] = []

    init() {
        Self.clearLeftoverDataIfNeeded()
        loadSavedData()
    }

    // Clear leftover testing data
    private static func clearLeftoverDataIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: dataVersionKey) < currentDataVersion else { return }

        for key in [historyKey, legacyPointsKey, "savedUsername", "savedProfileImageData"] {
            defaults.removeObject(forKey: key)
        }
        defaults.set(currentDataVersion, forKey: dataVersionKey)
    }

    // MARK: - Saving

    // Loads data from history , points are calculated from history
    private func loadSavedData() {
        let defaults = UserDefaults.standard

        guard let data = defaults.data(forKey: Self.historyKey),
              let records = try? JSONDecoder().decode([CompletedRecord].self, from: data) else { return }

        completedTasks = records.map { r in
            let item = Item(photo: r.photo, name: r.name, author: r.author, year: r.year,
                            details: r.details, rating: r.rating,
                            imageURL: r.imageURL ?? "", kind: r.kind ?? "",
                            countryCode: r.countryCode ?? "", externalID: r.externalID ?? "")
            return CompletedTask(item: item, points: r.points, date: r.date)
        }
    }

    private func saveHistory() {
        let records = completedTasks.map { c in
            CompletedRecord(photo: c.item.photo, name: c.item.name,
                            author: c.item.author, year: c.item.year,
                            details: c.item.details, rating: c.item.rating,
                            points: c.points, date: c.date,
                            imageURL: c.item.imageURL, kind: c.item.kind,
                            countryCode: c.item.countryCode, externalID: c.item.externalID)
        }
        if let data = try? JSONEncoder().encode(records) {
            UserDefaults.standard.set(data, forKey: Self.historyKey)
        }
    }

    var points: Int {
        completedTasks.reduce(0) { $0 + $1.points }
    }

    // True if this work was already completed (used to hide it from search)
    func isCompleted(_ item: Item) -> Bool {
        !item.externalID.isEmpty && completedTasks.contains { $0.item.externalID == item.externalID }
    }

    // nil -> no task selected
    var currentTask: Item?

    var nextTasks: [Item] = []
    static let maxNextTasks = 2

    var chooseTarget: ChooseTarget = .current

    // Popup home views
    var showCountries = false       // opens SearchView
    var showCongrats = false        // CongratulationsView

    // Data needed for congratulations view
    var finishedTask: Item?         // the task just completed
    var earnedPoints = 0            // points earned with that task

    // How many "Next task" slots are visible
    var visibleNextSlots: Int {
        min(nextTasks.count + 1, TaskStore.maxNextTasks)
    }

    func nextTask(at slot: Int) -> Item? {
        slot < nextTasks.count ? nextTasks[slot] : nil
    }

    var targetHasTask: Bool {
        switch chooseTarget {
        case .current:
            return currentTask != nil
        case .next(let slot):
            return slot < nextTasks.count
        }
    }

    // The task that "Change task" will substitute
    var targetTask: Item? {
        switch chooseTarget {
        case .current:
            return currentTask
        case .next(let slot):
            return nextTask(at: slot)
        }
    }

    // MARK: - Open the search screen

    func openCountries() {
        chooseTarget = .current
        showCountries = true
    }

    func openCountries(forNextSlot slot: Int) {
        chooseTarget = .next(slot)
        showCountries = true
    }

    // MARK: - Choose

    // saves task and goes back to home
    func choose(_ item: Item) {
        switch chooseTarget {
        case .current:
            currentTask = item
        case .next(let slot):
            if slot < nextTasks.count {
                nextTasks[slot] = item
            } else if nextTasks.count < TaskStore.maxNextTasks {
                nextTasks.append(item)
            }
        }
        showCountries = false
    }

    // MARK: - Points

    // Reads the rating and converts it to a 0-10 scale:
    // "8.5/10 (TMDB)" -> 8.5     "4.1/5 (Open Library)" -> 8.2
    func ratingNumber(of item: Item) -> Double? {
        let text = item.rating.replacingOccurrences(of: ",", with: ".")
        let parts = text.split(separator: "/", maxSplits: 1)
        guard let first = parts.first, let value = Double(first.trimmingCharacters(in: .whitespaces)) else { return nil }
        guard parts.count == 2 else { return value }
        let digits = parts[1].prefix { $0.isNumber || $0 == "." }
        guard let maxValue = Double(String(digits)), maxValue > 0 else { return value }
        return min(value / maxValue * 10, 10)
    }

    // 8.2 -> 820 points. Works without a rating (e.g. songs) get a standard 700.
    func points(for item: Item) -> Int {
        guard let value = ratingNumber(of: item) else { return 700 }
        return Int((value * 100).rounded())
    }

    // MARK: - Complete

    func finishCurrentTask() {
        guard let task = currentTask else { return }

        let earned = points(for: task)
        finishedTask = task
        earnedPoints = earned

        // Add to history
        completedTasks.insert(CompletedTask(item: task, points: earned, date: .now), at: 0)
        saveHistory()

        nextTasks.removeAll { $0.id == task.id }

        currentTask = nil
        showCongrats = true
    }

    func promoteNextTask() {
        guard currentTask == nil, !nextTasks.isEmpty else { return }
        currentTask = nextTasks.removeFirst()
    }
}
