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
