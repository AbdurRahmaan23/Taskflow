# TaskFlow

A lightweight project management system where users belong to organizations, create and manage projects, view and update tasks, assign work, and receive task-related notifications.

## Architecture
This project follows a Clean Architecture approach to separate concerns and make the mock data layer easily swappable with a real REST API later.

- **`core/`**: Routing configuration (GoRouter), constants, and theming.
- **`domain/`**: Business logic, data models (Freezed), and repository interfaces (`AuthRepository`, `ProjectRepository`, etc.).
- **`data/`**: `MockDataSource` parsing the local `mock-data.json`, and implementations of the repository interfaces to handle in-memory state mutations.
- **`presentation/`**: Flutter UI components (screens/widgets) and Riverpod state management providers linking the UI to the domain layer.

## State Management
We use **Riverpod** (`flutter_riverpod`) for robust state management and dependency injection.
- The `authStateProvider` governs the global logged-in user state.
- `projectsProvider` and `tasksProvider` handle asynchronous data loading with built-in loading and error states.

## Mock Data Layer
The app does not make actual network requests. Instead, it reads from `assets/mock_data/mock-data.json`.
- `MockDataSource` parses the JSON exactly once upon startup.
- It simulates an artificial network delay of 500ms for all "requests".
- **Error/Offline Simulation**: You can toggle `simulateOffline` or `simulateError` booleans directly in `MockDataSource` to force network errors or timeout states for testing the UI.

## Setup & Running
**Prerequisites:**
- Flutter SDK

**Commands:**
1. Fetch dependencies:
   ```bash
   flutter pub get
   ```
2. Run code generation for Freezed models (if you make changes to models):
   ```bash
   dart run build_runner build -d
   ```
3. Run the app:
   ```bash
   flutter run
   ```
4. Build Release APK:
   ```bash
   flutter build apk --release
   ```

## Test Credentials
Use the following credentials from `auth_mock.json` to test role-based behavior. Password for all is `Password123!`.
- **Admin**: `ava.admin@nimbusdigital.test` (Nimbus Digital)
- **Member**: `marcus.member@nimbusdigital.test` (Nimbus Digital)
