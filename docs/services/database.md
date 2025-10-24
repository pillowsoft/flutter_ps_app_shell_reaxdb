# Database Service

The Database Service provides a high-performance NoSQL document database with local storage and optional encryption. Built on **ReaxDB** for blazing-fast local-only storage (21,000+ writes/sec, 333,000+ cached reads/sec).

## 🚀 Quick Start

### Basic Usage
```dart
final db = getIt<DatabaseService>();

// Create a document
final todoId = await db.create('todos', {
  'title': 'Buy groceries',
  'completed': false,
  'dueDate': DateTime.now().add(Duration(days: 1)).toIso8601String(),
});

// Read a document
final todo = await db.read('todos', todoId);

// Query all documents in collection
final todos = await db.findAll('todos');

// Update a document
await db.update('todos', todoId, {
  'completed': true,
});

// Delete a document
await db.delete('todos', todoId);
```

### Reactive Queries with Signals
```dart
// Watch for changes using Signals
final todosSignal = db.watchCollection('todos');

// Use in UI with Watch
Watch((context) {
  final todos = todosSignal.value;

  if (todos.isEmpty) {
    return Text('No todos yet');
  }

  return ListView.builder(
    itemCount: todos.length,
    itemBuilder: (context, index) {
      final todo = todos[index];
      return ListTile(
        title: Text(todo['title']),
        trailing: Checkbox(
          value: todo['completed'] ?? false,
          onChanged: (value) => _toggleTodo(todo['id'], value),
        ),
      );
    },
  );
});
```

## 📊 Document Model

### Document Structure
All documents stored in ReaxDB include automatic metadata:

```dart
{
  'id': 'abc123',              // Document ID (auto-generated or provided)
  '_type': 'todos',            // Collection name
  '_createdAt': '2025-10-05T...', // ISO8601 timestamp
  '_updatedAt': '2025-10-05T...', // ISO8601 timestamp
  '_version': 1,               // Incremented on each update

  // Your custom fields
  'title': 'Buy groceries',
  'completed': false,
  // ... any other fields
}
```

### Creating Documents
```dart
// Simple document (ID auto-generated)
final id = await db.create('notes', {
  'title': 'My Note',
  'content': 'Note content here',
});

// Document with custom ID
final id = await db.create('users', {
  'id': 'user_123',
  'name': 'John Doe',
  'email': 'john@example.com',
});

// Document with nested data
final id = await db.create('articles', {
  'title': 'Flutter Best Practices',
  'content': 'Article content...',
  'metadata': {
    'tags': ['flutter', 'development'],
    'author': 'Jane Smith',
  },
});
```

## 🔍 Querying Data

### Basic Queries
```dart
// Find all documents in a collection
final allTodos = await db.findAll('todos');

// Find with limit
final recentTodos = await db.findAll('todos', limit: 10);

// Find by ID
final todo = await db.read('todos', todoId);

// Count documents
final count = await db.count('todos');
```

### Filtered Queries
```dart
// Find documents matching criteria
final activeTodos = await db.findWhere('todos', {
  'completed': false,
});

// Find with multiple criteria
final urgentActiveTodos = await db.findWhere('todos', {
  'completed': false,
  'priority': 'high',
});

// Find with limit
final firstFiveActive = await db.findWhere(
  'todos',
  {'completed': false},
  limit: 5,
);
```

### Reactive Queries
```dart
// Watch entire collection
final todosSignal = db.watchCollection('todos');

// Watch with filter
final activeTodosSignal = db.watchWhere('todos', {
  'completed': false,
});

// Use computed signals for derived data
final completedCount = computed(() {
  final todos = todosSignal.value;
  return todos.where((t) => t['completed'] == true).length;
});
```

## 📝 CRUD Operations

### Create
```dart
// Basic creation
final id = await db.create('todos', {
  'title': 'New Task',
  'completed': false,
});

// With custom ID
final id = await db.create('settings', {
  'id': 'user_preferences',
  'theme': 'dark',
  'notifications': true,
});
```

### Read
```dart
// Single document
final doc = await db.read('todos', todoId);
if (doc != null) {
  print('Title: ${doc['title']}');
  print('Type: ${doc['_type']}');
  print('Created: ${doc['_createdAt']}');
  print('Version: ${doc['_version']}');
}

// Returns null if not found
final missing = await db.read('todos', 'nonexistent_id');
// missing == null
```

### Update
```dart
// Partial update (merges with existing data)
final success = await db.update('todos', todoId, {
  'completed': true,
  'completedAt': DateTime.now().toIso8601String(),
});

// Returns true if successful, false if document not found
if (success) {
  print('Document updated successfully');
} else {
  print('Document not found');
}

// Metadata automatically updated:
// - _updatedAt set to current timestamp
// - _version incremented
```

### Delete
```dart
// Delete document
final success = await db.delete('todos', todoId);

// Returns true if deleted, false if not found
if (success) {
  print('Document deleted');
}
```

## 🔒 Encryption Support

### Enabling Encryption
Configure encryption via environment variables:

```bash
# .env file
REAXDB_DATABASE_NAME=app_shell
REAXDB_ENCRYPTION_ENABLED=true
REAXDB_ENCRYPTION_KEY=your-secure-32-character-key-here
```

Or programmatically:
```dart
await db.initialize(
  dbName: 'secure_db',
  encrypted: true,
  encryptionKey: 'your-secure-32-character-key',
);
```

### Encryption Features
- **AES-256 encryption** - Industry-standard encryption
- **Transparent operation** - Same API whether encrypted or not
- **At-rest protection** - All data encrypted on disk
- **Performance** - Minimal overhead with caching

## 🚀 Performance & Optimization

### ReaxDB Performance Characteristics
- **21,000+ writes/second** - Blazing-fast write operations
- **333,000+ cached reads/second** - Extremely fast read operations
- **Pure Dart implementation** - Zero native dependencies
- **Cross-platform** - Same performance on all platforms
- **Memory efficient** - Built-in caching with LRU eviction

### Database Statistics
```dart
// Get detailed statistics
final stats = await db.getStats();
print('Total documents: ${stats.totalDocuments}');
print('Total collections: ${stats.totalCollections}');
print('Connection status: ${stats.connectionStatus}');
print('Database path: ${stats.databasePath}');
```

### Best Practices
```dart
// ✅ Good: Batch operations when possible
final ids = await Future.wait([
  db.create('todos', {'title': 'Task 1'}),
  db.create('todos', {'title': 'Task 2'}),
  db.create('todos', {'title': 'Task 3'}),
]);

// ✅ Good: Use specific queries
final active = await db.findWhere('todos', {'completed': false});

// ❌ Avoid: Loading all documents then filtering in memory
final all = await db.findAll('todos'); // Loads everything
final active = all.where((t) => t['completed'] == false); // Filters in app
```

## 🧪 Testing

### Test Database
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_shell/src/services/database_service.dart';

void main() {
  late DatabaseService db;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = DatabaseService.instance;
    await db.initialize(dbName: 'test_db');
  });

  test('should create and retrieve document', () async {
    // Create
    final id = await db.create('todos', {
      'title': 'Test Todo',
      'completed': false,
    });

    // Read
    final doc = await db.read('todos', id);

    // Assert
    expect(doc, isNotNull);
    expect(doc!['title'], equals('Test Todo'));
    expect(doc['completed'], equals(false));
    expect(doc['_version'], equals(1));
  });

  test('should update document', () async {
    // Create
    final id = await db.create('todos', {'title': 'Original'});

    // Update
    final success = await db.update('todos', id, {
      'title': 'Updated',
      'extra': 'field',
    });

    // Assert
    expect(success, isTrue);

    final doc = await db.read('todos', id);
    expect(doc!['title'], equals('Updated'));
    expect(doc['extra'], equals('field'));
    expect(doc['_version'], equals(2)); // Incremented
  });

  tearDown(() async {
    await db.close();
  });
}
```

## 🔧 Configuration

### Environment Variables
Configure ReaxDB in your `.env` file:

```bash
# Database name (default: 'app_shell')
REAXDB_DATABASE_NAME=my_app_db

# Enable encryption (default: false)
REAXDB_ENCRYPTION_ENABLED=false

# Encryption key (required if encryption enabled)
# Must be a secure random string
# REAXDB_ENCRYPTION_KEY=your-32-character-key-here

# WAL Management (Write-Ahead Log)
# Auto-cleanup stale WAL files (default: true in debug mode, false in release)
REAXDB_WAL_AUTO_CLEANUP=true

# Maximum WAL size threshold in MB (default: 10)
# Warns if total WAL size exceeds this value
REAXDB_WAL_MAX_SIZE_MB=10

# Checkpoint WAL on database close (default: true)
# Merges WAL changes back into main database on clean shutdown
REAXDB_CHECKPOINT_ON_CLOSE=true
```

### Programmatic Initialization
```dart
// Automatic from environment (recommended)
// Called automatically by service_locator.dart
final db = DatabaseService.instance;

// Manual initialization (advanced)
await db.initialize(
  dbName: 'custom_db',
  encrypted: true,
  encryptionKey: 'secure-key',
);
```

### Connection Status
```dart
// Monitor database connection status with Signals
Watch((context) {
  final status = db.connectionStatus.value;

  return switch (status) {
    DatabaseConnectionStatus.connected =>
      Icon(Icons.check_circle, color: Colors.green),
    DatabaseConnectionStatus.connecting =>
      CircularProgressIndicator(),
    DatabaseConnectionStatus.error =>
      Icon(Icons.error, color: Colors.red),
    DatabaseConnectionStatus.disconnected =>
      Icon(Icons.offline_bolt),
  };
});
```

## 📊 Monitoring & Debugging

### Service Inspector Integration
The Database Service integrates with the Service Inspector for real-time monitoring:

- **Document counts** by collection
- **Connection status** monitoring
- **Database path** and configuration
- **Interactive testing** - create, update, delete documents
- **Real-time statistics**

### Local Database Demo Screen
Navigate to `/local-database` in the example app to:
- Test CRUD operations
- View database statistics
- Monitor connection status
- Manage document collections
- Clear all documents

### Real-time Signals
The DatabaseService uses Signals for reactive status updates:
```dart
// Connection status
final connectionStatus = signal<DatabaseConnectionStatus>(
  DatabaseConnectionStatus.disconnected
);

// Last operation timestamp
final lastOperationTime = signal<DateTime?>(null);
```

## 📂 WAL File Management

### What are WAL Files?

ReaxDB (like SQLite) uses Write-Ahead Logging (WAL) for database transactions. WAL files temporarily store changes before they're merged into the main database file. This improves performance and crash recovery.

**WAL Files Include:**
- `database-wal` - Write-ahead log file (transaction log)
- `database-shm` - Shared memory file (coordination)

### WAL Accumulation During Development

**Problem**: During active development with hot restarts and Ctrl+C exits, WAL files can accumulate because:
- Hot restart doesn't cleanly close the database
- Ctrl+C force-quits the app without cleanup
- Multiple WAL files pile up (31 files / 1.9MB observed)
- Next app start processes ALL accumulated WAL files (10+ second delays)

**Solution**: App Shell now includes automatic WAL cleanup:
- ✅ Cleans up stale WAL files before database initialization
- ✅ Enabled by default in debug mode
- ✅ Prevents accumulation during development
- ✅ Configurable via environment variables

### Automatic WAL Cleanup

WAL cleanup runs automatically before database initialization when enabled:

```dart
// Automatically configured from .env file
await DatabaseService.instance.initialize();

// WAL cleanup happens transparently:
// 1. Scans for WAL files in database directory
// 2. Logs file count and total size
// 3. Deletes stale WAL files (safe when DB is closed)
// 4. Tracks cleanup metrics for monitoring
```

**Configuration:**
```bash
# .env file
REAXDB_WAL_AUTO_CLEANUP=true          # Enable auto-cleanup
REAXDB_WAL_MAX_SIZE_MB=10             # Warn if WAL > 10MB
REAXDB_CHECKPOINT_ON_CLOSE=true       # Checkpoint on close
```

### Manual WAL Cleanup

You can manually trigger WAL cleanup from your app:

```dart
final db = getIt<DatabaseService>();

// Manually cleanup WAL files
await db.cleanupWalFiles();

// Check WAL statistics
final stats = await db.getStats();
print('WAL files: ${stats.walFileCount}');
print('WAL size: ${stats.walSizeMB?.toStringAsFixed(2)} MB');
print('Last cleanup: ${stats.lastCleanupTime}');
```

### WAL Lifecycle Best Practices

**✅ Development (Debug Mode):**
```bash
# Aggressive cleanup to prevent accumulation
REAXDB_WAL_AUTO_CLEANUP=true
REAXDB_WAL_MAX_SIZE_MB=10
REAXDB_CHECKPOINT_ON_CLOSE=true
```

**✅ Production (Release Mode):**
```bash
# Standard WAL behavior (let ReaxDB handle it)
REAXDB_WAL_AUTO_CLEANUP=false        # Disable aggressive cleanup
REAXDB_CHECKPOINT_ON_CLOSE=true      # Still checkpoint on clean exit
```

**✅ App Lifecycle:**
- App Shell automatically closes database on app termination
- `AppLifecycleManager` detects app pause/detach/terminate events
- Database cleanup happens automatically via lifecycle hooks
- No manual intervention required

### Monitoring WAL Files

**Check WAL Statistics:**
```dart
final stats = await db.getStats();

// WAL metrics included in stats
if (stats.walFileCount != null) {
  print('WAL files: ${stats.walFileCount}');
  print('WAL size: ${stats.walSizeMB?.toStringAsFixed(2)} MB');
  print('Last cleanup: ${stats.lastCleanupTime}');
} else {
  print('No WAL cleanup has run yet');
}
```

**View in Service Inspector:**
- Navigate to `/inspector` in example app
- Database section shows WAL metrics
- Manual cleanup button available
- Real-time statistics

**Initialization Timing:**
The database service logs initialization timing to help identify WAL processing:

```
ReaxDB database initialized (unencrypted) at: /path/to/db
Timing: total=127ms, db_open=89ms

// If slow (> 1 second):
WARNING: Database initialization took 10234ms. This may indicate
accumulated WAL files being processed. Consider enabling
REAXDB_WAL_AUTO_CLEANUP in your .env file.
```

### Troubleshooting WAL Issues

**Symptom**: Slow database initialization (>1 second)
**Cause**: Accumulated WAL files from hot restarts
**Solution**:
```bash
# Enable auto-cleanup in .env
REAXDB_WAL_AUTO_CLEANUP=true

# Or manually cleanup once:
await getIt<DatabaseService>().cleanupWalFiles();
```

**Symptom**: WAL files keep growing
**Cause**: Database not closing properly
**Check**:
- Ensure `AppLifecycleManager` is registered in service locator
- Check if app lifecycle events are firing
- Verify `REAXDB_CHECKPOINT_ON_CLOSE=true`

**Symptom**: WAL files deleted but re-appear
**Cause**: Normal operation - WAL files are created during transactions
**Solution**: This is expected. Auto-cleanup only triggers on next app start.

For more troubleshooting help, see: [Database Troubleshooting Guide](../troubleshooting/database.md)

## 🎯 Key Advantages of ReaxDB

### Local-Only Database
ReaxDB provides **high-performance local storage**:
- ✅ 21,000+ writes/second
- ✅ 333,000+ cached reads/second
- ✅ Zero native dependencies (pure Dart)
- ✅ Optional AES-256 encryption
- ✅ Works on all platforms (iOS, Android, Web, Desktop)
- ✅ No internet connection required
- ✅ Simple document/collection API
- ✅ Zero code generation

### Document Storage Pattern
```dart
// ReaxDB approach (schemaless, local-only)
final doc = await db.create('todos', {
  'title': 'My Todo',
  'completed': false,
  'tags': ['work', 'urgent'],
  'metadata': {
    'priority': 'high',
    'assignee': 'user123'
  }
});

// Query with reactive updates
final todosSignal = db.watchCollection('todos');
Watch((context) {
  final todos = todosSignal.value;
  // UI automatically rebuilds when data changes locally
});
```

### When to Use ReaxDB
Perfect for:
- ✅ Local-only apps (no cloud requirement)
- ✅ High-performance requirements
- ✅ Offline-first applications
- ✅ Privacy-focused apps (data never leaves device)
- ✅ Desktop applications
- ✅ Apps with sensitive data (optional encryption)

Not suitable for:
- ❌ Real-time multi-device sync
- ❌ Cloud-based collaboration
- ❌ Automatic backups to cloud

## 🔗 Related Documentation

- **[Services Overview](README.md)** - Overview of all services
- **[Architecture](../architecture.md)** - How Database Service fits in the overall architecture
- **[ReaxDB Migration Plan](../../REAXDB_MIGRATION_PLAN.md)** - InstantDB to ReaxDB migration

The Database Service provides a powerful, flexible foundation for your app's local data needs. High-performance storage with optional encryption, all without any cloud dependencies! 🗄️
