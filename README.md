# Flutter App Shell

> ⚠️ **EXPERIMENTAL SOFTWARE - NOT PRODUCTION READY** ⚠️
> 
> This framework is in early experimental stages and contains:
> - **Numerous bugs and incomplete features**
> - **Breaking changes without notice**
> - **Untested edge cases**
> - **Performance issues**
> 
> **USE AT YOUR OWN RISK** - This code is provided for educational purposes and inspiration only. It is NOT suitable for production applications. Consider this a reference implementation or starting point for your own framework.

## 📢 Recent Updates

### Navigation System Improvements (Latest)
- ✅ **Fixed bottom navigation threshold logic** - Apps now correctly show bottom tabs when ≤5 visible routes (was counting hidden routes)
- ✅ **Enhanced hidden routes support** - Routes accessible via code but not shown in navigation using `showInNavigation: false`
- ✅ **Improved AppShellAction navigation** - Context-aware navigation with declarative routes and backward compatibility
- ✅ **Comprehensive navigation demo** - Interactive screen showing responsive behavior and hidden routes
- ✅ **Better drawer detection** - Mobile apps with >5 visible routes automatically use drawer navigation

### Dialog System Improvements
- ✅ **Fixed Cupertino dialog width constraints** - Form dialogs now properly respect the `width` parameter on iPad/macOS
- ✅ **Comprehensive dialog support** - Added `showFormDialog`, `showPageModal`, `showActionSheet`, and `showConfirmationDialog` methods
- ✅ **Platform-specific behavior** - Cupertino uses full-screen on iPhone, proper width dialogs on iPad/desktop
- ✅ **Responsive width calculation** - Tablets can now display dialogs at requested width (e.g., 700px)

A comprehensive Flutter application framework for rapid development with adaptive UI, service architecture, state management, and cloud synchronization capabilities.

## 🚀 Features

### Core Framework
- **Adaptive UI System** - Seamlessly switch between Material, Cupertino, and ForUI design systems
  - Complete component library with 30+ adaptive widgets
  - Extended components: date/time pickers, range sliders, chips, tab bars, and more
  - Platform-specific styling and behavior
- **Plugin System** - Extensible architecture for custom functionality
  - Service Plugins: Add new services (analytics, payments, etc.)
  - Widget Plugins: Provide reusable UI components (charts, maps, etc.)
  - Theme Plugins: Create custom design systems beyond Material/Cupertino/ForUI
  - Workflow Plugins: Implement multi-step processes (onboarding, wizards, etc.)
  - Auto-discovery from dependencies with health monitoring
- **Service-Oriented Architecture** - Modular services with dependency injection via GetIt
- **Reactive State Management** - Built on Signals for efficient, granular updates
- **Responsive Navigation** - Adaptive layout system with platform-aware transitions:
  - Mobile (<600px): Bottom tabs (≤5 visible routes) or drawer (>5 visible routes)
  - Tablet (600-1200px): Navigation rail with collapsible labels
  - Desktop (>1200px): Full sidebar with expand/collapse
  - **Hidden Routes**: Routes accessible via code but not shown in navigation (`showInNavigation: false`)
  - **Platform Transitions**: iOS sliding in Cupertino, Material transitions in Material/ForUI
  - **Smart Back Button Detection**: Reliable back button appearance on nested routes
  - **Authentic iOS Feel**: Proper sliding animations and back button behavior
- **Wizard Navigation** - Step-by-step flows with progress tracking and persistence
- **Settings Persistence** - Automatic saving/loading of all preferences with reactive effects

### Local Database (ReaxDB)
- **High-Performance Storage** - 21,000+ writes/sec, 333,000+ cached reads/sec
- **Pure Dart Implementation** - Zero native dependencies, works on all platforms
- **Optional Encryption** - AES-256 encryption support for sensitive data
- **Local-Only Architecture** - All data stored on device, no cloud dependencies
- **Zero Configuration** - No schema setup or migrations required
- **Document/Collection API** - Familiar NoSQL patterns over key-value storage

### Services
- **NavigationService** - Centralized navigation management with GoRouter
- **DatabaseService** - NoSQL document storage with ReaxDB (no code generation, local-only)
- **PreferencesService** - Type-safe key-value storage with reactive signals
- **NetworkService** - Dio HTTP client with offline queue and retry logic
- **AuthenticationService** - JWT tokens, biometric support, session management
- **FileStorageService** - Local and cloud file management
- **Service Inspector** - Real-time debugging UI for all services and plugins with health monitoring

## 📦 Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_app_shell:
    path: packages/flutter_app_shell
```

## 🏗️ Project Structure

```
flutter_ps_app_shell/
├── packages/
│   └── flutter_app_shell/        # Core framework package
│       ├── lib/
│       │   ├── src/
│       │   │   ├── core/         # Core framework components
│       │   │   ├── services/     # Service implementations
│       │   │   ├── plugins/      # Plugin system
│       │   │   │   ├── interfaces/  # Plugin interfaces
│       │   │   │   ├── core/        # Plugin manager & registry
│       │   │   │   └── examples/    # Example plugins
│       │   │   ├── ui/           # UI components and adaptive system
│       │   │   ├── wizard/       # Wizard navigation system
│       │   │   ├── models/       # Data models
│       │   │   ├── state/        # State management
│       │   │   └── utils/        # Utilities
│       │   └── flutter_app_shell.dart
│       └── pubspec.yaml
├── example/                       # Example application
│   ├── lib/
│   │   ├── features/             # Feature modules
│   │   │   ├── local_database/  # Local database demo
│   │   │   ├── wizard_demo/     # Wizard navigation demo
│   │   │   ├── plugin_demo/     # Plugin system demo
│   │   │   └── ...
│   │   └── main.dart
│   └── pubspec.yaml
└── README.md
```

## 🚀 Zero Code Generation Required!

Flutter App Shell eliminates all code generation from your development workflow:

- ✅ **No build_runner** - No more waiting for generated files
- ✅ **No .g.dart files** - Clean, simple Dart code only
- ✅ **Faster development** - Instant hot reload without generation delays
- ✅ **ReaxDB database** - High-performance local NoSQL without code generation
- ✅ **Signals state management** - Reactive state without any setup or generation

**Before (with code generation):**
```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
# Wait for generation...
flutter run
```

**Now (zero code generation):**
```bash
flutter run  # That's it! 🎉
```

## 🎯 Quick Start

### Basic Setup

```dart
import 'package:flutter_app_shell/flutter_app_shell.dart';

void main() {
  runShellApp(() async {
    return AppConfig(
      title: 'My App',
      routes: [
        AppRoute(
          title: 'Home',
          path: '/',
          icon: Icons.home,
          builder: (context, state) => const HomeScreen(),
        ),
        // Hidden route example - accessible via context.push('/camera') but not shown in navigation
        AppRoute(
          title: 'Camera',
          path: '/camera',
          icon: Icons.camera,
          builder: (context, state) => const CameraScreen(),
          showInNavigation: false, // Hide from navigation UI
        ),
      ],
    );
  });
}
```

### Configure Local Database (ReaxDB)

1. **Setup Environment Configuration**

Create a `.env` file in your project root:

```bash
# ReaxDB Configuration
REAXDB_DATABASE_NAME=app_shell
REAXDB_ENCRYPTION_ENABLED=false  # Enable for encrypted storage
# REAXDB_ENCRYPTION_KEY=your-secure-key  # Required if encryption enabled
```

Add the `.env` file as an asset in your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - .env
```

2. **Initialize Services**

```dart
// Services are automatically configured from environment
// No manual initialization required!

void main() {
  runShellApp(() async {
    return AppConfig(
      title: 'My App',
      routes: [
        // Your routes here
      ],
    );
  });
}
```

3. **No Database Schema Required**

ReaxDB is schemaless - just start using it! The database automatically:
- Creates collections as you use them
- Provides high-performance local storage (21,000+ writes/sec)
- Works offline (no cloud dependency)
- Optional AES-256 encryption for sensitive data

## 🎨 UI Systems

The framework supports three distinct UI systems with complete component libraries:

### Material Design
- Google's Material Design 3 components
- Vibrant colors, elevation, ripple effects
- Standard Material widgets and behaviors

### Cupertino (iOS)
- Native iOS components and styling
- iOS-specific grouped lists for settings
- Platform-appropriate navigation patterns
- System gray backgrounds and native controls

### ForUI
- Modern, minimal design system
- Zinc/slate color palette
- Flat design with subtle borders
- Focus on accessibility and readability

## 💡 Usage Examples

### Adaptive UI

```dart
Widget build(BuildContext context) {
  final ui = getAdaptiveFactory(context);
  
  return ui.scaffold(
    title: 'Adaptive UI',
    body: Column(
      children: [
        ui.button(
          label: 'Adaptive Button',
          onPressed: () {},
        ),
        ui.textField(
          label: 'Adaptive Input',
          onChanged: (value) {},
        ),
      ],
    ),
  );
}
```

### Local Database Operations

```dart
final db = getIt<DatabaseService>();

// Create document
final id = await db.create('todos', {
  'title': 'Buy groceries',
  'completed': false,
});

// Read document
final doc = await db.read('todos', id);

// Query all documents in collection
final todos = await db.findAll('todos');

// Query with filter
final activeTodos = await db.findWhere('todos', {'completed': false});

// Watch for changes (reactive)
final todosSignal = db.watchCollection('todos');
// UI automatically rebuilds when data changes

// Update document
await db.update('todos', id, {
  'completed': true,
});

// Delete document
await db.delete('todos', id);
```

### File Storage

```dart
final storage = FileStorageService.instance;

// Save file (local + cloud)
final result = await storage.saveFile(
  fileName: 'document.pdf',
  data: fileBytes,
  folder: 'documents',
  syncToCloud: true,
);

// Load file (with fallback)
final data = await storage.loadFile(
  fileName: 'document.pdf',
  folder: 'documents',
  preferCloud: false, // Try local first
);

// Get public URL
final url = await storage.getPublicUrl(
  fileName: 'document.pdf',
  folder: 'documents',
  expiresIn: Duration(hours: 1),
);
```

### Wizard Navigation

```dart
final wizard = WizardController(
  wizardId: 'onboarding',
  steps: [
    WizardStep(
      id: 'welcome',
      title: 'Welcome',
      builder: (context, wizard) => WelcomeStep(),
    ),
    WizardStep(
      id: 'profile',
      title: 'Create Profile',
      validator: () async => profileValid,
      builder: (context, wizard) => ProfileStep(),
    ),
  ],
  onComplete: (data) async {
    print('Wizard completed with data: $data');
  },
);

// Navigate to wizard
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => WizardScreen(controller: wizard),
  ),
);
```

## 🔧 Configuration

### Environment Variables

Configure ReaxDB using environment variables in your `.env` file:

```bash
# Database configuration
REAXDB_DATABASE_NAME=app_shell
REAXDB_ENCRYPTION_ENABLED=false

# If encryption is enabled, provide a key
# REAXDB_ENCRYPTION_KEY=your-secure-encryption-key

# Development options
DEBUG_LOGGING=false
LOG_LEVEL=info
```

### ReaxDB Features

ReaxDB provides:
- **High-performance storage** - 21,000+ writes/sec, 333,000+ cached reads/sec
- **Pure Dart implementation** - Zero native dependencies, works on all platforms
- **Local-only architecture** - All data stored on device, no cloud required
- **Optional AES-256 encryption** - Secure sensitive data at rest
- **Schema flexibility** - No migrations required
- **Document/collection API** - Familiar NoSQL patterns

## 📱 Example App

Run the example app to see all features in action:

```bash
cd example
flutter run
```

Navigate to different demos:
- `/` - Home screen with framework overview
- `/dashboard` - Responsive dashboard with adaptive widgets
- `/settings` - Platform-adaptive settings screen
  - Material: Card-based layout
  - Cupertino: iOS-style grouped lists
  - ForUI: Minimal modern design
- `/profile` - User profile with adaptive forms
- `/adaptive` - Live UI system switching demo
- `/services` - Interactive service testing
- `/inspector` - Real-time service monitoring and debugging

## 📚 Documentation

### Complete Documentation
- **[docs/README.md](docs/README.md)** - Comprehensive documentation hub
- **[Getting Started Guide](docs/getting-started.md)** - 5-minute tutorial
- **[Architecture Overview](docs/architecture.md)** - Framework design principles
- **[Common Patterns](docs/examples/patterns.md)** - Real-world examples
- **[Best Practices](docs/reference/best-practices.md)** - Guidelines and recommendations

### AI-Friendly Documentation
- **[llms.txt](llms.txt)** - Navigation index optimized for AI consumption ([llms.txt spec](https://llmstxt.org))
- **[llms-full.txt](llms-full.txt)** - Complete documentation for AI development

```bash
# Generate updated llms.txt files
just generate-llms
```

## 🛠️ Development

### Quick Commands

```bash
# Setup project
just setup

# Run example app
just run

# Run tests
just test

# Generate llms.txt files
just generate-llms

# Clean build
just clean
```

### Running Tests

```bash
flutter test
```

### Building

```bash
# iOS
flutter build ios

# Android
flutter build apk

# Web
flutter build web

# Desktop
flutter build macos
flutter build windows
flutter build linux
```

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 🙏 Acknowledgments

Built with:
- [Flutter](https://flutter.dev)
- [InstantDB](https://www.instantdb.com)
- [Signals](https://pub.dev/packages/signals)
- [GoRouter](https://pub.dev/packages/go_router)
- [GetIt](https://pub.dev/packages/get_it)

## 📞 Support

For issues and questions, please use the GitHub issue tracker.