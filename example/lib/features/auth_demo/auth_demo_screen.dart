import 'package:flutter/material.dart';
import 'package:flutter_app_shell/flutter_app_shell.dart';

enum AuthMode { signIn, signUp }

class AuthDemoScreen extends StatefulWidget {
  const AuthDemoScreen({super.key});

  @override
  State<AuthDemoScreen> createState() => _AuthDemoScreenState();
}

class _AuthDemoScreenState extends State<AuthDemoScreen> {
  AuthMode _currentMode = AuthMode.signIn;

  // Controllers for form fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  // State management
  bool _isLoading = false;
  String _resultMessage = '';
  bool _isCodeSent = false;

  final _authService = AuthenticationService.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final ui = getAdaptiveFactory(context);
      final currentUser = _authService.currentUser.value;
      final isAuthenticated = _authService.isAuthenticated.value;

      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ui.pageTitle('Authentication Demo'),
          const SizedBox(height: 8),
          Text(
            'Test traditional email/password authentication and InstantDB magic link authentication',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 32),

          // Current Auth Status Card
          ui.card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isAuthenticated
                            ? Icons.verified_user
                            : Icons.person_off,
                        color: isAuthenticated
                            ? Colors.green
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Authentication Status',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAuthenticated
                        ? 'Signed in as: ${currentUser?.email ?? 'Unknown'}'
                        : 'Not authenticated',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (currentUser != null) ...[
                    const SizedBox(height: 8),
                    Text('Name: ${currentUser.name}',
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text('ID: ${currentUser.id}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                  if (isAuthenticated) ...[
                    const SizedBox(height: 16),
                    ui.button(
                      label: 'Sign Out',
                      onPressed: _signOut,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Auth Mode Selector
          if (!isAuthenticated) ...[
            ui.card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Authentication Method',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ui.segmentedControl<AuthMode>(
                      children: {
                        AuthMode.signIn: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.login),
                            SizedBox(width: 4),
                            Text('Sign In'),
                          ],
                        ),
                        AuthMode.signUp: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_add),
                            SizedBox(width: 4),
                            Text('Sign Up'),
                          ],
                        ),
                      },
                      groupValue: _currentMode,
                      onValueChanged: (value) {
                        setState(() {
                          _currentMode = value;
                          _resetForm();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Auth Form
            ui.card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAuthForm(ui),
                    if (_resultMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _resultMessage.contains('successful') ||
                                  _resultMessage.contains('sent')
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _resultMessage.contains('successful') ||
                                    _resultMessage.contains('sent')
                                ? Colors.green
                                : Colors.red,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _resultMessage,
                          style: TextStyle(
                            color: _resultMessage.contains('successful') ||
                                    _resultMessage.contains('sent')
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    });
  }

  Widget _buildAuthForm(AdaptiveWidgetFactory ui) {
    switch (_currentMode) {
      case AuthMode.signIn:
        return _buildSignInForm(ui);
      case AuthMode.signUp:
        return _buildSignUpForm(ui);
    }
  }

  Widget _buildSignInForm(AdaptiveWidgetFactory ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.login, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Sign In',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ui.textField(
          controller: _emailController,
          labelText: 'Email Address',
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email),
        ),
        const SizedBox(height: 16),
        ui.textField(
          controller: _passwordController,
          labelText: 'Password',
          hintText: 'Enter your password',
          obscureText: true,
          prefixIcon: const Icon(Icons.lock),
        ),
        const SizedBox(height: 24),
        ui.button(
          label: _isLoading ? 'Signing In...' : 'Sign In',
          onPressed: _isLoading ? () {} : _signIn,
        ),
      ],
    );
  }

  Widget _buildSignUpForm(AdaptiveWidgetFactory ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.person_add,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Sign Up',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ui.textField(
          controller: _nameController,
          labelText: 'Full Name',
          hintText: 'Enter your name',
          prefixIcon: const Icon(Icons.person),
        ),
        const SizedBox(height: 16),
        ui.textField(
          controller: _emailController,
          labelText: 'Email Address',
          hintText: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email),
        ),
        const SizedBox(height: 16),
        ui.textField(
          controller: _passwordController,
          labelText: 'Password',
          hintText: 'Enter your password (min 6 characters)',
          obscureText: true,
          prefixIcon: const Icon(Icons.lock),
        ),
        const SizedBox(height: 24),
        ui.button(
          label: _isLoading ? 'Creating Account...' : 'Sign Up',
          onPressed: _isLoading ? () {} : _signUp,
        ),
      ],
    );
  }

  Future<void> _sendMagicLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showResult('Please enter your email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final result = await _authService.sendMagicLink(email);
      if (result.success) {
        setState(() {
          _isCodeSent = true;
        });
        _showResult(
            'Magic link sent! Check your email for the verification code.');
      } else {
        _showResult(result.error ?? 'Failed to send magic link');
      }
    } catch (e) {
      _showResult('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyMagicCode() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();

    if (email.isEmpty || code.isEmpty) {
      _showResult('Please enter both email and verification code');
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final result = await _authService.verifyMagicCode(email, code);
      if (result.success) {
        _showResult('Magic link authentication successful!');
        _resetForm();
      } else {
        _showResult(result.error ?? 'Verification failed');
      }
    } catch (e) {
      _showResult('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showResult('Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final result = await _authService.signIn(email, password);
      if (result.success) {
        _showResult('Sign in successful!');
        _resetForm();
      } else {
        _showResult(result.error ?? 'Sign in failed');
      }
    } catch (e) {
      _showResult('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showResult('Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _resultMessage = '';
    });

    try {
      final result = await _authService.signUp(email, password, name);
      if (result.success) {
        _showResult('Account created and signed in successfully!');
        _resetForm();
      } else {
        _showResult(result.error ?? 'Sign up failed');
      }
    } catch (e) {
      _showResult('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signOut();
      _showResult('Signed out successfully');
      _resetForm();
    } catch (e) {
      _showResult('Error signing out: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetForm() {
    _emailController.clear();
    _passwordController.clear();
    _nameController.clear();
    _codeController.clear();
    setState(() {
      _isCodeSent = false;
      _resultMessage = '';
      _isLoading = false;
    });
  }

  void _showResult(String message) {
    setState(() {
      _resultMessage = message;
    });
  }
}
