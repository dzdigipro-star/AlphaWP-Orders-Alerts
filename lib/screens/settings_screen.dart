import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../services/notification_service.dart';
import '../models/site.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsChecked = false;
  String _notificationStatus = 'Checking...';
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkNotificationStatus();
  }

  void _checkNotificationStatus() {
    final service = NotificationService.instance;
    setState(() {
      _notificationsChecked = true;
      if (service.hasError) {
        _notificationStatus = 'Not available';
        _notificationsEnabled = false;
      } else if (service.isInitialized && service.token != null) {
        _notificationStatus = 'Enabled';
        _notificationsEnabled = true;
      } else if (service.isInitialized) {
        _notificationStatus = 'Permission denied';
        _notificationsEnabled = false;
      } else {
        _notificationStatus = 'Not configured';
        _notificationsEnabled = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AppProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Section
          _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeName(provider.themeMode)),
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                ),
              ],
              selected: {provider.themeMode},
              onSelectionChanged: (modes) {
                provider.setThemeMode(modes.first);
              },
            ),
          ),

          const Divider(),

          // Sites Section
          _SectionHeader(title: 'Connected Stores'),
          ...provider.sites.asMap().entries.map((entry) {
            final index = entry.key;
            final site = entry.value;
            final isCurrent = site == provider.currentSite;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isCurrent 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.surfaceVariant,
                child: Icon(
                  Icons.store,
                  color: isCurrent 
                      ? theme.colorScheme.onPrimary 
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              title: Text(site.name),
              subtitle: Text(site.url),
              trailing: isCurrent
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: isCurrent 
                  ? null 
                  : () => provider.setCurrentSite(site),
              onLongPress: () => _showSiteOptions(context, provider, site, index),
            );
          }),
          
          ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                Icons.add,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('Add Another Store'),
            subtitle: const Text('Connect a new WordPress site'),
            onTap: () => _addNewSite(context, provider),
          ),

          const Divider(),

          // Notifications Section
          _SectionHeader(title: 'Notifications'),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Push Notifications'),
            subtitle: Text(_notificationStatus),
            trailing: Icon(
              _notificationsEnabled 
                  ? Icons.check_circle 
                  : Icons.error_outline,
              color: _notificationsEnabled 
                  ? Colors.green 
                  : Colors.orange,
            ),
          ),

          const Divider(),

          // Account Section
          _SectionHeader(title: 'Account'),
          ListTile(
            leading: Icon(
              Icons.logout,
              color: theme.colorScheme.error,
            ),
            title: Text(
              'Logout',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            subtitle: const Text('Disconnect from current store'),
            onTap: () => _confirmLogout(context, provider),
          ),

          const SizedBox(height: 24),

          // App Info
          Center(
            child: Text(
              'AlphaWP Orders Alerts v1.0.0',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _themeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light: return 'Light';
      case ThemeMode.dark: return 'Dark';
      case ThemeMode.system: return 'System';
    }
  }

  void _showSiteOptions(BuildContext context, AppProvider provider, Site site, int index) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Switch to this store'),
              onTap: () {
                Navigator.pop(ctx);
                provider.setCurrentSite(site);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
              title: Text('Remove store', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmRemoveSite(context, provider, index);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveSite(BuildContext context, AppProvider provider, int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Store?'),
        content: const Text('This will remove the store from your app. You can add it again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.removeSite(index);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _addNewSite(BuildContext context, AppProvider provider) {
    // Navigate back to login which will add a new site
    Navigator.pop(context); // Close settings screen first
    provider.logout(); // This will trigger re-render to show LoginScreen
  }

  void _confirmLogout(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout?'),
        content: const Text('You will need to enter your API key again to reconnect.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.logout();
              Navigator.pop(context); // Go back to login
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
    );
  }
}
