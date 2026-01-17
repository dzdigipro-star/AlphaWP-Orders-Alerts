import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../models/order.dart';
import '../models/lead.dart';
import 'settings_screen.dart';

/// Decode HTML entities like &#x62f; to their actual characters
String decodeHtmlEntities(String text) {
  // Common HTML entity patterns
  final hexPattern = RegExp(r'&#x([0-9a-fA-F]+);');
  final decPattern = RegExp(r'&#(\d+);');
  
  String result = text;
  
  // Decode hex entities (&#x62f; -> د)
  result = result.replaceAllMapped(hexPattern, (match) {
    final code = int.tryParse(match.group(1)!, radix: 16);
    return code != null ? String.fromCharCode(code) : match.group(0)!;
  });
  
  // Decode decimal entities (&#1583; -> د)
  result = result.replaceAllMapped(decPattern, (match) {
    final code = int.tryParse(match.group(1)!);
    return code != null ? String.fromCharCode(code) : match.group(0)!;
  });
  
  // Common named entities
  result = result
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&nbsp;', ' ');
  
  return result;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;
  final RefreshController _refreshController = RefreshController();
  
  Map<String, dynamic>? _stats;
  List<Order> _orders = [];
  List<Lead> _leads = [];
  bool _isLoading = true;
  Timer? _autoRefreshTimer;
  bool _deviceRegistered = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);
    _loadData();
    _setupNotifications();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _refreshController.dispose();
    _autoRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh data when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  void _setupNotifications() {
    final notificationService = NotificationService.instance;
    
    // Register device when token is received
    notificationService.onTokenReceived = (token) {
      _registerDevice(token);
    };
    
    // Refresh data when notification is received
    notificationService.onNotificationReceived = () {
      _loadData();
    };
    
    // If token already exists, register now
    if (notificationService.token != null && !_deviceRegistered) {
      _registerDevice(notificationService.token!);
    }
  }

  Future<void> _registerDevice(String token) async {
    if (_deviceRegistered) return;
    
    final site = context.read<AppProvider>().currentSite;
    if (site == null) return;

    final api = ApiService(site);
    final success = await api.registerDevice(token, 'AlphaWP Orders App');
    
    if (success) {
      _deviceRegistered = true;
      print('Device registered successfully with server');
    } else {
      print('Failed to register device with server');
    }
  }

  void _startAutoRefresh() {
    // Auto-refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final site = context.read<AppProvider>().currentSite;
    if (site == null) return;

    final api = ApiService(site);
    
    final results = await Future.wait([
      api.getStats(),
      api.getOrders(),
      api.getLeads(),
    ]);

    if (!mounted) return;
    setState(() {
      _stats = results[0] as Map<String, dynamic>?;
      _orders = results[1] as List<Order>;
      _leads = results[2] as List<Lead>;
      _isLoading = false;
    });

    _refreshController.refreshCompleted();
  }

  Future<void> _onRefresh() async {
    await _loadData();
  }

  void _callPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final site = context.watch<AppProvider>().currentSite;

    return Scaffold(
      appBar: AppBar(
        title: Text(site?.name ?? 'AlphaWP Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.shopping_cart), text: 'Orders'),
            Tab(icon: Icon(Icons.person_off), text: 'Leads'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboard(theme),
                  _buildOrdersList(theme),
                  _buildLeadsList(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildDashboard(ThemeData theme) {
    final today = _stats?['today'] ?? {};
    final leads = _stats?['leads'] ?? {};
    final currency = context.read<AppProvider>().currentSite?.currency ?? 'DZD';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Today's Stats
        Text(
          "Today's Performance",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.shopping_cart,
                title: 'Orders',
                value: '${today['orders'] ?? 0}',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.attach_money,
                title: 'Revenue',
                value: '${(today['revenue'] ?? 0).toStringAsFixed(0)} ${decodeHtmlEntities(currency)}',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.person_off,
                title: 'Abandoned',
                value: '${leads['abandoned'] ?? 0}',
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.pending_actions,
                title: 'Pending',
                value: '${_stats?['pending_orders'] ?? 0}',
                color: Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Recent Orders
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Orders',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        ..._orders.take(5).map((order) => _OrderCard(
          order: order,
          currency: currency,
          onCall: () => _callPhone(order.customerPhone),
        )),

        if (_orders.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(
                    Icons.inbox,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No orders yet',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrdersList(ThemeData theme) {
    final currency = context.read<AppProvider>().currentSite?.currency ?? 'DZD';

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        return _OrderCard(
          order: order,
          currency: currency,
          onCall: () => _callPhone(order.customerPhone),
        );
      },
    );
  }

  Widget _buildLeadsList(ThemeData theme) {
    if (_leads.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No abandoned leads',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _leads.length,
      itemBuilder: (context, index) {
        final lead = _leads[index];
        return _LeadCard(
          lead: lead,
          onCall: () => _callPhone(lead.customerPhone),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final String currency;
  final VoidCallback onCall;

  const _OrderCard({
    required this.order,
    required this.currency,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${order.orderNumber}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${order.statusEmoji} ${order.statusDisplay}',
                    style: TextStyle(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                Text(
                  '${order.total.toStringAsFixed(0)} ${decodeHtmlEntities(currency)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            if (order.customerCity.isNotEmpty || order.customerState.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    [order.customerCity, order.customerState]
                        .where((s) => s.isNotEmpty)
                        .join(', '),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.customerPhone,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'processing': return Colors.blue;
      case 'on-hold': return Colors.purple;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'refunded': return Colors.grey;
      case 'failed': return Colors.red;
      default: return Colors.grey;
    }
  }
}

class _LeadCard extends StatelessWidget {
  final Lead lead;
  final VoidCallback onCall;

  const _LeadCard({
    required this.lead,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    lead.productName.isNotEmpty 
                        ? lead.productName 
                        : 'Unknown Product',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(lead.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${lead.statusEmoji} ${lead.statusDisplay}',
                    style: TextStyle(
                      color: _getStatusColor(lead.status),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    lead.customerName.isNotEmpty 
                        ? lead.customerName 
                        : 'Unknown Customer',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            if (lead.time != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(lead.time!),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    lead.customerPhone,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'abandoned': return Colors.orange;
      case 'recovered': return Colors.green;
      case 'captcha_failed': return Colors.red;
      case 'trash': return Colors.grey;
      default: return Colors.grey;
    }
  }
}
