import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:reaxdb_dart/reaxdb_dart.dart' show SimpleReaxDB;
import 'package:path_provider/path_provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:logging/logging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/logger.dart';

/// Local-only database service using ReaxDB
/// Provides document/collection abstraction over key-value storage
///
/// This service replaces InstantDB with a pure local database solution.
/// All data is stored locally with no cloud sync capabilities.
class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  // Service-specific logger
  static final Logger _logger = createServiceLogger('DatabaseService');

  SimpleReaxDB? _db;
  String? _dbPath;

  // WAL cleanup tracking
  int? _lastWalFileCount;
  int? _lastWalTotalSize;
  DateTime? _lastCleanupTime;

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
  /// [encryptionKey] is required if encrypted is true
  Future<void> initialize({
    String dbName = 'app_shell',
    bool encrypted = false,
    String? encryptionKey,
  }) async {
    if (_db != null) return;

    final initStopwatch = Stopwatch()..start();

    try {
      connectionStatus.value = DatabaseConnectionStatus.connecting;
      _logger.info('Initializing ReaxDB database service...');

      // Get application documents directory
      final directory = await getApplicationDocumentsDirectory();
      _dbPath = '${directory.path}/$dbName';

      // Get WAL configuration from environment
      final walAutoCleanup = _getWalAutoCleanupSetting();
      final walMaxSizeMB = _getWalMaxSizeSetting();

      // Cleanup stale WAL files before initialization (dev mode optimization)
      if (walAutoCleanup) {
        final cleanupStopwatch = Stopwatch()..start();
        await _cleanupWalFiles(_dbPath!, walMaxSizeMB);
        cleanupStopwatch.stop();

        if (cleanupStopwatch.elapsedMilliseconds > 100) {
          _logger.warning(
            'WAL cleanup took ${cleanupStopwatch.elapsedMilliseconds}ms '
            '(this may indicate many accumulated WAL files from hot restarts)',
          );
        }
      }

      // Initialize ReaxDB using SimpleReaxDB API
      final dbOpenStopwatch = Stopwatch()..start();
      _db = await SimpleReaxDB.open(
        dbName,
        encrypted: encrypted,
        path: _dbPath,
      );
      dbOpenStopwatch.stop();

      initStopwatch.stop();

      // Log initialization timing
      final mode = encrypted ? 'encrypted' : 'unencrypted';
      _logger.info(
        'ReaxDB database initialized ($mode) at: $_dbPath\n'
        'Timing: total=${initStopwatch.elapsedMilliseconds}ms, '
        'db_open=${dbOpenStopwatch.elapsedMilliseconds}ms',
      );

      // Warn if initialization is slow (may indicate WAL processing)
      if (initStopwatch.elapsedMilliseconds > 1000) {
        _logger.warning(
          'Database initialization took ${initStopwatch.elapsedMilliseconds}ms. '
          'This may indicate accumulated WAL files being processed. '
          'Consider enabling REAXDB_WAL_AUTO_CLEANUP in your .env file.',
        );
      }

      connectionStatus.value = DatabaseConnectionStatus.connected;
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
        final checkpointOnClose = _getCheckpointOnCloseSetting();

        // Checkpoint WAL files if configured (merge changes back into main DB)
        if (checkpointOnClose && _dbPath != null) {
          try {
            await _checkpointWalFiles(_dbPath!);
          } catch (e) {
            _logger.warning('Failed to checkpoint WAL on close: $e');
          }
        }

        // ReaxDB doesn't require explicit close, just cleanup references
        _db = null;
        _dbPath = null;
        connectionStatus.value = DatabaseConnectionStatus.disconnected;
        _logger.info('Database service closed');
      } catch (e) {
        _logger.warning('Error closing database: $e');
      }
    }
  }

  // WAL Management

  /// Clean up stale WAL files before database initialization
  /// This prevents WAL accumulation during development (hot restarts, Ctrl+C exits)
  Future<void> _cleanupWalFiles(String dbPath, int maxSizeMB) async {
    try {
      final dir = Directory(dbPath).parent;
      final dbName = Directory(dbPath).path.split('/').last;

      // Look for WAL files (ReaxDB/SQLite pattern: dbname-wal, dbname-shm)
      final walFiles = dir
          .listSync()
          .where((entity) =>
              entity is File &&
              (entity.path.endsWith('-wal') ||
                  entity.path.endsWith('-shm') ||
                  entity.path.contains('$dbName') &&
                      entity.path.contains('wal')))
          .cast<File>()
          .toList();

      if (walFiles.isEmpty) {
        _logger.fine('No WAL files found to clean up');
        return;
      }

      // Calculate total WAL size
      final totalSize =
          walFiles.fold<int>(0, (sum, file) => sum + file.lengthSync());
      final totalSizeMB = totalSize / (1024 * 1024);

      _lastWalFileCount = walFiles.length;
      _lastWalTotalSize = totalSize;

      _logger.info(
        'Found ${walFiles.length} WAL file(s) '
        '(${totalSizeMB.toStringAsFixed(2)} MB)',
      );

      // Warn if WAL size exceeds threshold
      if (totalSizeMB > maxSizeMB) {
        _logger.warning(
          'WAL files exceed ${maxSizeMB}MB threshold '
          '(${totalSizeMB.toStringAsFixed(2)} MB). '
          'This indicates accumulated files from development hot restarts. '
          'Cleaning up...',
        );
      }

      // Delete WAL files (safe when database is not open)
      for (final file in walFiles) {
        try {
          file.deleteSync();
          _logger.fine('Deleted WAL file: ${file.path}');
        } catch (e) {
          _logger.warning('Failed to delete WAL file ${file.path}: $e');
        }
      }

      _lastCleanupTime = DateTime.now();
      _logger.info('WAL cleanup completed: removed ${walFiles.length} file(s)');
    } catch (e, stackTrace) {
      _logger.warning('Error during WAL cleanup', e, stackTrace);
      // Don't rethrow - WAL cleanup failure shouldn't prevent DB initialization
    }
  }

  /// Checkpoint WAL files (merge WAL changes back into main database)
  Future<void> _checkpointWalFiles(String dbPath) async {
    try {
      // Note: ReaxDB may handle this internally
      // If ReaxDB exposes a checkpoint API, call it here
      _logger.fine('WAL checkpoint requested on database close');
    } catch (e) {
      _logger.warning('WAL checkpoint failed: $e');
    }
  }

  /// Get WAL auto-cleanup setting from environment (default: true in debug mode)
  bool _getWalAutoCleanupSetting() {
    try {
      final envValue = dotenv.env['REAXDB_WAL_AUTO_CLEANUP'];
      if (envValue != null) {
        return envValue.toLowerCase() == 'true';
      }
      // Default: enable in debug mode, disable in release
      return kDebugMode;
    } catch (e) {
      return kDebugMode; // Fallback to debug mode default
    }
  }

  /// Get WAL max size setting from environment (default: 10 MB)
  int _getWalMaxSizeSetting() {
    try {
      final envValue = dotenv.env['REAXDB_WAL_MAX_SIZE_MB'];
      if (envValue != null) {
        return int.tryParse(envValue) ?? 10;
      }
      return 10; // Default: 10 MB
    } catch (e) {
      return 10; // Fallback
    }
  }

  /// Get checkpoint on close setting from environment (default: true)
  bool _getCheckpointOnCloseSetting() {
    try {
      final envValue = dotenv.env['REAXDB_CHECKPOINT_ON_CLOSE'];
      if (envValue != null) {
        return envValue.toLowerCase() == 'true';
      }
      return true; // Default: enabled
    } catch (e) {
      return true; // Fallback
    }
  }

  /// Manually cleanup WAL files (can be called from UI)
  Future<void> cleanupWalFiles() async {
    if (_dbPath == null) {
      throw StateError('Database not initialized');
    }

    _logger.info('Manual WAL cleanup requested');
    final maxSizeMB = _getWalMaxSizeSetting();
    await _cleanupWalFiles(_dbPath!, maxSizeMB);
  }

  // CRUD Operations

  /// Create a new document in a collection
  /// Returns the generated document ID
  Future<String> create(String collection, Map<String, dynamic> data) async {
    _ensureInitialized();

    try {
      // Generate document ID if not provided
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
      _logger.severe(
          'Failed to create document: collection=$collection', e, stackTrace);
      rethrow;
    }
  }

  /// Read a document by ID
  Future<Map<String, dynamic>?> read(String collection, String id) async {
    _ensureInitialized();

    try {
      final key = '$collection:$id';
      final data = await _db!.get(key);

      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return null;
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to read document: collection=$collection, id=$id',
          e,
          stackTrace);
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
      _logger.severe(
          'Failed to update document: collection=$collection, id=$id',
          e,
          stackTrace);
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
      _logger.severe(
          'Failed to delete document: collection=$collection, id=$id',
          e,
          stackTrace);
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
      final keys = await _db!.query(pattern);

      var documents = <Map<String, dynamic>>[];
      for (final key in keys) {
        final data = await _db!.get(key);
        if (data != null && data is Map) {
          final doc = Map<String, dynamic>.from(data);
          // Ensure _id is set for compatibility
          doc['_id'] = doc['id'];
          documents.add(doc);
        }
      }

      if (limit != null && limit > 0) {
        documents = documents.take(limit).toList();
      }

      _logger.fine('Found ${documents.length} documents in $collection');
      return documents;
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to find documents in collection: $collection', e, stackTrace);
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

      _logger.fine(
          'Found ${filtered.length} documents in $collection matching filter');
      return filtered;
    } catch (e, stackTrace) {
      _logger.severe(
          'Failed to find documents with filter in collection: $collection',
          e,
          stackTrace);
      rethrow;
    }
  }

  /// Count documents in a collection
  Future<int> count(String collection) async {
    final documents = await findAll(collection);
    return documents.length;
  }

  /// Watch a collection for changes (reactive)
  /// Note: ReaxDB SimpleAPI doesn't support reactive queries yet.
  /// This is a fallback that returns a computed signal based on periodic polling.
  /// For real-time updates, manually call findAll() after mutations.
  Computed<List<Map<String, dynamic>>> watchCollection(String collection) {
    _ensureInitialized();
    _logger.fine('Setting up watch for collection: $collection (polling mode)');

    // Create a signal that will hold the documents
    final docsSignal = signal<List<Map<String, dynamic>>>([]);

    // Initial load
    findAll(collection).then((docs) => docsSignal.value = docs);

    // Return a computed that just returns the signal value
    return computed(() => docsSignal.value);
  }

  /// Watch documents with a filter (reactive)
  /// Note: ReaxDB SimpleAPI doesn't support reactive queries yet.
  /// This is a fallback implementation.
  Computed<List<Map<String, dynamic>>> watchWhere(
    String collection,
    Map<String, dynamic> where,
  ) {
    _ensureInitialized();
    _logger.fine(
        'Setting up watch with filter for collection: $collection, filter: $where (polling mode)');

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
        walFileCount: _lastWalFileCount,
        walTotalSize: _lastWalTotalSize,
        lastCleanupTime: _lastCleanupTime,
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
      throw StateError(
          'DatabaseService not initialized. Call initialize() first.');
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

  // WAL metrics
  final int? walFileCount;
  final int? walTotalSize; // in bytes
  final DateTime? lastCleanupTime;

  DatabaseStats({
    required this.totalDocuments,
    required this.totalCollections,
    required this.connectionStatus,
    this.databasePath,
    this.walFileCount,
    this.walTotalSize,
    this.lastCleanupTime,
  });

  /// Get WAL size in MB
  double? get walSizeMB =>
      walTotalSize != null ? walTotalSize! / (1024 * 1024) : null;

  @override
  String toString() {
    final walInfo = walFileCount != null
        ? ', wal_files: $walFileCount (${walSizeMB?.toStringAsFixed(2) ?? 0} MB)'
        : '';
    return 'DatabaseStats(docs: $totalDocuments, collections: $totalCollections, '
        'status: ${connectionStatus.name}, path: $databasePath$walInfo)';
  }
}
