import SwiftUI
import AppKit

@main
struct BarTasksApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView() // No main window, just a menu bar item.
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Remove from Dock
        NSApp.setActivationPolicy(.accessory)

        // Create the status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "list.bullet", accessibilityDescription: "BarTasks Item List")
            button.action = #selector(togglePopover(_:))
        }

        // Create the popover with our SwiftUI view
        popover = NSPopover()
        popover.contentViewController = NSHostingController(rootView: ContentView())
        popover.behavior = .transient
    }

    @objc func togglePopover(_ sender: AnyObject?) {
        if let button = statusItem.button {
            if popover.isShown {
                popover.performClose(sender)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 5) {
                ListView(title: "Now", itemsKey: "items", deletedItemsKey: "deletedItems")
                ListView(title: "Later", itemsKey: "laterItems", deletedItemsKey: "laterDeletedItems")
            }
        }
    }
}

struct ListView: View {
    @State private var items: [TaskItem]
    @State private var deletedItems: [TaskItem]
    @State private var newItem: String = ""
    @State private var showDeletedItems: Bool = false
    var title: String
    var itemsKey: String
    var deletedItemsKey: String

    init(title: String, itemsKey: String, deletedItemsKey: String) {
        self.title = title
        self.itemsKey = itemsKey
        self.deletedItemsKey = deletedItemsKey
        _items = State(initialValue: UserDefaultsManager.loadItems(forKey: itemsKey))
        _deletedItems = State(initialValue: UserDefaultsManager.loadItems(forKey: deletedItemsKey))
    }

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.headline)

            ForEach(items) { item in
                HStack(alignment: .top) {
                    Button(action: {
                        completeItem(item)
                    }) {
                        Image(systemName: "square")
                    }
                    .buttonStyle(BorderlessButtonStyle())

                    Text(item.name)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(timeSinceAdded(item.addedAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(alignment: .trailing)
                }
            }

            HStack {
                TextField("Add new item", text: $newItem, onCommit: {
                    addItem()
                })
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                if !deletedItems.isEmpty {
                    Button(action: {
                        showDeletedItems.toggle()
                    }) {
                        Image(systemName: "tray.full")
                    }
                }
            }

            if showDeletedItems {
                ScrollView {
                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(deletedItems) { item in
                            HStack {
                                Text(item.name)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if let completedAt = item.completedAt {
                                    Text(timeSinceAdded(completedAt))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                        .frame(alignment: .trailing)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 125)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .onDisappear(perform: saveData)
    }

    private func addItem() {
        guard !newItem.isEmpty else { return }
        let task = TaskItem(id: UUID(), name: newItem, addedAt: Date(), completedAt: nil)
        items.append(task)
        newItem = ""
        saveData()
    }

    private func completeItem(_ item: TaskItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            var completedTask = items[index]
            completedTask.completedAt = Date()
            deletedItems.append(completedTask)
            items.remove(at: index)
            saveData()
        }
    }

    private func saveData() {
        UserDefaultsManager.saveItems(items, forKey: itemsKey)
        UserDefaultsManager.saveItems(deletedItems, forKey: deletedItemsKey)
    }

    private func timeSinceAdded(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)

        if days > 0 {
            return "\(days) day(s) ago"
        } else {
            return "\(hours) hour(s) ago"
        }
    }
}

struct TaskItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var addedAt: Date
    var completedAt: Date?
}

class UserDefaultsManager {
    static func saveItems(_ items: [TaskItem], forKey key: String) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func loadItems(forKey key: String) -> [TaskItem] {
        if let data = UserDefaults.standard.data(forKey: key),
           let items = try? JSONDecoder().decode([TaskItem].self, from: data) {
            return items
        }
        return []
    }
}
