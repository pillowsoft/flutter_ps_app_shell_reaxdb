# ReaxDB Migration Plan: InstantDB → ReaxDB

**Version:** 1.0
**Status:** Draft
**Last Updated:** 2025-10-05

## Executive Summary

This document provides a comprehensive, step-by-step plan to migrate the Flutter App Shell framework from **InstantDB** (cloud-enabled database with authentication) to **ReaxDB** (local-only NoSQL database). The migration maintains the service-oriented architecture while eliminating cloud dependencies and simplifying the database layer.

### Key Objectives

1. ✅ **Preserve Architecture** - Maintain the service layer abstraction pattern
2. ✅ **Local-Only Database** - Replace InstantDB with ReaxDB for pure local storage
3. ✅ **Simplified Authentication** - Remove cloud auth, keep local biometric/token auth
4. ✅ **Zero Code Generation** - Continue the no-codegen philosophy
5. ✅ **Maintain API Compatibility** - Minimize breaking changes to consuming code

---

## Table of Contents

1. [Current State Analysis](#1-current-state-analysis)
2. [Feature Mapping](#2-feature-mapping)
3. [Migration Strategy](#3-migration-strategy)
4. [Implementation Details](#4-implementation-details)
5. [Testing & Validation](#5-testing--validation)
6. [Rollback Plan](#6-rollback-plan)
7. [Timeline & Resources](#7-timeline--resources)

---

## 1. Current State Analysis

### 1.1 InstantDB Usage Patterns

**Current Dependencies:**
```yaml
# packages/flutter_app_shell/pubspec.yaml
dependencies:
  instantdb_flutter: ^0.2.1  # To be replaced
```

**Key Files Using InstantDB:**

| File | Usage | Lines of Code | Complexity |
|------|-------|---------------|------------|
| `database_service.dart` | Core database operations | ~936 lines | High |
| `authentication_service.dart` | Magic link auth only | ~60 lines | Medium |
| `cloud_sync_demo_screen.dart` | Demo/testing | ~100 lines | Low |
| `instantdb_test_screen.dart` | Debug utilities | ~200 lines | Low |
| `datalog_investigation_screen.dart` | Debug utilities | ~150 lines | Low |

**Total Impact:** ~1,446 lines across 5 files

### 1.2 InstantDB Features Currently Used

#### ✅ **Actively Used**
- ✅ Local NoSQL database storage
- ✅ CRUD operations (create, read, update, delete)
- ✅ Query operations (findAll, findWhere)
- ✅ Reactive queries (watchCollection, watchWhere)
- ✅ Document/collection abstraction
- ✅ Basic authentication (magic links - optional feature)

#### ⚠️ **Partially Used**
- ⚠️ Real-time sync (demo only, not production)
- ⚠️ Cloud authentication (optional, local fallback exists)

#### ❌ **Not Used**
- ❌ Advanced datalog queries
- ❌ Presence system
- ❌ Multi-user collaboration features
- ❌ Schema enforcement

### 1.3 Critical Dependencies

**Services Depending on DatabaseService:**
- `AuthenticationService` - User data persistence only
- Example app screens - Demo data
- Service inspector - Statistics display

**Authentication Architecture:**
```
AuthenticationService
├── Local Authentication (Keep ✅)
│   ├── Email/password with SHA-256 hashing
│   ├── JWT-style token generation
│   └── Biometric authentication (local_auth)
├── InstantDB Magic Links (Remove ❌)
│   ├── sendMagicCode()
│   └── verifyMagicCode()
└── Token Management (Keep ✅)
    ├── Token expiry tracking
    └── Refresh token flow
```

---

## 2. Feature Mapping

### 2.1 Database Operations Mapping

| InstantDB Feature | ReaxDB Equivalent | Implementation Notes |
|-------------------|-------------------|---------------------|
| `InstantDB.init()` | `ReaxDB.simple()` | Path-based initialization |
| `db.transact()` | `db.put()` | Direct key-value operations |
| `db.queryOnce()` | `db.get()` | Synchronous reads |
| `db.subscribeQuery()` | `db.watch()` | Stream-based reactivity |
| Collection abstraction | Key prefix pattern | `users:123` instead of `users.doc(123)` |
| Document metadata | Manual tracking | Add `_createdAt`, `_updatedAt` fields |
| Transactions | `db.advanced.transaction()` | For complex operations |

### 2.2 Query Pattern Migration

#### **InstantDB Pattern (Current)**
```dart
// Query all users
final query = {'users': {}};
final result = await db.queryOnce(query);
final users = result.data['users'] as List;

// Query with filter
final query = {
  'users': {
    '\$': {'where': {'status': 'active'}}
  }
};
```

#### **ReaxDB Pattern (Target)**
```dart
// Get all users by prefix pattern
final userKeys = await db.getAll('user:*');
final users = userKeys.map((key) => db.get(key)).toList();

// Filter in application layer
final activeUsers = users.where((u) => u['status'] == 'active').toList();

// Or use advanced querying
final users = await db.advanced.query()
  .where('status', isEqualTo: 'active')
  .execute();
```

### 2.3 Reactive Updates Migration

#### **InstantDB Pattern (Current)**
```dart
// Reactive query
final querySignal = db.subscribeQuery({'users': {}});
final usersSignal = computed(() {
  final result = querySignal.value;
  return result.data['users'] as List? ?? [];
});
```

#### **ReaxDB Pattern (Target)**
```dart
// Watch pattern
final usersStream = db.watch('user:*');
final usersSignal = streamSignal(
  usersStream.map((keys) => keys.map((k) => db.get(k)).toList()),
  initialValue: [],
);
```

### 2.4 Authentication Migration

| Feature | Current (InstantDB) | Target (Local-Only) | Status |
|---------|---------------------|---------------------|--------|
| Email/Password | Local fallback ✅ | Keep as primary ✅ | No change |
| Magic Links | InstantDB cloud ❌ | Remove completely ❌ | Remove |
| Biometric | Local (local_auth) ✅ | Keep ✅ | No change |
| Token Management | Local (SHA-256) ✅ | Keep ✅ | No change |
| User Persistence | SharedPreferences ✅ | Keep ✅ | No change |

---

## 3. Migration Strategy

### 3.1 Phased Approach

#### **Phase 1: Preparation & Setup** (Week 1)
- [ ] Create feature branch: `feature/reaxdb-migration`
- [ ] Add ReaxDB dependency to pubspec.yaml
- [ ] Create parallel ReaxDB service implementation
- [ ] Update environment configuration
- [ ] Document API changes

#### **Phase 2: Core Service Migration** (Week 1-2)
- [ ] Implement new `DatabaseService` with ReaxDB
- [ ] Create collection/document abstraction layer
- [ ] Implement CRUD operations
- [ ] Add reactive query support
- [ ] Migrate metadata tracking

#### **Phase 3: Authentication Updates** (Week 2)
- [ ] Remove InstantDB magic link methods
- [ ] Update authentication service
- [ ] Remove cloud sync status signals
- [ ] Simplify service initialization

#### **Phase 4: Testing & Integration** (Week 3)
- [ ] Update unit tests
- [ ] Update integration tests
- [ ] Test example app screens
- [ ] Performance benchmarking
- [ ] Update documentation

#### **Phase 5: Cleanup & Release** (Week 3-4)
- [ ] Remove InstantDB dependency
- [ ] Remove debug/investigation screens
- [ ] Update CHANGELOG.md
- [ ] Update migration guide
- [ ] Version bump to 2.0.0 (breaking change)

### 3.2 Migration Principles

1. **Backward Compatibility Where Possible**
   - Keep the same public API methods
   - Maintain service locator pattern
   - Preserve signal-based reactivity

2. **Graceful Degradation**
   - Cloud sync features → No-op with warning logs
   - Magic link auth → Error with helpful message

3. **Clear Communication**
   - Mark deprecated methods with `@Deprecated` annotations
   - Provide migration examples in docs
   - Update all example code

---

## 4. Implementation Details

### 4.1 DatabaseService Rewrite

#### **Step 1: Update Dependencies**

```yaml
# packages/flutter_app_shell/pubspec.yaml
dependencies:
  # Remove:
  # instantdb_flutter: ^0.2.1

  # Add:
  reaxdb_dart: ^1.4.1

  # Keep these for data handling:
  path_provider: ^2.1.4  # For database path
  crypto: ^3.0.5         # For ID generation
```

#### **Step 2: New DatabaseService Implementation**

```dart
// packages/flutter_app_shell/lib/src/services/database_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:reaxdb_dart/reaxdb_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:logging/logging.dart';
import 'package:crypto/crypto.dart';
import '../utils/logger.dart';

/// Local-only database service using ReaxDB
/// Provides document/collection abstraction over key-value storage
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  static final Logger _logger = createServiceLogger('DatabaseService');

  ReaxDB? _db;
  String? _dbPath;

  bool get isInitialized => _db != null;

  /// Signal for database connection status
  final connectionStatus = signal<DatabaseConnectionStatus>(
    DatabaseConnectionStatus.disconnected,
  );

  /// Signal for last operation timestamp
  final lastOperationTime = signal<DateTime?>(null);

  /// Initialize the database service
  /// [dbName] is the database name (default: 'app_shell')
  /// [encrypted] enables encryption (default: false)
  Future<void> initialize({
    String dbName = 'app_shell',
    bool encrypted = false,
  }) async {
    if (_db != null) return;

    try {
      connectionStatus.value = DatabaseConnectionStatus.connecting;
      _logger.info('Initializing ReaxDB database service...');

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      _dbPath = '${directory.path}/$dbName';

      // Initialize ReaxDB
      _db = encrypted
          ? await ReaxDB.encrypted(_dbPath!, 'encryption-key-from-config')
          : await ReaxDB.simple(_dbPath!);

      connectionStatus.value = DatabaseConnectionStatus.connected;
      _logger.info('ReaxDB database initialized at: $_dbPath');
    } catch (e, stackTrace) {
      connectionStatus.value = DatabaseConnectionStatus.error;
      _logger.severe('Failed to initialize database', e, stackTrace);
      rethrow;
    }
  }

  /// Close the database connection
  Future<void> close() async {
    if (_db != null) {
      try {
        // ReaxDB doesn't require explicit close
        _db = null;
        _dbPath = null;
        connectionStatus.value = DatabaseConnectionStatus.disconnected;
        _logger.info('Database service closed');
      } catch (e) {
        _logger.warning('Error closing database: $e');
      }
    }
  }

  // CRUD Operations

  /// Create a new document in a collection
  /// Returns the generated document ID
  Future<String> create(String collection, Map<String, dynamic> data) async {
    _ensureInitialized();

    try {
      // Generate document ID
      final id = data['id'] as String? ?? _generateId();

      // Add metadata
      final documentData = {
        ...data,
        'id': id,
        '_type': collection,
        '_createdAt': DateTime.now().toIso8601String(),
        '_updatedAt': DateTime.now().toIso8601String(),
        '_version': 1,
      };

      // Store with key pattern: collection:id
      final key = '$collection:$id';
      await _db!.put(key, documentData);

      lastOperationTime.value = DateTime.now();
      _logger.fine('Created document: $key');
      return id;
    } catch (e, stackTrace) {
      _logger.severe('Failed to create document', e, stackTrace);
      rethrow;
    }
  }

  /// Read a document by ID
  Future<Map<String, dynamic>?> read(String collection, String id) async {
    _ensureInitialized();

    try {
      final key = '$collection:$id';
      final data = await _db!.get(key);

      if (data != null && data is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e, stackTrace) {
      _logger.severe('Failed to read document', e, stackTrace);
      rethrow;
    }
  }

  /// Update a document by ID
  Future<bool> update(
    String collection,
    String id,
    Map<String, dynamic> data,
  ) async {
    _ensureInitialized();

    try {
      final key = '$collection:$id';
      final existing = await read(collection, id);

      if (existing == null) {
        return false;
      }

      // Merge updates with metadata
      final updatedData = {
        ...existing,
        ...data,
        '_updatedAt': DateTime.now().toIso8601String(),
        '_version': (existing['_version'] ?? 0) + 1,
      };

      await _db!.put(key, updatedData);
      lastOperationTime.value = DateTime.now();
      _logger.fine('Updated document: $key');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to update document', e, stackTrace);
      rethrow;
    }
  }

  /// Delete a document by ID
  Future<bool> delete(String collection, String id) async {
    _ensureInitialized();

    try {
      final key = '$collection:$id';
      final existing = await read(collection, id);

      if (existing == null) {
        return false;
      }

      await _db!.delete(key);
      lastOperationTime.value = DateTime.now();
      _logger.fine('Deleted document: $key');
      return true;
    } catch (e, stackTrace) {
      _logger.severe('Failed to delete document', e, stackTrace);
      rethrow;
    }
  }

  // Query Operations

  /// Find all documents in a collection
  Future<List<Map<String, dynamic>>> findAll(
    String collection, {
    int? limit,
  }) async {
    _ensureInitialized();

    try {
      final pattern = '$collection:*';
      final keys = await _db!.getAll(pattern);

      var documents = <Map<String, dynamic>>[];
      for (final key in keys) {
        final data = await _db!.get(key);
        if (data != null && data is Map<String, dynamic>) {
          documents.add(Map<String, dynamic>.from(data));
        }
      }

      if (limit != null && limit > 0) {
        documents = documents.take(limit).toList();
      }

      return documents;
    } catch (e, stackTrace) {
      _logger.severe('Failed to find documents', e, stackTrace);
      rethrow;
    }
  }

  /// Find documents matching a filter
  Future<List<Map<String, dynamic>>> findWhere(
    String collection,
    Map<String, dynamic> where, {
    int? limit,
  }) async {
    _ensureInitialized();

    try {
      // Get all documents in collection
      final allDocs = await findAll(collection);

      // Filter in memory
      var filtered = allDocs.where((doc) {
        for (final entry in where.entries) {
          if (doc[entry.key] != entry.value) {
            return false;
          }
        }
        return true;
      }).toList();

      if (limit != null && limit > 0) {
        filtered = filtered.take(limit).toList();
      }

      return filtered;
    } catch (e, stackTrace) {
      _logger.severe('Failed to find documents with filter', e, stackTrace);
      rethrow;
    }
  }

  /// Count documents in a collection
  Future<int> count(String collection) async {
    final documents = await findAll(collection);
    return documents.length;
  }

  /// Watch a collection for changes (reactive)
  Computed<List<Map<String, dynamic>>> watchCollection(String collection) {
    _ensureInitialized();

    final pattern = '$collection:*';
    final stream = _db!.watch(pattern);

    // Convert stream to signal
    final streamSignal = StreamSignal<List<String>>(
      () => stream,
      initialValue: const [],
    );

    // Transform to documents
    return computed(() async {
      final keys = streamSignal.value;
      final documents = <Map<String, dynamic>>[];

      for (final key in keys) {
        final data = await _db!.get(key);
        if (data != null && data is Map<String, dynamic>) {
          documents.add(Map<String, dynamic>.from(data));
        }
      }

      return documents;
    }() as List<Map<String, dynamic>>);
  }

  /// Watch documents with a filter (reactive)
  Computed<List<Map<String, dynamic>>> watchWhere(
    String collection,
    Map<String, dynamic> where,
  ) {
    _ensureInitialized();

    final collectionSignal = watchCollection(collection);

    return computed(() {
      final allDocs = collectionSignal.value;
      return allDocs.where((doc) {
        for (final entry in where.entries) {
          if (doc[entry.key] != entry.value) {
            return false;
          }
        }
        return true;
      }).toList();
    });
  }

  /// Get database statistics
  Future<DatabaseStats> getStats() async {
    _ensureInitialized();

    try {
      final info = await _db!.getDatabaseInfo();

      // Count documents by scanning common collections
      final collections = ['demo', 'tasks', 'users', 'settings'];
      int totalDocuments = 0;
      int totalCollections = 0;

      for (final collection in collections) {
        try {
          final count = await this.count(collection);
          if (count > 0) {
            totalDocuments += count;
            totalCollections++;
          }
        } catch (_) {
          // Collection might not exist
        }
      }

      return DatabaseStats(
        totalDocuments: totalDocuments,
        totalCollections: totalCollections,
        connectionStatus: connectionStatus.value,
        databasePath: _dbPath,
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to get database stats', e, stackTrace);
      rethrow;
    }
  }

  // Private methods

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond;
    final bytes = utf8.encode('$timestamp$random');
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  void _ensureInitialized() {
    if (!isInitialized) {
      throw StateError('DatabaseService not initialized. Call initialize() first.');
    }
  }
}

/// Database connection status
enum DatabaseConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Database statistics
class DatabaseStats {
  final int totalDocuments;
  final int totalCollections;
  final DatabaseConnectionStatus connectionStatus;
  final String? databasePath;

  DatabaseStats({
    required this.totalDocuments,
    required this.totalCollections,
    required this.connectionStatus,
    this.databasePath,
  });

  @override
  String toString() {
    return 'DatabaseStats(docs: $totalDocuments, collections: $totalCollections, '
        'status: ${connectionStatus.name}, path: $databasePath)';
  }
}
```

### 4.2 AuthenticationService Updates

#### **Step 1: Remove InstantDB Magic Links**

```dart
// packages/flutter_app_shell/lib/src/services/authentication_service.dart

// REMOVE these methods:
// - sendMagicLink()
// - verifyMagicCode()
// - All InstantDB-specific error handling

// KEEP these methods:
// - signIn() (local authentication)
// - signUp() (local user creation)
// - signOut()
// - All biometric methods
// - Token management methods
```

#### **Step 2: Remove InstantDB Import**

```dart
// Remove:
import 'package:instantdb_flutter/instantdb_flutter.dart';

// Keep:
import 'package:local_auth/local_auth.dart';
import 'package:crypto/crypto.dart';
import 'preferences_service.dart';
```

#### **Step 3: Simplify Initialization**

```dart
Future<void> initialize() async {
  if (_isInitialized) return;

  try {
    _logger.info('Initializing authentication service...');

    _prefs = PreferencesService.instance;
    _localAuth = LocalAuthentication();

    // Check biometric availability
    await _checkBiometricAvailability();

    // Restore authentication state (local only)
    await _restoreAuthState();

    _isInitialized = true;
    _logger.info('Authentication service initialized (local-only mode)');
  } catch (e, stackTrace) {
    _logger.severe('Failed to initialize authentication service', e, stackTrace);
    rethrow;
  }
}
```

### 4.3 Configuration Updates

#### **Step 1: Update .env.example**

```bash
# .env.example

# ==============================================================================
# ReaxDB Configuration (Local Database)
# ==============================================================================

# Database name (default: app_shell)
REAXDB_DATABASE_NAME=app_shell

# Enable encryption (default: false)
# When enabled, data is encrypted at rest
REAXDB_ENCRYPTION_ENABLED=false

# Encryption key (required if encryption enabled)
# Keep this secret and never commit to version control
# REAXDB_ENCRYPTION_KEY=your-secure-key-here

# ==============================================================================
# Development & Debugging Options
# ==============================================================================

# Enable debug logging for App Shell services
DEBUG_LOGGING=false

# Log level: error, warning, info, debug
LOG_LEVEL=info

# ==============================================================================
# Removed: InstantDB Configuration
# ==============================================================================
# The following InstantDB features have been removed:
# - INSTANTDB_APP_ID (cloud database)
# - INSTANTDB_ENABLE_SYNC (real-time sync)
# - INSTANTDB_VERBOSE_LOGGING
#
# All data is now stored locally using ReaxDB.
# See REAXDB_MIGRATION_PLAN.md for migration details.
```

#### **Step 2: Update Service Locator**

```dart
// packages/flutter_app_shell/lib/src/services/service_locator.dart

Future<void> _setupDatabaseService(AppConfig config) async {
  final databaseService = DatabaseService.instance;

  // Get config from environment
  final dbName = dotenv.env['REAXDB_DATABASE_NAME'] ?? 'app_shell';
  final encrypted = dotenv.env['REAXDB_ENCRYPTION_ENABLED'] == 'true';

  await databaseService.initialize(
    dbName: dbName,
    encrypted: encrypted,
  );

  getIt.registerSingleton<DatabaseService>(databaseService);
  _logger.info('DatabaseService registered (ReaxDB)');
}
```

### 4.4 Example App Updates

#### **Files to Update:**

1. **Remove:**
   - `example/lib/features/instantdb_test/instantdb_test_screen.dart`
   - `packages/flutter_app_shell/lib/src/screens/datalog_investigation_screen.dart`

2. **Update:**
   - `example/lib/features/cloud_sync/cloud_sync_demo_screen.dart`
     - Rename to `local_database_demo_screen.dart`
     - Remove sync status UI
     - Show local-only database operations

3. **Update Routes:**
   ```dart
   // Remove:
   // - /instantdb-test
   // - /datalog-investigation

   // Update:
   AppRoute(
     title: 'Local Database',  // Was: 'Cloud Sync'
     path: '/local-database',
     icon: Icons.storage,
     builder: (context, state) => const LocalDatabaseDemoScreen(),
   ),
   ```

---

## 5. Testing & Validation

### 5.1 Unit Tests

#### **Update Database Service Tests**

```dart
// packages/flutter_app_shell/test/database_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock path provider for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/tmp/test_db';
  }
}

void main() {
  setUpAll(() {
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  group('DatabaseService - ReaxDB', () {
    late DatabaseService databaseService;

    setUp(() async {
      databaseService = DatabaseService.instance;
      await databaseService.initialize(dbName: 'test_db');
    });

    tearDown(() async {
      await databaseService.close();
    });

    test('should initialize successfully', () {
      expect(databaseService.isInitialized, isTrue);
      expect(
        databaseService.connectionStatus.value,
        DatabaseConnectionStatus.connected,
      );
    });

    test('should create document', () async {
      final id = await databaseService.create('users', {
        'name': 'John Doe',
        'email': 'john@example.com',
      });

      expect(id, isNotEmpty);

      final doc = await databaseService.read('users', id);
      expect(doc?['name'], 'John Doe');
      expect(doc?['email'], 'john@example.com');
      expect(doc?['_type'], 'users');
    });

    test('should update document', () async {
      final id = await databaseService.create('users', {'name': 'Jane'});

      final updated = await databaseService.update('users', id, {
        'name': 'Jane Smith',
      });

      expect(updated, isTrue);

      final doc = await databaseService.read('users', id);
      expect(doc?['name'], 'Jane Smith');
      expect(doc?['_version'], 2);
    });

    test('should delete document', () async {
      final id = await databaseService.create('users', {'name': 'Test'});

      final deleted = await databaseService.delete('users', id);
      expect(deleted, isTrue);

      final doc = await databaseService.read('users', id);
      expect(doc, isNull);
    });

    test('should find all documents', () async {
      await databaseService.create('users', {'name': 'User 1'});
      await databaseService.create('users', {'name': 'User 2'});
      await databaseService.create('users', {'name': 'User 3'});

      final docs = await databaseService.findAll('users');
      expect(docs.length, 3);
    });

    test('should find documents with filter', () async {
      await databaseService.create('users', {'name': 'Active', 'status': 'active'});
      await databaseService.create('users', {'name': 'Inactive', 'status': 'inactive'});
      await databaseService.create('users', {'name': 'Active 2', 'status': 'active'});

      final docs = await databaseService.findWhere('users', {'status': 'active'});
      expect(docs.length, 2);
      expect(docs.every((d) => d['status'] == 'active'), isTrue);
    });

    test('should count documents', () async {
      await databaseService.create('users', {'name': 'User 1'});
      await databaseService.create('users', {'name': 'User 2'});

      final count = await databaseService.count('users');
      expect(count, 2);
    });

    test('should get database stats', () async {
      await databaseService.create('users', {'name': 'Test'});

      final stats = await databaseService.getStats();
      expect(stats.totalDocuments, greaterThan(0));
      expect(stats.connectionStatus, DatabaseConnectionStatus.connected);
      expect(stats.databasePath, isNotNull);
    });
  });
}
```

### 5.2 Integration Tests

**Test Scenarios:**
- [ ] Create, read, update, delete operations
- [ ] Query operations (findAll, findWhere)
- [ ] Reactive queries (watchCollection, watchWhere)
- [ ] Service initialization flow
- [ ] Error handling and edge cases
- [ ] Database statistics and monitoring

### 5.3 Performance Testing

**Benchmarks to Run:**
```dart
void main() {
  group('ReaxDB Performance', () {
    test('should handle 1000 writes', () async {
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 1000; i++) {
        await db.create('perf_test', {'index': i, 'data': 'test'});
      }

      stopwatch.stop();
      print('1000 writes: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(5000)); // < 5s
    });

    test('should handle 10000 reads', () async {
      // ... similar performance test
    });
  });
}
```

**Expected Performance:**
- Writes: ~21,000/sec (ReaxDB claim)
- Reads (cached): ~333,000/sec (ReaxDB claim)
- Collection queries: <100ms for <10k documents

---

## 6. Rollback Plan

### 6.1 Version Control Strategy

```bash
# Create feature branch
git checkout -b feature/reaxdb-migration

# Work on migration
git add .
git commit -m "WIP: ReaxDB migration"

# If rollback needed
git checkout main
git branch -D feature/reaxdb-migration
```

### 6.2 Dependency Rollback

**If Migration Fails:**
1. Revert pubspec.yaml changes
2. Run `flutter pub get`
3. Restore InstantDB service files from git
4. Run tests to verify

**Rollback Script:**
```bash
#!/bin/bash
# rollback_reaxdb.sh

echo "Rolling back ReaxDB migration..."

# Restore pubspec.yaml
git checkout main -- packages/flutter_app_shell/pubspec.yaml

# Restore service files
git checkout main -- packages/flutter_app_shell/lib/src/services/

# Install dependencies
cd packages/flutter_app_shell && flutter pub get

# Run tests
flutter test

echo "Rollback complete. Verify with: flutter run"
```

### 6.3 Data Migration Rollback

**Important:** ReaxDB is local-only, so there's no cloud data to roll back.

**User Data Considerations:**
- Users may lose data created during ReaxDB testing
- Document format changes (key patterns) are incompatible
- Recommend clean install or data export/import

---

## 7. Timeline & Resources

### 7.1 Estimated Timeline

| Phase | Duration | Effort | Risk |
|-------|----------|--------|------|
| Phase 1: Preparation | 2-3 days | Medium | Low |
| Phase 2: Core Migration | 3-5 days | High | Medium |
| Phase 3: Auth Updates | 1-2 days | Low | Low |
| Phase 4: Testing | 3-4 days | Medium | Medium |
| Phase 5: Cleanup | 1-2 days | Low | Low |
| **Total** | **10-16 days** | **2-3 weeks** | **Medium** |

### 7.2 Resource Requirements

**Developer Skills Needed:**
- ✅ Flutter/Dart expertise
- ✅ Database architecture knowledge
- ✅ NoSQL database patterns
- ✅ Reactive programming (Signals)
- ✅ Testing best practices

**Tools Required:**
- Flutter SDK 3.6.0+
- Dart 3.7+
- Git
- IDE with Dart/Flutter support
- Device/emulator for testing

### 7.3 Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Breaking API changes | Medium | High | Keep compatible API surface |
| Performance issues | Low | Medium | Benchmark early, optimize |
| Data loss during migration | Low | High | Clear migration guide, warnings |
| Test coverage gaps | Medium | Medium | Comprehensive test suite |
| Documentation drift | Medium | Low | Update docs in parallel |

### 7.4 Success Criteria

✅ **Must Have:**
- [ ] All tests passing (unit, integration)
- [ ] Example app functional
- [ ] Documentation updated
- [ ] Migration guide written
- [ ] Performance benchmarks met

✅ **Should Have:**
- [ ] Backward compatibility layer (deprecated APIs)
- [ ] Performance improvements over InstantDB
- [ ] Simplified codebase

✅ **Nice to Have:**
- [ ] Enhanced error messages
- [ ] Additional query features
- [ ] Better debugging tools

---

## 8. Migration Checklist

### 8.1 Pre-Migration

- [ ] Review current InstantDB usage
- [ ] Identify all dependencies
- [ ] Create feature branch
- [ ] Backup any test data
- [ ] Document current behavior

### 8.2 Implementation

- [ ] Add ReaxDB dependency
- [ ] Implement new DatabaseService
- [ ] Update AuthenticationService
- [ ] Remove InstantDB-specific code
- [ ] Update configuration files
- [ ] Migrate example app screens

### 8.3 Testing

- [ ] Unit tests for DatabaseService
- [ ] Unit tests for AuthenticationService
- [ ] Integration tests
- [ ] Performance benchmarks
- [ ] Manual testing on all platforms

### 8.4 Documentation

- [ ] Update CLAUDE.md
- [ ] Update README.md
- [ ] Update architecture.md
- [ ] Update services/database.md
- [ ] Create migration guide
- [ ] Update CHANGELOG.md

### 8.5 Release

- [ ] Version bump to 2.0.0
- [ ] Tag release in git
- [ ] Publish package (if applicable)
- [ ] Announce breaking changes
- [ ] Provide migration support

---

## 9. Additional Considerations

### 9.1 Advanced ReaxDB Features

**Encryption:**
```dart
// Enable encryption for sensitive data
await DatabaseService.instance.initialize(
  dbName: 'secure_app_shell',
  encrypted: true,
);
```

**Transactions:**
```dart
// For complex multi-document operations
await db.advanced.transaction(() async {
  await db.put('user:1', userData);
  await db.put('profile:1', profileData);
  await db.put('settings:1', settingsData);
});
```

**Indexing:**
```dart
// Create indexes for faster queries
await db.advanced.createIndex('users_by_email', 'email');
```

### 9.2 Migration Best Practices

1. **Incremental Migration**
   - Migrate one service at a time
   - Test thoroughly before moving to next

2. **Maintain Logs**
   - Keep detailed migration logs
   - Document all issues and resolutions

3. **Communicate Changes**
   - Update all stakeholders
   - Provide clear migration path for consumers

4. **Monitor Performance**
   - Compare before/after metrics
   - Optimize as needed

---

## 10. Appendix

### 10.1 Key Differences: InstantDB vs ReaxDB

| Feature | InstantDB | ReaxDB |
|---------|-----------|--------|
| **Architecture** | Client-server + local | Local-only |
| **Sync** | Real-time cloud sync | None (local-only) |
| **Authentication** | Built-in magic links | None (bring your own) |
| **Query Language** | Datalog-inspired | Key-value + patterns |
| **Reactivity** | Built-in signals | Stream-based |
| **Schema** | Optional/flexible | Schema-less |
| **Performance** | Network-dependent | Local-only (fast) |
| **Platform** | Flutter only | Pure Dart (all platforms) |
| **Code Gen** | None ✅ | None ✅ |
| **Encryption** | Cloud-managed | Local AES-256 |

### 10.2 Useful Commands

```bash
# Install dependencies
flutter pub get

# Run tests
flutter test

# Run example app
cd example && flutter run

# Performance profiling
flutter run --profile

# Generate documentation
dart doc .

# Clean build
flutter clean && flutter pub get

# Check for issues
flutter analyze
dart format --set-exit-if-changed .
```

### 10.3 References

**ReaxDB Documentation:**
- Pub.dev: https://pub.dev/packages/reaxdb_dart
- GitHub: https://github.com/dvillegastech/Reax-BD

**Related Docs:**
- `CLAUDE.md` - Project overview
- `docs/architecture.md` - Architecture guide
- `docs/services/database.md` - Database service docs
- `CHANGELOG.md` - Version history

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-05 | Claude Code | Initial migration plan |

---

**End of Migration Plan**

For questions or issues during migration, refer to the project's CLAUDE.md or open an issue in the repository.
