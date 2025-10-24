# Database Troubleshooting Guide

This guide helps you diagnose and fix common database issues when using ReaxDB in the Flutter App Shell.

## Table of Contents

- [WAL File Issues](#wal-file-issues)
- [Performance Issues](#performance-issues)
- [Initialization Problems](#initialization-problems)
- [Data Integrity Issues](#data-integrity-issues)
- [Platform-Specific Issues](#platform-specific-issues)

---

## WAL File Issues

### Symptom: Slow Database Initialization (>1 second)

**Root Cause**: Accumulated WAL (Write-Ahead Log) files from development hot restarts and force quits.

**Diagnosis:**
```dart
// Check initialization timing in logs:
// ReaxDB database initialized at: /path/to/db
// Timing: total=10234ms, db_open=9876ms

// If total > 1000ms, you likely have WAL accumulation
```

**Solution 1: Enable Auto-Cleanup** (Recommended)
```bash
# Add to your .env file:
REAXDB_WAL_AUTO_CLEANUP=true
REAXDB_WAL_MAX_SIZE_MB=10
REAXDB_CHECKPOINT_ON_CLOSE=true
```

**Solution 2: Manual Cleanup**
```dart
// One-time manual cleanup:
final db = getIt<DatabaseService>();
await db.cleanupWalFiles();

// Check the results:
final stats = await db.getStats();
print('Cleaned up ${stats.walFileCount ?? 0} WAL files');
```

**Solution 3: Delete WAL Files Manually**
```bash
# Find database directory (check logs for path):
# /Users/username/Library/Application Support/com.example.app/app_shell

# Stop the app completely, then:
cd /path/to/database/directory
rm -f *.wal *.shm

# Restart the app
```

**Prevention:**
- Always use WAL auto-cleanup in development
- Ensure `AppLifecycleManager` is registered
- Avoid force-quitting the app (use proper app termination)

---

### Symptom: WAL Files Keep Growing

**Root Cause**: Database not closing properly on app termination.

**Diagnosis:**
```dart
// Check if AppLifecycleManager is working:
final lifecycleManager = getIt<AppLifecycleManager>();
print('Is initialized: ${lifecycleManager._isInitialized}');
print('Current state: ${lifecycleManager.currentState}');

// Check database status:
final db = getIt<DatabaseService>();
final stats = await db.getStats();
print('WAL files: ${stats.walFileCount}');
print('WAL size: ${stats.walSizeMB?.toStringAsFixed(2)} MB');
```

**Solution:**
1. **Verify AppLifecycleManager is Registered**
   ```dart
   // Check service_locator.dart:
   // Should include:
   final lifecycleManager = AppLifecycleManager.instance;
   lifecycleManager.initialize();
   getIt.registerSingleton<AppLifecycleManager>(lifecycleManager);
   ```

2. **Enable Checkpoint on Close**
   ```bash
   # In .env file:
   REAXDB_CHECKPOINT_ON_CLOSE=true
   ```

3. **Check Lifecycle Events**
   ```dart
   // Add logging to AppLifecycleManager to verify events fire:
   @override
   void didChangeAppLifecycleState(AppLifecycleState state) {
     print('Lifecycle state changed: $state');
     // ... rest of implementation
   }
   ```

---

### Symptom: WAL Files Deleted But Re-appear

**Root Cause**: Normal operation - WAL files are created during database transactions.

**Explanation**: WAL files are NOT a problem - they're part of normal SQLite/ReaxDB operation. They only become an issue when:
- They accumulate over many development cycles
- They're large (>10MB)
- Initialization becomes slow

**Normal Behavior:**
- WAL files appear during app use ✅
- They're cleaned up on next app start (if auto-cleanup enabled) ✅
- Small WAL files (<1MB) are perfectly normal ✅

**When to Act:**
- WAL files exceed 10MB ⚠️
- Initialization takes >1 second ⚠️
- You have 10+ WAL files ⚠️

---

## Performance Issues

### Symptom: Slow CRUD Operations

**Diagnosis:**
```dart
final stopwatch = Stopwatch()..start();

final id = await db.create('test', {'data': 'test'});
stopwatch.stop();
print('Create took: ${stopwatch.elapsedMilliseconds}ms');

// Normal: <10ms
// Slow: >100ms
```

**Possible Causes:**

**1. Large WAL Files**
- See [WAL File Issues](#wal-file-issues) above

**2. Too Many Documents in Collection**
```dart
final count = await db.count('collection_name');
print('Document count: $count');

// If count > 10,000:
// Consider:
// - Pagination (use limit parameter)
// - Multiple collections
// - Archiving old data
```

**3. Inefficient Queries**
```dart
// ❌ Bad: Load all docs then filter
final all = await db.findAll('todos');
final active = all.where((t) => t['completed'] == false).toList();

// ✅ Good: Filter in database
final active = await db.findWhere('todos', {'completed': false});
```

**4. Blocking UI Thread**
```dart
// ❌ Bad: Synchronous heavy operation
Widget build(BuildContext context) {
  final todos = db.findAll('todos'); // BLOCKS UI!
  return ListView(...);
}

// ✅ Good: Use FutureBuilder or reactive signals
Widget build(BuildContext context) {
  return Watch((context) {
    final todos = todosSignal.value;
    return ListView(...);
  });
}
```

---

### Symptom: Slow Query Performance

**Optimization Strategies:**

**1. Use Limits**
```dart
// Instead of loading everything:
final recentTodos = await db.findAll('todos', limit: 50);
```

**2. Optimize findWhere() Usage**
```dart
// Current findWhere() loads all docs then filters
// For large collections, consider:
final allDocs = await db.findAll('todos');
final filtered = allDocs.where((doc) {
  // Custom complex filter logic
}).toList();
```

**3. Batch Operations**
```dart
// ❌ Slow: Sequential operations
for (final item in items) {
  await db.create('todos', item); // 100 round trips!
}

// ✅ Fast: Batch with Future.wait
await Future.wait(
  items.map((item) => db.create('todos', item)),
);
```

---

## Initialization Problems

### Symptom: "DatabaseService not initialized" Error

**Error Message:**
```
StateError: DatabaseService not initialized. Call initialize() first.
```

**Diagnosis:**
```dart
final db = getIt<DatabaseService>();
print('Is initialized: ${db.isInitialized}');
print('Connection status: ${db.connectionStatus.value}');
```

**Solution:**
Ensure database is initialized in `service_locator.dart`:

```dart
// In setupLocator():
if (!getIt.isRegistered<DatabaseService>()) {
  final databaseService = DatabaseService.instance;
  await databaseService.initialize(
    dbName: dbName,
    encrypted: encrypted,
  );
  getIt.registerSingleton<DatabaseService>(databaseService);
}
```

---

### Symptom: Encryption Key Error

**Error Message:**
```
Failed to initialize database: Encryption key required when encrypted=true
```

**Solution:**
```bash
# In .env file:
REAXDB_ENCRYPTION_ENABLED=true
REAXDB_ENCRYPTION_KEY=your-secure-32-character-key-here

# Generate a secure key:
openssl rand -base64 32
```

**Important:**
- Never commit encryption keys to version control
- Use different keys for development/production
- Store production keys securely (e.g., AWS Secrets Manager, environment variables)

---

### Symptom: Database Path Not Found

**Error Context**: Unable to locate application documents directory.

**Platform-Specific Solutions:**

**iOS/macOS:**
```dart
// Ensure path_provider is configured:
import 'package:path_provider/path_provider.dart';

final directory = await getApplicationDocumentsDirectory();
print('DB path: ${directory.path}');

// Typical path: /Users/username/Library/Application Support/com.example.app
```

**Android:**
```dart
// Typical path: /data/user/0/com.example.app/files
// Ensure app has storage permissions if needed
```

**Web:**
```dart
// Web uses IndexedDB, not file system
// Path is virtual
```

---

## Data Integrity Issues

### Symptom: Data Loss After Hot Restart

**Root Cause**: Hot restart doesn't persist uncommitted transactions.

**Solution:**
Ensure data is committed before hot restart:
```dart
// Always await database operations:
await db.create('todos', {'title': 'Important'});
// ✅ Data is persisted

// vs
db.create('todos', {'title': 'Lost'}); // ❌ May not persist!
```

---

### Symptom: Corrupted Database

**Symptoms:**
- Read operations fail
- Database won't initialize
- Unexpected null values

**Recovery Steps:**

**1. Check Database Integrity**
```dart
try {
  final stats = await db.getStats();
  print('Database OK: ${stats.toString()}');
} catch (e) {
  print('Database corrupted: $e');
}
```

**2. Backup Current Database**
```bash
# Find database path (check logs)
cp /path/to/app_shell /path/to/app_shell.backup
cp /path/to/app_shell-wal /path/to/app_shell-wal.backup
```

**3. Reset Database**
```dart
// Delete and reinitialize:
await db.close();

// Manually delete files:
final dir = Directory('/path/to/database').parent;
dir.listSync().where((f) => f.path.contains('app_shell')).forEach((f) {
  f.deleteSync();
});

// Reinitialize:
await db.initialize();
```

---

## Platform-Specific Issues

### iOS

**Issue**: Database path changes after updates
**Solution**: Use `getApplicationDocumentsDirectory()` dynamically, never hardcode paths

### Android

**Issue**: Storage permissions required
**Solution**: Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

### Web

**Issue**: IndexedDB quota exceeded
**Solution**: Request persistent storage:
```dart
// Web-specific code
if (kIsWeb) {
  // Request persistent storage
  await html.window.navigator.storage?.persist();
}
```

### macOS/Windows/Linux

**Issue**: App Sandbox restrictions
**Solution**: Configure entitlements for file access

---

## Getting Help

If you're still experiencing issues:

1. **Check Logs**: Enable debug logging
   ```bash
   DEBUG_LOGGING=true
   LOG_LEVEL=debug
   ```

2. **Inspect Database**: Navigate to `/inspector` in example app

3. **Check Service Health**: View Service Inspector for real-time status

4. **Review Documentation**:
   - [Database Service Docs](../services/database.md)
   - [ReaxDB Pub.dev](https://pub.dev/packages/reaxdb_dart)

5. **Report Issue**: Create issue in repository with:
   - Logs (sanitize sensitive data)
   - Platform (iOS, Android, Web, Desktop)
   - Database statistics
   - Steps to reproduce

---

## Quick Reference

**Common Commands:**

```dart
// Check database health
final stats = await db.getStats();
print(stats.toString());

// Manual WAL cleanup
await db.cleanupWalFiles();

// Close database
await db.close();

// Reinitialize
await db.initialize();

// Get lifecycle status
final lifecycle = getIt<AppLifecycleManager>();
print('State: ${lifecycle.currentState}');
```

**Environment Variables:**
```bash
REAXDB_DATABASE_NAME=app_shell
REAXDB_ENCRYPTION_ENABLED=false
REAXDB_WAL_AUTO_CLEANUP=true
REAXDB_WAL_MAX_SIZE_MB=10
REAXDB_CHECKPOINT_ON_CLOSE=true
DEBUG_LOGGING=false
LOG_LEVEL=info
```

---

**Last Updated**: 2025-10-23
**Version**: v1.1.0
