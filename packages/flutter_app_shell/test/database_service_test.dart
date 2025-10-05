import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app_shell/src/services/database_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// Mock PathProviderPlatform for testing
class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    // Use a temp directory for tests
    final tempDir = Directory.systemTemp.createTempSync('reaxdb_test_');
    return tempDir.path;
  }
}

void main() {
  setUpAll(() {
    // Set up mock path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  group('DatabaseService - ReaxDB', () {
    late DatabaseService db;
    late Directory testDir;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Create a unique test directory for each test
      testDir = Directory.systemTemp.createTempSync('reaxdb_test_');

      // Create a new instance for each test
      db = DatabaseService.instance;
    });

    tearDown(() async {
      if (db.isInitialized) {
        await db.close();
      }

      // Clean up test directory
      if (testDir.existsSync()) {
        try {
          testDir.deleteSync(recursive: true);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    });

    test('should initialize successfully', () async {
      await db.initialize(dbName: 'test_db');

      expect(db.isInitialized, isTrue);
      expect(db.connectionStatus.value, DatabaseConnectionStatus.connected);
    });

    test('should initialize with encryption when provided', () async {
      await db.initialize(
        dbName: 'test_encrypted_db',
        encrypted: true,
        encryptionKey: 'test-encryption-key-12345',
      );

      expect(db.isInitialized, isTrue);
      expect(db.connectionStatus.value, DatabaseConnectionStatus.connected);
    });

    test('should throw error when encryption enabled without key', () async {
      expect(
        () => db.initialize(
          dbName: 'test_db',
          encrypted: true,
          encryptionKey: null,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should create and read documents', () async {
      await db.initialize(dbName: 'test_crud_db');

      // Create a document
      const collection = 'users';
      final testData = {
        'name': 'John Doe',
        'email': 'john@example.com',
        'age': 30,
      };

      final id = await db.create(collection, testData);

      expect(id, isNotEmpty);

      // Read the document back
      final doc = await db.read(collection, id);
      expect(doc, isNotNull);
      expect(doc!['name'], 'John Doe');
      expect(doc['email'], 'john@example.com');
      expect(doc['age'], 30);
      expect(doc['_type'], collection);
      expect(doc['id'], id);
      expect(doc['_createdAt'], isNotNull);
      expect(doc['_updatedAt'], isNotNull);
      expect(doc['_version'], 1);
    });

    test('should update documents', () async {
      await db.initialize(dbName: 'test_update_db');

      // Create a document
      const collection = 'users';
      final id = await db.create(collection, {'name': 'Original Name'});

      // Update it
      final success = await db.update(collection, id, {
        'name': 'Updated Name',
        'newField': 'New Value',
      });
      expect(success, isTrue);

      // Read it back
      final doc = await db.read(collection, id);
      expect(doc, isNotNull);
      expect(doc!['name'], 'Updated Name');
      expect(doc['newField'], 'New Value');
      expect(doc['_version'], 2);
    });

    test('should return false when updating non-existent document', () async {
      await db.initialize(dbName: 'test_update_fail_db');

      const collection = 'users';
      final success = await db.update(collection, 'non-existent-id', {
        'name': 'Test',
      });

      expect(success, isFalse);
    });

    test('should delete documents', () async {
      await db.initialize(dbName: 'test_delete_db');

      // Create a document
      const collection = 'users';
      final id = await db.create(collection, {'name': 'To Delete'});

      // Verify it exists
      var doc = await db.read(collection, id);
      expect(doc, isNotNull);

      // Delete it
      final success = await db.delete(collection, id);
      expect(success, isTrue);

      // Verify it's gone
      doc = await db.read(collection, id);
      expect(doc, isNull);
    });

    test('should return false when deleting non-existent document', () async {
      await db.initialize(dbName: 'test_delete_fail_db');

      const collection = 'users';
      final success = await db.delete(collection, 'non-existent-id');

      expect(success, isFalse);
    });

    test('should find all documents in a collection', () async {
      await db.initialize(dbName: 'test_findall_db');

      const collection = 'users';

      // Create multiple documents
      await db.create(collection, {'name': 'User 1', 'age': 25});
      await db.create(collection, {'name': 'User 2', 'age': 30});
      await db.create(collection, {'name': 'User 3', 'age': 35});

      // Find all
      final docs = await db.findAll(collection);

      expect(docs.length, 3);
      expect(docs.every((d) => d['_type'] == collection), isTrue);
    });

    test('should find all with limit', () async {
      await db.initialize(dbName: 'test_findall_limit_db');

      const collection = 'users';

      // Create multiple documents
      await db.create(collection, {'name': 'User 1'});
      await db.create(collection, {'name': 'User 2'});
      await db.create(collection, {'name': 'User 3'});
      await db.create(collection, {'name': 'User 4'});
      await db.create(collection, {'name': 'User 5'});

      // Find all with limit
      final docs = await db.findAll(collection, limit: 3);

      expect(docs.length, 3);
    });

    test('should find documents with filter', () async {
      await db.initialize(dbName: 'test_findwhere_db');

      const collection = 'users';

      // Create documents with different statuses
      await db.create(collection, {'name': 'Active User 1', 'status': 'active'});
      await db.create(collection, {'name': 'Inactive User', 'status': 'inactive'});
      await db.create(collection, {'name': 'Active User 2', 'status': 'active'});
      await db.create(collection, {'name': 'Pending User', 'status': 'pending'});

      // Find only active users
      final activeDocs = await db.findWhere(collection, {'status': 'active'});

      expect(activeDocs.length, 2);
      expect(activeDocs.every((d) => d['status'] == 'active'), isTrue);
    });

    test('should find documents with filter and limit', () async {
      await db.initialize(dbName: 'test_findwhere_limit_db');

      const collection = 'users';

      // Create documents
      await db.create(collection, {'name': 'User 1', 'type': 'admin'});
      await db.create(collection, {'name': 'User 2', 'type': 'admin'});
      await db.create(collection, {'name': 'User 3', 'type': 'admin'});
      await db.create(collection, {'name': 'User 4', 'type': 'user'});

      // Find with filter and limit
      final docs = await db.findWhere(
        collection,
        {'type': 'admin'},
        limit: 2,
      );

      expect(docs.length, 2);
      expect(docs.every((d) => d['type'] == 'admin'), isTrue);
    });

    test('should count documents in a collection', () async {
      await db.initialize(dbName: 'test_count_db');

      const collection = 'users';

      // Initially should be 0
      var count = await db.count(collection);
      expect(count, 0);

      // Create some documents
      await db.create(collection, {'name': 'User 1'});
      await db.create(collection, {'name': 'User 2'});
      await db.create(collection, {'name': 'User 3'});

      // Count should be 3
      count = await db.count(collection);
      expect(count, 3);
    });

    test('should get database statistics', () async {
      await db.initialize(dbName: 'test_stats_db');

      // Create some test data
      await db.create('users', {'name': 'User 1'});
      await db.create('users', {'name': 'User 2'});
      await db.create('tasks', {'title': 'Task 1'});

      final stats = await db.getStats();

      expect(stats.connectionStatus, DatabaseConnectionStatus.connected);
      expect(stats.databasePath, isNotNull);
      expect(stats.databasePath, contains('test_stats_db'));
    });

    test('should throw error when not initialized', () async {
      expect(
        () => db.create('users', {'name': 'Test'}),
        throwsA(isA<StateError>()),
      );
    });

    test('should handle concurrent operations', () async {
      await db.initialize(dbName: 'test_concurrent_db');

      const collection = 'users';

      // Create multiple documents concurrently
      final futures = List.generate(
        10,
        (i) => db.create(collection, {'name': 'User $i', 'index': i}),
      );

      final ids = await Future.wait(futures);

      expect(ids.length, 10);
      expect(ids.toSet().length, 10); // All IDs should be unique

      // Verify all documents exist
      final count = await db.count(collection);
      expect(count, 10);
    });

    test('should preserve document metadata on updates', () async {
      await db.initialize(dbName: 'test_metadata_db');

      const collection = 'users';
      final id = await db.create(collection, {'name': 'Test User'});

      // Get initial document
      final doc1 = await db.read(collection, id);
      final createdAt = doc1!['_createdAt'];
      final version1 = doc1['_version'];

      // Wait a bit to ensure timestamps are different
      await Future.delayed(const Duration(milliseconds: 100));

      // Update document
      await db.update(collection, id, {'name': 'Updated User'});

      // Get updated document
      final doc2 = await db.read(collection, id);

      expect(doc2!['_createdAt'], createdAt); // Should not change
      expect(doc2['_updatedAt'], isNot(equals(createdAt))); // Should be updated
      expect(doc2['_version'], version1 + 1); // Should increment
    });
  });
}
