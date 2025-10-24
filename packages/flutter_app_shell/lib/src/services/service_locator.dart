import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';
import '../state/app_shell_settings_store.dart';
import 'navigation_service.dart';
import 'database_service.dart';
import 'preferences_service.dart';
import 'network_service.dart';
import 'authentication_service.dart';
import 'logging_service.dart';
import 'cloudflare_service.dart';
import 'window_state_service.dart';
import 'app_lifecycle_manager.dart';
import '../utils/logger.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  // Initialize LoggingService first (before any logging calls)
  if (!getIt.isRegistered<LoggingService>()) {
    final loggingService = LoggingService.instance;
    await loggingService.initialize(
      globalLevel: Level.INFO,
      enableFileLogging: false, // Can be configured later
    );
    getIt.registerSingleton<LoggingService>(loggingService);
  }

  // Get a hierarchical logger for this service
  final logger = createServiceLogger('ServiceLocator');
  logger.info('Setting up service locator...');

  // Core Services

  // Register AppLifecycleManager (should be early for cleanup hooks)
  if (!getIt.isRegistered<AppLifecycleManager>()) {
    final lifecycleManager = AppLifecycleManager.instance;
    lifecycleManager.initialize();
    getIt.registerSingleton<AppLifecycleManager>(lifecycleManager);
    logger.info('Registered AppLifecycleManager');
  } else {
    logger.info('AppLifecycleManager already registered, skipping');
  }

  // Register NavigationService
  if (!getIt.isRegistered<NavigationService>()) {
    getIt.registerLazySingleton<NavigationService>(() => NavigationService());
    logger.info('Registered NavigationService');
  } else {
    logger.info('NavigationService already registered, skipping');
  }

  // Get SharedPreferences instance
  if (!getIt.isRegistered<SharedPreferences>()) {
    final sharedPreferences = await SharedPreferences.getInstance();
    getIt.registerSingleton<SharedPreferences>(sharedPreferences);
    logger.info('Registered SharedPreferences');
  } else {
    logger.info('SharedPreferences already registered, skipping');
  }

  // Register PreferencesService and initialize
  if (!getIt.isRegistered<PreferencesService>()) {
    final preferencesService = PreferencesService.instance;
    await preferencesService.initialize();
    getIt.registerSingleton<PreferencesService>(preferencesService);
    logger.info('Registered PreferencesService');
  } else {
    logger.info('PreferencesService already registered, skipping');
  }

  // Register AppShellSettingsStore
  if (!getIt.isRegistered<AppShellSettingsStore>()) {
    getIt.registerLazySingleton<AppShellSettingsStore>(
      () => AppShellSettingsStore(getIt<SharedPreferences>()),
    );
    logger.info('Registered AppShellSettingsStore');
  } else {
    logger.info('AppShellSettingsStore already registered, skipping');
  }

  // Advanced Services

  // Register DatabaseService (ReaxDB) with automatic configuration from environment
  if (!getIt.isRegistered<DatabaseService>()) {
    try {
      // Get configuration from environment variables
      final dbName = dotenv.env['REAXDB_DATABASE_NAME'] ?? 'app_shell';
      final encrypted = dotenv.env['REAXDB_ENCRYPTION_ENABLED'] == 'true';
      final encryptionKey = dotenv.env['REAXDB_ENCRYPTION_KEY'];

      final databaseService = DatabaseService.instance;
      await databaseService.initialize(
        dbName: dbName,
        encrypted: encrypted,
        encryptionKey: encryptionKey,
      );
      getIt.registerSingleton<DatabaseService>(databaseService);

      final mode = encrypted ? 'encrypted' : 'unencrypted';
      logger.info('Registered ReaxDB database service ($mode, db: $dbName)');
    } catch (e) {
      // If dotenv is not loaded, fallback to default settings
      logger.warning(
          'Environment variables not available, using default database settings');
      final databaseService = DatabaseService.instance;
      await databaseService.initialize(dbName: 'app_shell');
      getIt.registerSingleton<DatabaseService>(databaseService);
      logger.info('Registered ReaxDB database service (default settings)');
    }
  } else {
    logger.info('DatabaseService already registered, skipping');
  }

  // Register NetworkService and initialize
  if (!getIt.isRegistered<NetworkService>()) {
    final networkService = NetworkService.instance;
    await networkService.initialize();
    getIt.registerSingleton<NetworkService>(networkService);
    logger.info('Registered NetworkService');
  } else {
    logger.info('NetworkService already registered, skipping');
  }

  // Register AuthenticationService and initialize
  if (!getIt.isRegistered<AuthenticationService>()) {
    final authService = AuthenticationService.instance;
    await authService.initialize();
    getIt.registerSingleton<AuthenticationService>(authService);
    logger.info('Registered AuthenticationService');
  } else {
    logger.info('AuthenticationService already registered, skipping');
  }

  // Register CloudflareService and initialize
  if (!getIt.isRegistered<CloudflareService>()) {
    try {
      // Get Cloudflare configuration from environment variables
      final workerUrl = dotenv.env['CLOUDFLARE_WORKER_URL'] ?? '';
      final jwtSecret = dotenv.env['SESSION_JWT_SECRET'] ?? '';
      final jwtIssuer = dotenv.env['SESSION_JWT_ISSUER'] ?? '';
      final jwtAudience = dotenv.env['SESSION_JWT_AUDIENCE'] ?? '';

      final cloudflareService = CloudflareService.instance;
      await cloudflareService.initialize(
        authShimUrl: workerUrl.isNotEmpty
            ? '${workerUrl.replaceAll('/api/', '/auth/')}'
            : '',
        apiWorkerUrl: workerUrl.isNotEmpty ? workerUrl : '',
        authService: getIt<AuthenticationService>(),
      );
      getIt.registerSingleton<CloudflareService>(cloudflareService);

      logger.info(
          'Registered CloudflareService${workerUrl.isEmpty ? ' (not configured)' : ''}');
    } catch (e) {
      // If CloudflareService fails to initialize, register it anyway but mark as disabled
      logger.warning(
          'CloudflareService initialization failed, registering as disabled: $e');
      final cloudflareService = CloudflareService.instance;
      getIt.registerSingleton<CloudflareService>(cloudflareService);
    }
  } else {
    logger.info('CloudflareService already registered, skipping');
  }

  // Register WindowStateService without initialization (will be initialized after window is ready)
  if (!getIt.isRegistered<WindowStateService>()) {
    final windowStateService = WindowStateService.instance;
    getIt.registerSingleton<WindowStateService>(windowStateService);
    logger.info('Registered window state service (initialization deferred)');
  } else {
    logger.info('WindowStateService already registered, skipping');
  }

  logger.info('Service locator setup complete');
}
