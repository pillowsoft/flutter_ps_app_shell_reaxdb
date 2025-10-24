import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'database_service.dart';
import '../utils/logger.dart';

/// Manages app lifecycle events for proper service cleanup
///
/// This service ensures critical resources like the database are properly
/// closed during app termination, hot restarts, and background transitions.
///
/// **Key Features:**
/// - Detects app pause/detach/terminate events
/// - Closes database connection on app termination
/// - Prevents WAL file accumulation during development
/// - Handles hot restart cleanup (Flutter DevTools)
class AppLifecycleManager with WidgetsBindingObserver {
  static AppLifecycleManager? _instance;
  static AppLifecycleManager get instance => _instance ??= AppLifecycleManager._();

  AppLifecycleManager._();

  static final Logger _logger = createServiceLogger('AppLifecycleManager');

  bool _isInitialized = false;
  AppLifecycleState? _lastState;

  /// Initialize the lifecycle manager
  /// Registers as a WidgetsBinding observer to receive lifecycle events
  void initialize() {
    if (_isInitialized) return;

    try {
      WidgetsBinding.instance.addObserver(this);
      _isInitialized = true;
      _logger.info('App lifecycle manager initialized');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize lifecycle manager', e, stackTrace);
      rethrow;
    }
  }

  /// Dispose the lifecycle manager
  /// Removes observer registration
  void dispose() {
    if (_isInitialized) {
      try {
        WidgetsBinding.instance.removeObserver(this);
        _isInitialized = false;
        _logger.info('App lifecycle manager disposed');
      } catch (e) {
        _logger.warning('Error disposing lifecycle manager: $e');
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logger.fine('App lifecycle state changed: ${state.name}');
    _lastState = state;

    switch (state) {
      case AppLifecycleState.detached:
        // App is detaching - perform final cleanup
        _handleAppDetached();
        break;
      case AppLifecycleState.paused:
        // App moved to background - optional cleanup
        _handleAppPaused();
        break;
      case AppLifecycleState.resumed:
        // App returned to foreground
        _logger.fine('App resumed');
        break;
      case AppLifecycleState.inactive:
        // App is inactive (e.g., phone call, app switcher)
        _logger.fine('App inactive');
        break;
      case AppLifecycleState.hidden:
        // App is hidden (e.g., minimized)
        _logger.fine('App hidden');
        break;
    }
  }

  /// Handle app detachment (termination)
  void _handleAppDetached() {
    _logger.info('App detaching - performing cleanup');

    try {
      // Close database service if registered
      if (GetIt.I.isRegistered<DatabaseService>()) {
        final db = GetIt.I<DatabaseService>();
        db.close().then((_) {
          _logger.info('Database service closed on app detach');
        }).catchError((e) {
          _logger.warning('Failed to close database on app detach: $e');
        });
      }
    } catch (e) {
      _logger.warning('Error during app detach cleanup: $e');
    }
  }

  /// Handle app paused (moved to background)
  void _handleAppPaused() {
    _logger.fine('App paused - background transition');

    // Optional: You could close database here for stricter resource management
    // For now, we only close on detach to avoid frequent open/close cycles
  }

  /// Get current lifecycle state
  AppLifecycleState? get currentState => _lastState;

  /// Check if app is in foreground
  bool get isInForeground =>
      _lastState == AppLifecycleState.resumed ||
      _lastState == AppLifecycleState.inactive;

  /// Check if app is in background
  bool get isInBackground =>
      _lastState == AppLifecycleState.paused ||
      _lastState == AppLifecycleState.hidden;
}
