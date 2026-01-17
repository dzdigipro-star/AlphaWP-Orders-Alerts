import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._();
  
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  FirebaseMessaging? _messaging;
  String? _token;
  bool _isInitialized = false;
  String? _initError;
  
  // Callback for when token is obtained or refreshed
  Function(String token)? onTokenReceived;
  // Callback for when a notification is received (for refreshing data)
  Function()? onNotificationReceived;

  NotificationService._();

  String? get token => _token;
  bool get isInitialized => _isInitialized;
  bool get hasError => _initError != null;
  String? get errorMessage => _initError;

  // Method to set error from external code (e.g., when Firebase.initializeApp fails)
  void setError(String error) {
    _initError = error;
    _isInitialized = true; // Mark as initialized so UI updates
  }


  Future<void> initialize() async {
    try {
      _messaging = FirebaseMessaging.instance;
      
      // Request permission
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
        
        // Get FCM token
        _token = await _messaging!.getToken();
        print('FCM Token: $_token');
        
        // Notify callback if set
        if (_token != null && onTokenReceived != null) {
          onTokenReceived!(_token!);
        }
        
        // Listen for token refresh
        _messaging!.onTokenRefresh.listen((token) {
          _token = token;
          print('FCM Token refreshed: $token');
          // Notify callback on refresh
          if (onTokenReceived != null) {
            onTokenReceived!(token);
          }
        });
      } else {
        print('Notification permission denied');
        _initError = 'Permission denied';
      }

      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      await _localNotifications.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Create Android notification channel for orders
      const orderChannel = AndroidNotificationChannel(
        'alphawp_orders',
        'AlphaWP Orders',
        description: 'Notifications for new orders and abandoned leads',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(orderChannel);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle message opened from background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      
      // Check if app was opened from a notification
      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }
      
      _isInitialized = true;
    } catch (e) {
      _initError = e.toString();
      _isInitialized = true; // Mark as initialized even on error so UI updates
      print('NotificationService initialization failed: $e');
      // Continue without push notifications
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
    // Handle navigation based on payload
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Foreground message: ${message.notification?.title}');
    
    // Play cha-ching sound
    await _playChaChing();
    
    // Vibrate
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500, amplitude: 255);
    }

    // Show local notification
    await _showLocalNotification(message);
    
    // Notify app to refresh data
    if (onNotificationReceived != null) {
      onNotificationReceived!();
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Message opened app: ${message.data}');
    // Handle navigation based on message data
  }

  Future<void> _playChaChing() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/cha_ching.mp3'));
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'alphawp_orders',
      'AlphaWP Orders',
      channelDescription: 'Notifications for new orders and abandoned leads',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(android: androidDetails),
      payload: message.data['type'],
    );
  }
}
