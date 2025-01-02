import SwiftUI
import AppKit
import UniformTypeIdentifiers

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
            if let appIcon = NSImage(named: NSImage.applicationIconName) {
                appIcon.size = NSSize(width: 18, height: 18)  // Resize to fit in status bar
                button.image = appIcon
            }
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
                ListView(title: "Now", itemsKey: "items", deletedItemsKey: "deletedItems", dropTargetID: "later")
                ListView(title: "Later", itemsKey: "laterItems", deletedItemsKey: "laterDeletedItems", dropTargetID: "now")
            }
        }
    }
}

struct ListView: View {
    @State private var items: [TaskItem]
    @State private var deletedItems: [TaskItem]
    @State private var newItem: String = ""
    @State private var showDeletedItems: Bool = false
    @State private var showingImagePicker = false
    @State private var selectedItem: TaskItem?
    @State private var showingPreview = false
    var title: String
    var itemsKey: String
    var deletedItemsKey: String
    var dropTargetID: String

    init(title: String, itemsKey: String, deletedItemsKey: String, dropTargetID: String) {
        self.title = title
        self.itemsKey = itemsKey
        self.deletedItemsKey = deletedItemsKey
        self.dropTargetID = dropTargetID
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

                    URLTextView(text: item.name)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let imageData = item.imageData,
                       let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .onTapGesture {
                                selectedItem = item
                                showingPreview = true
                            }
                    }

                    Text(timeSinceAdded(item.addedAt))
                        .font(.caption)
                        .foregroundColor(.gray)
                        .frame(alignment: .trailing)
                }
                .draggable(item)
            }

            .dropDestination(for: TaskItem.self) { droppedItems, _ in
                for item in droppedItems {
                    if let index = items.firstIndex(where: { $0.id == item.id }) {
                        items.remove(at: index)
                    }
                }
                items.append(contentsOf: droppedItems)
                saveData()
                return true
            }

            HStack {
                TextField("Add new item", text: $newItem)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        addItem()
                    }
                
                Button(action: {
                    showingImagePicker = true
                }) {
                    Image(systemName: "photo")
                }
                .buttonStyle(BorderlessButtonStyle())

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
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(completion: { imageData in
                if let imageData = imageData {
                    addItem(withImage: imageData)
                }
            })
        }
        .sheet(isPresented: $showingPreview) {
            if let selectedItem = selectedItem,
               let imageData = selectedItem.imageData {
                ImagePreviewView(imageData: imageData)
            }
        }
    }

    private func addItem(withImage imageData: Data? = nil) {
        guard !newItem.isEmpty else { return }
        let task = TaskItem(
            id: UUID(),
            name: newItem,
            addedAt: Date(),
            completedAt: nil,
            imageData: imageData
        )
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

struct URLTextView: View {
    let text: String
    
    var body: some View {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        
        if let matches = matches, !matches.isEmpty {
            let nsString = text as NSString
            HStack(spacing: 0) {
                ForEach(0..<matches.count, id: \.self) { index in
                    let match = matches[index]
                    
                    // Add text before the link if it's the first match
                    if index == 0 && match.range.location > 0 {
                        Text(nsString.substring(with: NSRange(location: 0, length: match.range.location)))
                    }
                    
                    // Add the link
                    if let url = match.url {
                        Text(simplifyURL(url))
                            .underline()
                            .onTapGesture {
                                NSWorkspace.shared.open(url)
                            }
                    }
                    
                    // Add text between links or after the last link
                    let endOfCurrentLink = match.range.location + match.range.length
                    let nextStart = index + 1 < matches.count ? matches[index + 1].range.location : nsString.length
                    if endOfCurrentLink < nextStart {
                        Text(nsString.substring(with: NSRange(location: endOfCurrentLink, length: nextStart - endOfCurrentLink)))
                    }
                }
            }
        } else {
            Text(text)
        }
    }
    
    private func simplifyURL(_ url: URL) -> String {
        guard let host = url.host?.lowercased() else { return url.absoluteString }
        
        // Remove 'www.' if present
        let domain = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        
        // If there's a path and it's not just "/", add "…"
        let path = url.path
        if path.count > 1 {
            return "\(domain)…"
        }
        
        return domain
    }
}

struct TaskItem: Identifiable, Codable, Transferable {
    let id: UUID
    var name: String
    var addedAt: Date
    var completedAt: Date?
    var imageData: Data?
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .taskItem)
    }
}

struct ImagePreviewView: View {
    let imageData: Data
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            if let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 400, maxHeight: 400)
            }
            
            Button("Close") {
                dismiss()
            }
            .padding()
        }
        .padding()
    }
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

extension UTType {
    static var taskItem: UTType {
        UTType(exportedAs: "com.yourdomain.bartasks.taskitem")
    }
}

struct ImagePicker {
    let completion: (Data?) -> Void
    
    func openPicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if let imageData = try? Data(contentsOf: url) {
                    completion(imageData)
                }
            } else {
                completion(nil)
            }
        }
    }
}

extension ImagePicker: View {
    var body: some View {
        EmptyView()
            .onAppear {
                openPicker()
            }
    }
}
