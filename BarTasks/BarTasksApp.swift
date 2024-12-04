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
    @State private var items: [TaskItem] = []
    @State private var newItem: String = ""

    var body: some View {
        VStack(spacing: 10) {
            TextField("Add new item", text: $newItem, onCommit: addItem)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            List {
                ForEach(items) { item in
                    HStack {
                        Button(action: {
                            toggleTaskCompletion(item)
                        }) {
                            Image(systemName: item.isCompleted ? "checkmark.square" : "square")
                        }
                        .buttonStyle(BorderlessButtonStyle())

                        Text(item.name)
                    }
                }
            }
            .frame(maxWidth: 300, maxHeight: 400)
        }
        .padding()
    }

    private func addItem() {
        guard !newItem.isEmpty else { return }
        let task = TaskItem(id: UUID(), name: newItem, isCompleted: false)
        items.append(task)
        newItem = ""
    }

    private func toggleTaskCompletion(_ item: TaskItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            if items[index].isCompleted {
                items.remove(at: index)
            } else {
                items[index].isCompleted.toggle()
            }
        }
    }
}

struct TaskItem: Identifiable {
    let id: UUID
    var name: String
    var isCompleted: Bool
}
