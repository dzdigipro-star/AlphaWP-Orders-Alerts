import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/site.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _siteUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _siteUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Clean URL
      String url = _siteUrlController.text.trim();
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }

      // Create site and test connection
      final tempSite = Site(
        name: 'Testing...',
        url: url,
        apiKey: _apiKeyController.text.trim(),
      );

      final api = ApiService(tempSite);
      final result = await api.authenticate();

      if (result != null && result['success'] == true) {
        final site = Site(
          name: result['site_name'] ?? 'My Store',
          url: url,
          apiKey: _apiKeyController.text.trim(),
          currency: result['currency'] ?? 'DZD',
        );

        final provider = context.read<AppProvider>();
        await provider.addSite(site);
        await provider.setCurrentSite(site);

        // Register device for push notifications
        final token = NotificationService.instance.token;
        if (token != null) {
          await api.registerDevice(token, 'Mobile App');
        }
      } else {
        setState(() {
          _errorMessage = 'Invalid API key or site URL';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection failed. Please check your details.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // Logo/Icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    size: 60,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Title
                Text(
                  'AlphaWP Orders Alerts',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Connect your WordPress store',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // Site URL field
                TextFormField(
                  controller: _siteUrlController,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'Site URL',
                    hintText: 'example.com',
                    prefixIcon: const Icon(Icons.language),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your site URL';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // API Key field
                TextFormField(
                  controller: _apiKeyController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _connect(),
                  decoration: InputDecoration(
                    labelText: 'API Key',
                    hintText: 'Paste your API key here',
                    prefixIcon: const Icon(Icons.key),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your API key';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Find your API key in WordPress → AlphaWP Direct Checkout → Mobile App',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Connect button
                FilledButton(
                  onPressed: _isLoading ? null : _connect,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Connect Store',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                
                const SizedBox(height: 24),
                
                // Theme toggle
                Center(
                  child: Consumer<AppProvider>(
                    builder: (context, provider, _) {
                      return SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode),
                          ),
                        ],
                        selected: {provider.themeMode},
                        onSelectionChanged: (modes) {
                          provider.setThemeMode(modes.first);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
