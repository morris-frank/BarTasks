# BarTasks App

## Overview
BarTasks is a lightweight macOS app that resides solely in the system menu bar and allows users to manage simple task lists. The app provides two distinct task lists labeled "Now" and "Later," making it easy to organize and prioritize tasks. The app data persists across reboots using `UserDefaults` for task items.

The app features:
- A menu bar icon for quick access.
- Separate lists for tasks, labeled as "Now" and "Later".
- The ability to add, mark complete, and view deleted items.
- Persistent storage using `UserDefaults` to ensure your tasks remain even after restarting the app.

## Features
- **Menu Bar App**: The app only runs in the macOS menu bar, keeping your Dock clean.
- **Multiple Task Lists**: Manage tasks for different contexts ("Now" and "Later").
- **Persistent Data**: Saves tasks persistently using `UserDefaults` to maintain data across app restarts.
- **Easy Item Management**: Add tasks, mark them complete, and view deleted items in a scrollable panel.

## Installation
To build and run this app:
1. Clone the repository to your local machine.
2. Open the project in Xcode.
3. Build and run the app.
4. The app will appear in the macOS menu bar with a list icon.

### Requirements
- macOS 11.0+ (Big Sur or later).
- Xcode 12 or later.

## Usage
1. Click the list icon in the menu bar to open the task manager popover.
2. Add tasks by typing into the text field and pressing Enter.
3. Completed tasks can be checked off, and they will appear in the deleted list.
4. Deleted tasks can be viewed by clicking the tray icon if deleted items exist.

### Persistent Storage
Tasks are saved to `UserDefaults` under unique keys for each task list:
- **Now List**: Items are saved under `items` and deleted items are saved under `deletedItems`.
- **Later List**: Items are saved under `laterItems` and deleted items are saved under `laterDeletedItems`.

This means the tasks will be available when you open the app again after a restart.

## Code Explanation
### Main App Structure
- **BarTasksApp**: The main SwiftUI entry point for the app. Uses `@NSApplicationDelegateAdaptor` to create a macOS menu bar-only experience.
- **AppDelegate**: Manages the menu bar item (`statusItem`) and the popover that contains the main view (`ContentView`). The app uses `.accessory` activation policy to stay out of the Dock.

### Content Views
- **ContentView**: Contains two `ListView` components, one for the "Now" list and one for the "Later" list. Wrapped in a `ScrollView` to allow scrolling if there is too much content.
- **ListView**: Represents each list (e.g., "Now" or "Later") and manages tasks for that specific list, including adding new items, completing items, and toggling the visibility of deleted items. Uses `@State` properties to track tasks and bind data.

### UserDefaults Storage
- **UserDefaultsManager**: Handles saving and loading task items from `UserDefaults`. Task items are encoded to JSON for easy storage and retrieval.
- Each `ListView` instance has its own unique key for `items` and `deletedItems` to store tasks independently for "Now" and "Later".

## Development Notes
- **UserDefaultsManager**: Uses `JSONEncoder` and `JSONDecoder` to serialize and deserialize the `TaskItem` objects.
- **TaskItem**: A simple `Identifiable` and `Codable` struct representing a task with an `id`, `name`, `addedAt` timestamp, and optional `completedAt` timestamp.
- **Button Actions**: Tasks can be added, marked as complete, and viewed in separate lists using buttons and toggles.

## License
This project is licensed under the MIT License.

## Contributions
Contributions are welcome! Please open an issue or create a pull request.

## Contact
For questions or suggestions, feel free to contact me through GitHub.
