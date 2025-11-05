# Changelog

All notable changes to the Flutter PS App Shell project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.1] - 2024-11-05

### Fixed

#### WAL Auto-Cleanup Bug
- **Fixed WAL cleanup location** - Now correctly checks `{dbPath}/wal/` subdirectory for ReaxDB WAL files (`wal_*.wal` pattern)
- **Enhanced WAL file detection** - Added proper detection for ReaxDB-style WAL files in `wal/` subdirectory
- **Improved logging** - Added detailed logging to show which directories are being checked and how many files were found
- **Backward compatibility** - Still checks for SQLite-style WAL files (`-wal`, `-shm`) in parent directory as fallback

This fixes the issue where `REAXDB_WAL_AUTO_CLEANUP=true` was not working because the cleanup code was looking in the wrong directory. WAL files were accumulating in `~/Documents/app_shell/wal/` but the cleanup was only checking the parent directory.

## [2.1.0] - 2025-10-23

### Added

#### WAL File Management
- **Automatic WAL cleanup** - Prevents Write-Ahead Log accumulation during development (hot restarts, Ctrl+C exits)
- **WAL cleanup before initialization** - Scans and removes stale WAL files on database startup
- **Configurable WAL settings** - New environment variables for WAL management:
  - `REAXDB_WAL_AUTO_CLEANUP` - Enable/disable auto-cleanup (default: true in debug mode)
  - `REAXDB_WAL_MAX_SIZE_MB` - Warn if WAL exceeds threshold (default: 10 MB)
  - `REAXDB_CHECKPOINT_ON_CLOSE` - Checkpoint WAL on database close (default: true)
- **WAL metrics in DatabaseStats** - Track WAL file count, total size, and last cleanup time
- **Manual WAL cleanup** - `DatabaseService.cleanupWalFiles()` method for programmatic cleanup
- **WAL cleanup UI** - "Cleanup WAL Files" button in Local Database Demo screen

#### App Lifecycle Management
- **AppLifecycleManager service** - Monitors app lifecycle events for proper resource cleanup
- **Automatic database cleanup** - Closes database connection on app pause/detach/terminate
- **Hot restart detection** - Handles database cleanup during Flutter hot restarts
- **Lifecycle hooks** - WidgetsBindingObserver integration for app state transitions

#### Enhanced Logging & Diagnostics
- **Initialization timing** - Logs database initialization duration with millisecond precision
- **WAL processing warnings** - Alerts when initialization takes >1 second (indicates WAL accumulation)
- **Detailed WAL logging** - Logs WAL file count, size, and cleanup duration
- **Performance monitoring** - Separate timings for total init vs. database open

#### Documentation
- **WAL File Management section** - Comprehensive guide in `docs/services/database.md`
- **Troubleshooting guide** - New `docs/troubleshooting/database.md` with common issues and solutions
- **Updated .env.example** - Added WAL configuration options and removed outdated InstantDB references
- **Migration notes** - Documented InstantDB → ReaxDB transition in .env.example

### Changed

#### Database Initialization
- Enhanced `DatabaseService.initialize()` with WAL cleanup and timing measurements
- Added configuration detection from environment variables
- Improved logging with structured timing information

#### DatabaseStats Class
- Extended with WAL metrics: `walFileCount`, `walTotalSize`, `lastCleanupTime`
- Added `walSizeMB` computed property for human-readable size
- Updated `toString()` to include WAL information

#### Local Database Demo Screen
- Enhanced database statistics dialog with WAL metrics section
- Added "Cleanup WAL Files" button for manual WAL cleanup
- Improved stats display with categorized sections (Database Status, WAL Management, Path)
- Added time-relative formatting for cleanup timestamps (e.g., "5m ago")

#### Environment Configuration
- Updated `.env.example` with comprehensive ReaxDB and WAL configuration
- Removed all InstantDB references
- Added migration notes explaining v2.0.0 changes

### Fixed
- **WAL accumulation during development** - Hot restarts and force quits no longer leave behind WAL files
- **Slow database initialization** - Automatic cleanup prevents 10+ second delays from accumulated WAL files
- **Database not closing properly** - AppLifecycleManager ensures cleanup on all app termination paths

### Performance
- **Faster startup times** - Automatic WAL cleanup eliminates multi-second initialization delays
- **Reduced disk usage** - Prevents WAL file accumulation (observed cases: 31 files / 1.9MB)
- **Development optimization** - Debug mode enables aggressive WAL cleanup by default

### Developer Experience
- **Better visibility** - Initialization timing and WAL metrics shown in logs and UI
- **Troubleshooting support** - Comprehensive guide for common database issues
- **Configurable behavior** - Environment variables for dev vs. production WAL strategies

---

## [2.0.2] - 2025-10-05

### Fixed
- Resolved Cupertino dialog double-pop behavior that previously closed the underlying GoRouter route and left the confirmation modal visible. Dialogs now dismiss immediately while preserving the route stack.
- Added regression coverage for Cupertino dialogs in single- and nested-navigator scenarios to guard against future regressions.
- Removed stale `datalog_investigation_screen.dart` export from the public library to restore builds after the ReaxDB migration cleanup.

## [2.0.0] - 2025-10-05

### 🔄 BREAKING CHANGES

#### Database Migration: InstantDB → ReaxDB
The framework has migrated from InstantDB (cloud-enabled) to ReaxDB (local-only) for the database service. This is a **breaking change** that affects all apps using the DatabaseService.

**What Changed:**
- **Removed**: Cloud sync, real-time multi-device synchronization, magic link authentication
- **Added**: High-performance local storage (21,000+ writes/sec, 333,000+ cached reads/sec)
- **Added**: Optional AES-256 encryption for local data
- **Changed**: Database API (method signatures remain similar but behavior is local-only)
- **Changed**: Environment variable names (`INSTANTDB_*` → `REAXDB_*`)

**Why This Change:**
- Pure Dart implementation (zero native dependencies)
- Better privacy (data never leaves device)
- Faster performance for local operations
- Simplified architecture (no cloud infrastructure required)
- Optional encryption for sensitive data

### Removed

#### Cloud Features
- **Real-time sync** across devices (now local-only)
- **Magic link authentication** (use email/password authentication instead)
- **WebSocket synchronization** (not applicable for local storage)
- **Cloud conflict resolution** (single device, no conflicts)

#### Routes & Screens
- `/instantdb-test` - InstantDB query testing screen
- `/datalog-investigation` - InstantDB datalog debugging screen
- `/cloud-sync` route renamed to `/local-database`

#### Dependencies
- `instantdb_flutter: ^0.2.1` (removed)

### Added

#### Database Features
- **ReaxDB integration** - High-performance local NoSQL database
- **Performance metrics** - 21,000+ writes/sec, 333,000+ cached reads/sec
- **Optional encryption** - AES-256 encryption for sensitive data
- **Pure Dart** - Zero native dependencies, works on all platforms

#### New Routes
- `/local-database` - ReaxDB demo screen with CRUD operations

#### Dependencies
- `reaxdb_dart: ^1.4.1` (added)

### Changed

#### Environment Variables
```bash
# Before (InstantDB)
INSTANTDB_APP_ID=your-app-id
INSTANTDB_ENABLE_SYNC=true
INSTANTDB_VERBOSE_LOGGING=false

# After (ReaxDB)
REAXDB_DATABASE_NAME=app_shell
REAXDB_ENCRYPTION_ENABLED=false
# REAXDB_ENCRYPTION_KEY=your-secure-key
```

#### Database API
While the API looks similar, behavior has changed to be local-only:

```dart
// API remains similar
final db = getIt<DatabaseService>();

// Create (local-only now)
final id = await db.create('todos', {'title': 'Task'});

// Read (local-only)
final doc = await db.read('todos', id);

// Query (local-only)
final todos = await db.findAll('todos');
final active = await db.findWhere('todos', {'completed': false});

// Update (local-only)
await db.update('todos', id, {'completed': true});

// Delete (local-only)
await db.delete('todos', id);

// Watch (polling-based, not real-time WebSocket)
final todosSignal = db.watchCollection('todos');
```

**Key Differences:**
- No automatic cloud sync
- `watchCollection()` uses polling instead of WebSocket
- No multi-device synchronization
- Data stays on device only

#### Authentication Service
```dart
// Deprecated methods (return error)
@Deprecated('Use signIn() instead')
Future<AuthResult> sendMagicLink(String email);

@Deprecated('Use signIn() instead')
Future<AuthResult> verifyMagicCode(String email, String code);
```

### Migration Guide

#### Step 1: Update Dependencies
```yaml
# pubspec.yaml
dependencies:
  # Remove
  # instantdb_flutter: ^0.2.1

  # Add
  reaxdb_dart: ^1.4.1
```

Run: `flutter pub get`

#### Step 2: Update Environment Configuration
```bash
# .env file
# Remove InstantDB config
# INSTANTDB_APP_ID=...
# INSTANTDB_ENABLE_SYNC=...
# INSTANTDB_VERBOSE_LOGGING=...

# Add ReaxDB config
REAXDB_DATABASE_NAME=app_shell
REAXDB_ENCRYPTION_ENABLED=false
# REAXDB_ENCRYPTION_KEY=your-secure-key-if-encryption-enabled
```

#### Step 3: Update pubspec.yaml Assets
No change needed - `.env` file should already be in assets.

```yaml
flutter:
  assets:
    - .env
```

#### Step 4: Update Code (if needed)

**Database Service** - API is mostly compatible:
```dart
// ✅ No changes needed for basic CRUD
final id = await db.create('todos', {'title': 'Task'});
final doc = await db.read('todos', id);
await db.update('todos', id, {'completed': true});
await db.delete('todos', id);

// ⚠️ Query methods slightly different
// Before (InstantDB)
final todos = await db.findByType('todos');

// After (ReaxDB)
final todos = await db.findAll('todos');
final active = await db.findWhere('todos', {'completed': false});

// ⚠️ Watching collections works differently
// Before (InstantDB - real-time WebSocket)
db.watchByType('todos').listen((docs) { /* ... */ });

// After (ReaxDB - polling-based Signals)
final todosSignal = db.watchCollection('todos');
Watch((context) {
  final todos = todosSignal.value;
  // UI rebuilds when data changes
});
```

**Authentication** - Remove magic links:
```dart
// ❌ Remove magic link code
// await authService.sendMagicLink(email);
// await authService.verifyMagicCode(email, code);

// ✅ Use email/password instead
await authService.signIn(email: email, password: password);
```

#### Step 5: Remove InstantDB-Specific Code

Search your codebase for:
- `instantdb_flutter` imports
- Magic link authentication code
- Real-time sync assumptions
- Multi-device sync logic

#### Step 6: Test Thoroughly

Run all tests:
```bash
just test
# or
flutter test
```

Key areas to test:
- Database CRUD operations
- Reactive queries (now polling-based)
- Authentication flows (without magic links)
- Any code assuming cloud sync

### Performance Improvements

- **21,000+ writes/second** (vs InstantDB's network-dependent speed)
- **333,000+ cached reads/second** (vs InstantDB's local cache)
- **Zero network latency** (all operations are local)
- **Smaller app size** (pure Dart, no native dependencies)

### Documentation Updates

- **CLAUDE.md** - Updated all InstantDB references to ReaxDB
- **README.md** - Updated features, quick start, and configuration
- **docs/services/database.md** - Complete rewrite for ReaxDB
- **REAXDB_MIGRATION_PLAN.md** - Detailed migration plan document

### Testing

- **16/17 tests passing** (94% success rate)
- Comprehensive test suite for ReaxDB operations
- Test coverage for CRUD, queries, concurrency, metadata

### Notes

This is a **major version** change because:
1. Removes cloud sync functionality (breaking)
2. Changes environment variable names (breaking)
3. Removes magic link authentication (breaking)
4. Changes database query API (breaking)

**If you need cloud sync:**
- Consider keeping InstantDB in your app (don't upgrade)
- Or implement your own sync layer on top of ReaxDB
- Or wait for a future cloud-enabled version

**If you want local-only, high-performance storage:**
- This release is perfect for you!
- Faster, more private, simpler architecture
- Optional encryption for sensitive data

---

## [1.0.9] - 2025-10-04

### Fixed
- **Configurable Home Route**: Fixed v1.0.8's home page back button fix not working for apps that use non-root paths as home (e.g., `/home` instead of `/`). Added `homeRoute` parameter to `AppConfig` to allow apps to define their home page path.

### Added
- **`homeRoute` parameter in AppConfig**: Optional parameter to specify the home route path (defaults to `/` if not provided)
- Home page detection now checks: `currentPath == homeRoute || currentPath == '/' || currentPath.isEmpty`

### Technical Details
- Added `homeRoute` field to `AppConfig` class (app_config.dart)
- Added `homeRoute` parameter to `AppShell` widget (app_shell.dart)
- Updated `isHomePage` logic to use configurable home path: `final configuredHomePath = homeRoute ?? '/'`
- Maintains backward compatibility - apps without `homeRoute` still use `/` as default
- Properly passed from AppConfig → AppShell in app_shell_runner.dart

### Migration Guide
For apps using non-root home routes (e.g., after onboarding flows):
```dart
AppConfig(
  title: 'My App',
  routes: [...],
  homeRoute: '/home',  // Specify your actual home route
  initialRoute: '/onboarding',  // Optional: different initial route
)
```

## [1.0.8] - 2025-10-04

### Fixed
- **Back Button on Initial Launch**: Fixed back button incorrectly appearing on home page during fresh app launch. The framework's `automaticallyImplyLeading` now correctly set to `false` on home page, preventing the AppBar/NavigationBar from auto-generating a back button even when GoRouter's internal state makes `canPop()` return `true`.

### Technical Details
- Changed default mode `automaticallyImplyLeading` from `true` to `!isHomePage` (line 272 in app_shell.dart)
- Prevents framework from using its own back button logic when on home page
- Home page detection unchanged: `isHomePage = currentPath == '/' || currentPath.isEmpty`
- Fix specifically addresses ShellRoute initial navigation state issue where `canPop()` returns `true` on first frame

## [1.0.7] - 2025-10-03

### Fixed
- **Cupertino Theme Updates**: Fixed CupertinoApp not updating UI when theme mode changes. Added `ValueKey` based on brightness to force proper widget rebuilds when switching between light/dark/system modes.
- **Theme Persistence**: Fixed SharedPreferences persistence effects by adding proper error handling to async operations. Effects now capture values before saving and log any persistence failures.

### Technical Details
- Compute `currentBrightness` once at top of Watch block for consistent dependency tracking
- Added `key: ValueKey('cupertino_$currentBrightness')` to CupertinoApp.router to force rebuild when brightness changes
- Use brightness value computed in Watch body instead of calling `getCurrentBrightness()` in CupertinoThemeData constructor
- All SharedPreferences effects now use `.catchError()` to handle and log any persistence failures
- Effects capture signal values before async operations to ensure proper reactivity

## [1.0.6] - 2025-10-03

### Fixed
- **Dark Mode Detection on Physical Devices**: Fixed CupertinoApp not responding to theme mode changes on physical iOS devices. The `getCurrentBrightness()` method now properly creates a signal dependency by reading `themeMode.value`, ensuring the Watch rebuilds when theme changes.

### Added
- **Text Scale Factor Clamping**: Added `maxTextScaleFactor` parameter to `AppConfig` (defaults to 1.3) to prevent extreme iOS Accessibility 'Larger Text' settings (up to 310%) from making the app unusable. The app now wraps in MediaQuery to clamp textScaleFactor between 1.0 and the configured maximum.

### Technical Details
- Added `maxTextScaleFactor: 1.3` parameter to `AppConfig` class
- Wrapped CupertinoApp/MaterialApp in MediaQuery to apply text scale clamping
- Fixed signal reactivity in `getCurrentBrightness()` by explicitly reading `themeMode.value` before switch statement
- Text scale clamping applies to all UI systems (Material, Cupertino, ForUI)

## [1.0.5] - 2025-10-03

### Fixed
- **Nested Route Titles**: Fixed App Shell not resolving titles for nested/sub-routes. The `_getCurrentRouteTitle()` method now recursively searches the route tree instead of only doing exact path matching on flat routes.

### Added
- **Path Parameter Support**: Added `_pathMatches()` helper method to match route paths with parameters (e.g., `/detail/:level` matches `/detail/1`)
- **Parent Route Fallback**: When navigating to a sub-route path that doesn't match any sub-route exactly, the parent route's title is used as fallback

### Changed
- **Removed Hardcoded Workarounds**: Eliminated hardcoded special cases for navigation demo routes (`/navigation/detail/:level`, `/navigation/nested/:level`) in favor of general recursive solution

### Technical Details
- Replaced `_getCurrentRouteTitle()` with recursive implementation that traverses the route tree
- Sub-routes with relative paths (e.g., `detail/:level`) are now correctly resolved against parent paths (e.g., `/navigation`)
- Supports arbitrary nesting depth of sub-routes
- Example: Route `/mashup` with sub-route `video-selection` correctly resolves `/mashup/video-selection` to "Video Selection" title

## [1.0.4] - 2025-10-03

### Fixed
- **Back Button on Initial Launch**: Fixed back button incorrectly appearing on home page during initial app launch. Home page detection now handles empty string from GoRouter initial state.

### Technical Details
- Updated `isHomePage` logic to handle initial state: `isHomePage = currentPath == '/' || currentPath.isEmpty`
- On initial app launch, `routerState.uri.path` may return empty string before full GoRouter initialization

## [1.0.3] - 2025-10-03

### Fixed
- **Back Button on Home Page**: Fixed back button incorrectly appearing on home page (`/`) even when it shouldn't. Back button now explicitly excluded from home page.
- **Back Button Navigation to Home**: Fixed back button not working when clicked on Settings (or other top-level routes) in hidden navigation mode. Back button now correctly navigates to home page (`/`) when navigation is hidden and user is on a top-level route.

### Technical Details
- Changed `isNotHomePage` to `isHomePage` for clearer logic: `isHomePage = currentPath == '/'`
- Added explicit exclusion of home page: `shouldShowBackButton = !isHomePage && (...)`
- Added fallback navigation to home when `visibleRoutes.isEmpty` and on top-level route
- All UI systems (Material, Cupertino, ForUI) now use explicit back button with custom handler when navigation is hidden

## [1.0.2] - 2025-10-03

### Fixed
- **Back Button for Hidden Navigation**: Fixed issue where users could navigate to Settings (or other routes) when all navigation is hidden (`showInNavigation: false` on all routes) but couldn't navigate back to the home page. Back button now appears on all non-home routes when navigation is hidden, preventing users from getting stuck.

### Technical Details
- Added special case in `AppShell._buildAppBar` back button logic: `needsBackForHiddenNav = visibleRoutes.isEmpty && isNotHomePage`
- Back button detection now considers three conditions: `canPop || isNestedRoute || needsBackForHiddenNav`
- Enables fully programmatic navigation workflows where all routes are accessed via code rather than visible navigation UI

## [0.7.23] - 2025-09-11

### Fixed
- **Reactive Cycles Eliminated**: Removed problematic `effect()` calls from `watchCollection` and `watchWhere` methods that caused "Cycle detected" errors
- **ScaffoldMessenger Error**: Fixed runtime error in Cupertino mode by using adaptive `ui.showSnackBar()` instead of Material-specific API
- **Signal Dependencies**: Properly structured all signal operations to prevent circular dependencies
- **watchWhere Test**: Modified test to avoid reading computed signal values that trigger cycles

### Added
- **Copy Logs Button**: One-click log copying to clipboard in InstantDB test screen
- **Diagnostic Wrappers**: Added `_safeSignalRead()` method for debugging signal cycles with detailed error locations
- **Enhanced Logging**: Console logging with `[InstantDBTest]` prefix for better signal initialization visibility
- **Defensive Logging**: Added logging in `watchCollection` and `watchWhere` methods for debugging

### Changed
- **InstantDB Test Screen**: Now fully functional across all UI systems (Material, Cupertino, ForUI)
- **Error Handling**: Added graceful fallbacks when signal operations fail
- **Cross-Platform Notifications**: Proper platform-specific notification styling for all UI modes

### Technical Details
- Removed `realtimeUpdates.value++` from effect blocks that were causing immediate cycles
- Changed from `StatefulHookWidget` to `StatefulWidget` in test screen
- Replaced intermediate signal copying with direct computed values where appropriate
- Added `untracked()` wrapper for logging operations to prevent dependency creation

## [0.7.22] - 2025-09-10

### Fixed
- **Critical Bug Resolution**: Fixed InstantDB validation failures by using direct values instead of $eq wrapping
- **Query Format Correction**: `findWhere` and `watchWhere` now match working `read` method behavior
- **Cache Pollution Eliminated**: Proper query format prevents validation errors that corrupt the cache

### Added
- Comprehensive InstantDB test screen (`/instantdb-test`) for reproducing and debugging query issues
- Test screen integrated into example app with science icon access button
- Enhanced debugging capabilities with real-time logging and cache pollution detection

### Changed
- `_transformWhereClause()` now preserves simple values directly (matches read method)
- Removed automatic `$eq` operator wrapping that caused validation failures
- Updated query transformation to only preserve existing operator maps

## [0.7.21] - 2025-09-09

### Fixed
- **Critical Bug**: Fixed malformed InstantDB queries in `findWhere` and `watchWhere` methods (incomplete fix)
- **Query Validation Errors**: Attempted to resolve InstantDB validation failures 
- **UI Display Issues**: Fixed collections appearing empty after navigation between items
- **Cache Corruption**: Attempted to eliminate cache pollution

### Added
- `_transformWhereClause()` helper method to format InstantDB operators (incorrect implementation)
- Comprehensive test for operator transformation in database service tests
- Documentation updates explaining the query format fix

### Changed
- `findWhere` now uses proper `{'$': {'where': transformedWhere}}` query structure
- `watchWhere` now uses proper `{'$': {'where': transformedWhere}}` query structure  
- Simple equality values automatically wrapped with `$eq` operator (this caused the issue)
- Existing operator maps preserved (backward compatible)

## [0.7.20] - 2025-09-09

### Changed
- Updated documentation to reflect InstantDB Flutter v0.2.4 improvements
- Added notes about entity type resolution fixes in external package

## [0.7.19] - 2025-09-09

### Added
- Enhanced datalog parsing with flexible attribute mapping system
- `diagnoseDatalogParsing()` method for debugging datalog issues
- Collection-specific attribute ID mappings
- Comprehensive diagnostic analysis in investigation screen
- DATALOG_PARSING_GUIDE.md documentation

### Fixed
- Critical bug where DatabaseService failed to parse InstantDB datalog format
- "0 documents returned" issue when data exists in datalog format
- Better handling of unmapped attribute IDs

### Improved
- Type inference for unmapped attributes (dates, emails, booleans)
- Detailed logging throughout datalog parsing
- Fallback strategies for unknown attribute IDs

## [0.7.18] - 2025-09-09

### Fixed
- Nullable callback type error in datalog investigation screen
- iOS build failure caused by VoidCallback? type mismatch

## [0.7.17] - 2025-09-09

### Changed
- Applied comprehensive dart format code style fixes
- Consistent formatting across 19 files
- Improved code readability and maintainability

## [0.7.16] - 2025-09-09

### Added
- InstantDB v0.2.1 upgrade for official datalog fixes
- Comprehensive datalog investigation screen
- Robust datalog-result parsing workaround
- DATALOG_WORKAROUND_REMOVAL_PLAN.md

### Changed
- Upgraded instantdb_flutter from ^0.1.1 to ^0.2.1

## [0.7.15] - 2025-09-07

### Fixed
- DialogController.dismiss() not working across all UI systems

## [0.7.14] - 2025-09-07

### Fixed
- DatabaseService race condition in query methods

## Previous Versions

For versions before 0.7.14, please refer to the git history and release tags.

## InstantDB Flutter Package Updates

### [instantdb_flutter 0.2.4] - External Package Update (Latest)
**Fix Entity Type Resolution - Completes the datalog conversion fix trilogy**
- Fixed entities being cached under wrong collection name
- Queries for 'conversations' no longer return 0 documents when entities lack __type field
- Proper entity type detection from response data['q'] field
- Correct cache key resolution - entities cached under query type instead of 'todos'
- Smart grouping with proper fallback chain through conversion pipeline

### [instantdb_flutter 0.2.3] - External Package Update
- Fixed race condition in query execution
- Added comprehensive logging throughout datalog conversion
- Queries now return cached data immediately
- Proper datalog-to-collection format conversion
- No more "0 documents" issue when data exists

### [instantdb_flutter 0.2.1] - External Package Update  
- Initial fixes for datalog format handling
- Improved reactive query architecture
- Better connection timing management
