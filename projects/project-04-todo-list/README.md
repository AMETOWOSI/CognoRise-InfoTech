# Project 4 — Task List

Task List is a Flutter task manager built for the CognoRise InfoTech App Development
Internship. It helps users turn a busy list into clear next steps: create a
task, set a priority or due date, mark it complete, and find it again later.

This README belongs to **this application only**. In the internship portfolio,
keep it next to this project's code at
`projects/project-04-todo-list/README.md`. Keep the repository's top-level
`README.md` as the portfolio overview and link to this project from there.

## Project status

| Check | Status |
| --- | --- |
| Create, edit, delete, and complete tasks | Implemented |
| Local task storage | Implemented with `shared_preferences` and JSON |
| Pending/completed filters and sorting | Implemented |
| Empty, loading, and error states | Implemented |
| Completion and dismissal animations | Implemented |
| Automated tests | `flutter test` passes |
| Static analysis | `flutter analyze` passes |
| Real-device close-and-reopen check | Recommended before submission |

The automated persistence tests use a mocked preferences store. They verify
that saved tasks can be read by a newly created repository and that the app
widget can be recreated while the test storage remains available. They do not
close and relaunch a real Android or iOS process. Follow the manual check below
to verify persistence on a device.

## What you can do

- Create a task with a title, priority, optional due date, and optional urgency
  level.
- Edit a task without losing its completion state.
- Mark a task complete or return it to the pending list.
- Delete a task with a swipe or the task options menu, then undo the deletion
  from the confirmation message.
- Show all tasks, pending tasks, or completed tasks.
- Sort tasks by priority or due date.
- Use the app in English, including the date picker.
- Keep tasks on the current device between app launches.

Task data is local to the device. This project does not provide an account,
cloud backup, or synchronization between devices.

## Screenshots and demo videos

There are no demo recordings committed yet. Add your own recordings after
capturing the app; do not leave example links pointing to files that are not in
the repository.

Create this folder inside the project:

```text
docs/
└── media/
    ├── task-list.png
    ├── create-task.png
    ├── filters-and-sorting.png
    ├── task-manager-demo.gif
    └── task-manager-demo.mp4
```

After adding a screenshot, show it in this README with a relative path:

```markdown
![Task List screen](docs/media/task-list.png)
```

For a compact preview, convert a short screen recording to an optimized GIF
and embed it:

```markdown
![Short Task List app demo](docs/media/task-manager-demo.gif)
```

GIFs are useful for a preview, but a long or high-resolution recording can make
the repository slow to clone. Keep the preview short and optimized. Link to the
full recording separately:

```markdown
[Watch the full app demo (MP4)](docs/media/task-manager-demo.mp4)
```

GitHub README pages do not reliably play a repository MP4 inline across
devices. For a dependable full-length video, upload it as a GitHub Release
asset or attach it to a GitHub issue, discussion, or pull request, then link
the resulting URL:

```markdown
[Watch the full app demo](PASTE-THE-GITHUB-VIDEO-URL-HERE)
```

Replace the example URL with the real URL GitHub gives you. Keep the GIF
preview and MP4 in this project's `docs/media/` folder only if you want the
video files versioned with the source code. Never add a broken placeholder
image or a link that only works on your computer.

### Suggested recordings

Record separate short clips so a reviewer can quickly find the behavior they
want to see:

1. `create-and-edit.mp4` — create a task and edit its title or priority.
2. `complete-and-filter.mp4` — mark a task complete and switch between filters.
3. `delete-and-undo.mp4` — delete a task and restore it from the confirmation.
4. `restart-persistence.mp4` — create a task, fully close the app, reopen it,
   and show the task is still present.

Use a screen recorder on an emulator or physical device. Avoid recording
personal notifications, private task names, passwords, or account details.
For the portfolio README, a single short GIF and links to the full clips are
usually clearer than embedding several large recordings.

## Technology

- Flutter and Dart
- Material 3 widgets
- `shared_preferences` for local key-value storage
- JSON serialization for task records
- `flutter_test` and `package:test`

## Run the app

Install Flutter and an Android emulator, iOS simulator (on macOS), or connect a
physical device. From this project's directory, run:

```sh
flutter pub get
flutter devices
flutter run
```

To run the automated tests and static analysis:

```sh
flutter test
flutter analyze
```

To run an individual test file:

```sh
flutter test test/shared_preferences_task_repository_test.dart
```

## Verify persistence on a real device

1. Start the app on an emulator or phone.
2. Add a task with a recognizable title.
3. Close the app completely. Do not only navigate to another screen.
4. Launch the app again.
5. Confirm that the task, its completion state, priority, due date, and urgency
   are still correct.
6. Repeat after editing and deleting a task.

This checks the platform storage implementation in addition to the mocked
automated test.

## How the code is organized

```text
lib/
├── main.dart
├── app_theme.dart
├── exceptions/
│   └── task_exception.dart
├── models/
│   ├── basic_task.dart
│   ├── priority.dart
│   ├── task.dart
│   ├── task_factory.dart
│   └── urgent_task.dart
├── repositories/
│   ├── repository.dart
│   ├── shared_preferences_task_repository.dart
│   └── task_repository.dart
├── screens/
│   └── home_screen.dart
├── services/
│   └── task_service.dart
└── widgets/
    ├── task_card.dart
    └── task_editor_sheet.dart

test/
├── home_screen_test.dart
├── shared_preferences_task_repository_test.dart
├── task_model_test.dart
├── task_repository_test.dart
└── task_service_test.dart
```

The app is split by responsibility:

- **Models** describe task data and convert it to and from JSON.
- **Repositories** define and implement task storage.
- **TaskService** applies task rules, validates input, generates IDs, and sorts
  tasks.
- **HomeScreen** coordinates loading, filtering, and user actions.
- **Widgets** render reusable task cards and the add/edit form.
- **Tests** check models, service behavior, storage, and user flows.

### One task from the form to local storage

When a user saves the editor form, the form returns a `TaskDraft`. The home
screen passes that draft's values to the service. The service validates them,
creates a `BasicTask` or `UrgentTask`, and asks the repository to save it.

The repository converts tasks to JSON and stores that JSON under the
`tasks` preference key. When the app loads, the repository decodes the JSON and
`TaskFactory` recreates the correct task subtype.

The stored record is conceptually similar to:

```json
{
  "id": 1,
  "title": "Prepare the demo",
  "priority": "high",
  "dueDate": "2026-10-20T00:00:00.000",
  "completed": false,
  "urgencyLevel": 4,
  "type": "urgent"
}
```

The `type` field is important: it allows the factory to distinguish a regular
task from an urgent task when data is restored.

## Main user flows

### Add or edit a task

The editor collects the title, priority, optional due date, and urgency
settings. It validates the title before returning the draft. The service
validates it again so that business rules are enforced even if another part of
the app calls the service directly.

### Complete a task

The task card calls a callback when its completion control is tapped. The home
screen asks the service to toggle the task's completion state, reloads the
stored tasks, and displays the updated card.

### Filter and sort

The service sorts the task list by priority or due date. The home screen
filters the returned list into all, pending, or completed tasks. Filtering only
changes what is displayed; it does not delete or rewrite hidden tasks.

### Delete and undo

The repository removes the task from saved data. The home screen keeps the
task briefly for the undo action shown in a `SnackBar`. If the user chooses
undo, the task is added back to the repository.

## Tests

The suite covers:

- Model serialization and task subtype restoration.
- Service validation, ID generation, sorting, and completion behavior.
- Repository add, update, delete, and lookup behavior.
- Shared-preferences persistence with a mocked device store.
- Screen flows for empty state, adding, editing, completing, deleting, and
  filtering tasks.
- App-widget recreation while the mocked preference data remains available.

Run all tests from the project directory:

```sh
flutter test
```

## Reference and implementation choices

The internship brief links to
[dwyl's Flutter Todo List tutorial](https://github.com/dwyl/flutter-todo-list-tutorial),
which demonstrates task management with Riverpod and also discusses an API
integration. Task List follows the same broad learning goal but uses a different
structure: a task service and repository contract, with on-device storage for
this version. The tutorial is a reference for learning, not code copied into
this project.

## Known limitations

- Tasks are stored on one device and are not backed up or synchronized.
- `shared_preferences` is appropriate for a small learning project. For
  larger datasets or stronger data guarantees, use a local database such as
  SQLite/Drift.
- The release Android build still needs a real application ID and a private
  release signing key before publishing to an app store. Never commit a
  signing key or its password.
- For very large task lists, consider replacing the eagerly built list with a
  lazy sliver list.

## Add this project to the CognoRise internship repository

The internship repository's top-level README should describe the whole
portfolio. Keep this project's detailed guide in its own folder, for example:

```text
CognoRise-InfoTech/
├── README.md
└── projects/
    ├── project-04-todo-list/
    │   ├── README.md
    │   ├── pubspec.yaml
    │   ├── lib/
    │   ├── test/
    │   └── docs/
    │       └── media/
    ├── project-05/
    │   └── README.md
    └── project-06/
        └── README.md
```

Each project gets its own README, screenshots, and demo links. The top-level
README stays short and links to each project. For example, add a section like
this to the portfolio README:

```markdown
## Projects

### Project 4 — Task List

A Flutter task manager with local persistence, task filters, and priority
sorting.

[Open the project guide](projects/project-04-todo-list/README.md)
```

Do not replace the portfolio's root README with this file. Copy the app into
its project folder and use this README as that folder's `README.md`.
