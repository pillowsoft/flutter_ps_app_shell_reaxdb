import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

/// Demo screen showcasing local database operations with ReaxDB
class LocalDatabaseDemoScreen extends StatefulWidget {
  const LocalDatabaseDemoScreen({super.key});

  @override
  State<LocalDatabaseDemoScreen> createState() =>
      _LocalDatabaseDemoScreenState();
}

class _LocalDatabaseDemoScreenState extends State<LocalDatabaseDemoScreen> {
  late DatabaseService _databaseService;

  // Demo data
  final List<Map<String, dynamic>> _documents = [];
  String _dbStatus = 'Not initialized';
  String? _lastMessage;
  DateTime? _messageTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _databaseService = getIt<DatabaseService>();
      _updateStatus();
      _loadData();
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMessage('Failed to initialize services: $e');
      });
    }
  }

  void _updateStatus() {
    if (mounted) {
      setState(() {
        _dbStatus =
            _databaseService.connectionStatus.value.toString().split('.').last;
      });
    }
  }

  Future<void> _loadData() async {
    if (!_databaseService.isInitialized) return;

    try {
      setState(() => _isLoading = true);

      final docs = await _databaseService.findAll('demo');
      if (mounted) {
        setState(() {
          _documents.clear();
          _documents.addAll(docs);
          _isLoading = false;
        });
      }
    } catch (e) {
      _showMessage('Failed to load data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addDocument() async {
    try {
      final timestamp = DateTime.now().toIso8601String();
      final doc = {
        'title': 'Demo Document ${_documents.length + 1}',
        'content': 'Created at $timestamp',
        'timestamp': timestamp,
      };

      await _databaseService.create('demo', doc);
      _showMessage('Document created successfully');
      _loadData();
    } catch (e) {
      _showMessage('Failed to create document: $e');
    }
  }

  Future<void> _deleteDocument(String id) async {
    try {
      final success = await _databaseService.delete('demo', id);
      if (success) {
        _showMessage('Document deleted successfully');
        _loadData();
      } else {
        _showMessage('Failed to delete document');
      }
    } catch (e) {
      _showMessage('Failed to delete document: $e');
    }
  }

  Future<void> _clearAllDocuments() async {
    final ui = getAdaptiveFactory(context);

    final confirmed = await ui.showDialog<bool>(
      context: context,
      title: const Text('Clear All Documents'),
      content:
          const Text('Are you sure you want to delete all demo documents?'),
      actions: [
        ui.textButton(
          label: 'Cancel',
          onPressed: () => Navigator.pop(context, false),
        ),
        ui.button(
          label: 'Delete All',
          onPressed: () => Navigator.pop(context, true),
        ),
      ],
    );

    if (confirmed == true) {
      try {
        final docs = await _databaseService.findAll('demo');
        for (final doc in docs) {
          await _databaseService.delete('demo', doc['id']);
        }
        _showMessage('All documents cleared');
        _loadData();
      } catch (e) {
        _showMessage('Failed to clear documents: $e');
      }
    }
  }

  Future<void> _showDatabaseStats() async {
    try {
      final stats = await _databaseService.getStats();

      if (mounted) {
        final ui = getAdaptiveFactory(context);

        ui.showDialog(
          context: context,
          title: const Text('Database Statistics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Database Status',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Status: ${stats.connectionStatus.name}'),
              const SizedBox(height: 4),
              Text('Total Documents: ${stats.totalDocuments}'),
              const SizedBox(height: 4),
              Text('Total Collections: ${stats.totalCollections}'),
              const SizedBox(height: 16),
              const Text(
                'WAL File Management',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (stats.walFileCount != null) ...[
                Text('WAL Files: ${stats.walFileCount}'),
                const SizedBox(height: 4),
                Text(
                  'WAL Size: ${stats.walSizeMB?.toStringAsFixed(2) ?? "0.00"} MB',
                ),
                const SizedBox(height: 4),
                if (stats.lastCleanupTime != null)
                  Text(
                    'Last Cleanup: ${_formatDateTime(stats.lastCleanupTime!)}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ] else
                const Text(
                  'No WAL cleanup has run yet',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              const SizedBox(height: 16),
              const Text(
                'Database Path',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                stats.databasePath ?? 'Unknown',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            ui.textButton(
              label: 'Close',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      }
    } catch (e) {
      _showMessage('Failed to get stats: $e');
    }
  }

  Future<void> _cleanupWalFiles() async {
    try {
      setState(() => _isLoading = true);
      await _databaseService.cleanupWalFiles();
      _showMessage('WAL files cleaned up successfully');
      setState(() => _isLoading = false);
    } catch (e) {
      _showMessage('Failed to cleanup WAL files: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      setState(() {
        _lastMessage = message;
        _messageTime = DateTime.now();
      });

      final ui = getAdaptiveFactory(context);
      ui.showSnackBar(
        context,
        message,
        duration: const Duration(seconds: 3),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = getAdaptiveFactory(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ui.pageTitle('Local Database Demo'),
        const SizedBox(height: 24),

        // Info Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ReaxDB Local Storage',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This demo uses ReaxDB for local-only data storage. All data is stored on your device with no cloud synchronization.',
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.storage, size: 16),
                    const SizedBox(width: 8),
                    Text('Status: $_dbStatus'),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Actions
        Row(
          children: [
            Expanded(
              child: ui.button(
                label: 'Add Document',
                onPressed: _addDocument,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ui.button(
                label: 'Clear All',
                onPressed: _clearAllDocuments,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: ui.outlinedButton(
                label: 'Refresh',
                onPressed: _loadData,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ui.outlinedButton(
                label: 'Show Stats',
                onPressed: _showDatabaseStats,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: ui.outlinedButton(
                label: 'Cleanup WAL Files',
                onPressed: _cleanupWalFiles,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Documents List
        Text(
          'Documents (${_documents.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_documents.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No documents yet',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Add Document" to create your first document',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...(_documents.map((doc) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.description),
                title: Text(doc['title'] ?? 'Untitled'),
                subtitle: Text(doc['content'] ?? ''),
                trailing: ui.iconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteDocument(doc['id']),
                ),
              ),
            );
          }).toList()),

        const SizedBox(height: 24),

        // Last Action
        if (_lastMessage != null && _messageTime != null)
          Card(
            color: Colors.grey[100],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastMessage!,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
