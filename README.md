# TaskFlow

A lightweight, robust project management system where users belong to organizations, create and manage projects, view and update tasks, assign work, and receive task-related notifications.

## Project Overview and Architecture Explanation
TaskFlow is a fully functional offline-first Flutter application utilizing mock data. The application follows a **Clean Architecture** combined with a **Feature-First** structure. By separating the UI, business logic, and data layer, the app becomes highly modular and testable. The `MockDataSource` acts as a substitute for a real backend (REST/GraphQL API), parsing local JSON files and executing CRUD operations in-memory.

The architecture comprises:
- **Presentation Layer**: Flutter widgets and screens.
- **State Management Layer**: Riverpod providers managing async data loading, caching, and state transitions (Initial -> Loading -> Success -> Error).
- **Domain Layer**: Freezed models (`models.dart`) and abstract Repository interfaces (`repositories.dart`) defining the contracts.
- **Data Layer**: Concrete implementation of the repositories (`repositories_impl.dart`) using `MockDataSource` and `SharedPreferences` (for offline caching and mock token storage).

## Folder Structure
```
lib/
├── core/
│   ├── router.dart         # GoRouter configuration & route guards
│   └── theme.dart          # Light/Dark mode themes & typography
├── data/
│   ├── data_sources/       # mock_data_source.dart (Reads assets/mock_data/mock-data.json)
│   ├── repositories/       # repositories_impl.dart (Concrete implementations)
│   └── services/           # local_cache_service.dart & sync_service.dart (Offline Queue)
├── domain/
│   ├── models/             # Freezed models (Project, Task, AuthCredentials, AppNotification)
│   └── repositories/       # Abstract repository interfaces
├── presentation/
│   ├── providers/          # providers.dart (Riverpod Notifiers & global state)
│   └── screens/            # UI Screens (Login, Dashboard, Project Details, Task Details, Settings)
└── main.dart               # Entry point
```

## State Management Approach
We use **Riverpod 2.0** (`flutter_riverpod`) for robust state management and dependency injection:
- `StateNotifier / AsyncNotifier` handles transitions natively mapping to `AsyncValue.loading()`, `AsyncValue.data()`, and `AsyncValue.error()`.
- **Dependency Injection**: We inject repository interfaces (`projectRepositoryProvider`) instead of concrete classes, which makes it extremely easy to mock during tests (using `ProviderScope` overrides).
- **No excessive setState()**: Complex data fetches, deletions, and filtering operations happen strictly inside Notifiers.

## Mock Data Layer Approach
- **Data Initialization**: The app reads `assets/mock_data/mock-data.json` exactly once and keeps the entire state in a private in-memory map within `MockDataSource`.
- **Artificial Delay**: An artificial network delay of 500-1000ms is simulated using `Future.delayed` on every "request" to adequately demonstrate loading states.
- **Error Simulation**: We can globally force simulated Network Error or 404 Exceptions via debug toggles. 
- **Offline Mode**: A simulated offline switch throws `SocketException`. The `SyncService` captures pending operations (e.g. creating a task offline) into a local `SharedPreferences` queue. When toggled back online, it syncs those pending operations automatically.
- **Local Caching**: On successful fetches, `LocalCacheService` persists JSON data to `SharedPreferences` to ensure offline availability.

## Auth/Token Flow (Simulated)
1. **Login**: The user enters mock credentials. `AuthRepository` validates them against the JSON data.
2. **Tokens**: If valid, a simulated token pair (`access_token`, `refresh_token`) is stored securely using `flutter_secure_storage`.
3. **App Startup**: The `AuthNotifier` checks for the presence of the mock token upon launch and automatically routes to the `/dashboard`.
4. **Biometrics**: Simulated biometric authentication executes post-login validation.
5. **Logout**: Deletes the tokens and forces navigation back to `/login`.

## Setup & Execution

### Prerequisites
- Flutter SDK (`>=3.5.0`)
- Dart SDK (`>=3.5.0`)
- Android Studio / Xcode

### Local Setup
1. Fetch dependencies:
   ```bash
   flutter pub get
   ```
2. Generate Freezed/JSON Serializable models (if modifying data models):
   ```bash
   dart run build_runner build -d
   ```

### How to Run
Run on an emulator or physical device:
```bash
flutter run
```

### How to Test
Execute Unit, Widget, and Integration tests, and view coverage:
```bash
flutter test
flutter test --coverage
```

### How to Build APK
Build the release Android package:
```bash
flutter build apk --release
```

## How to Trigger Simulated Error/Offline States
For reviewer testing, open the application and authenticate.
1. Tap the **Settings (⚙️ Gear Icon)** on the top-right corner of the Dashboard.
2. **Simulate Offline Mode**: Toggle this ON. Attempt to fetch a new project or task; it will instantly fail and use cached data (or show an offline message). You can create a Task offline, and it will be queued. Toggle back OFF to "sync" it.
3. **Simulate API Error**: Toggle this ON. Any subsequent fetch or mutation will simulate a random API error (e.g., Timeout or 500 Server Error) to demonstrate error snackbars/banners.

### Test Credentials
Use the following credentials from `mock-data.json` to test role-based behavior. **Password for all is `Password123!`**.

**Org A: Nimbus Digital**
- **Admin**: `ava.admin@nimbusdigital.test`
- **Member**: `marcus.member@nimbusdigital.test`

**Org B: Harborlight Studios**
- **Admin**: `daniel.admin@harborlightstudios.test`
- **Member**: `elena.member@harborlightstudios.test`

## Known Limitations and Technical Decisions/Trade-offs
1. **In-Memory State Loss**: Since the mock backend executes operations purely in memory, performing a full app hot-restart will wipe out mutations (new tasks/projects) created in the session unless they were stored in the offline sync queue.
2. **Lack of True Database**: We opted for `SharedPreferences` for local caching. In a large-scale real-world application, `sqflite`, `Isar`, or `Hive` would be preferred for high-performance offline querying and relational data.
3. **Simulated Cancellation**: "Request cancellation" is basic and only terminates artificial `Future.delayed` loops because actual network `Dio/http` tokens are not in play.
4. **Task Filters offline**: Filtering tasks while in offline mode currently relies heavily on what is already available in the provider's active memory; advanced complex filtering logic does not hit a SQLite database. 
