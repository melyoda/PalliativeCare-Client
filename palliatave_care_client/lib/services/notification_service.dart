// In lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:palliatave_care_client/services/api_service.dart';
// You will need to create this Notification model in Flutter
import 'package:palliatave_care_client/models/notification_model.dart'; 
import 'dart:convert';

class NotificationService with ChangeNotifier {
  final ApiService _apiService = ApiService();
  StompClient? stompClient;

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  Future<void> connect() async {
    final String? token = await _apiService.getToken();
    if (token == null) {
      print("NotificationService: No token, cannot connect.");
      return;
    }

    stompClient = StompClient(
      config: StompConfig(
        // Use wss for secure WebSocket, same as your https base URL
        url: 'wss://palliativecare-k6g2.onrender.com/ws',
        onConnect: _onConnect,
        onWebSocketError: (dynamic error) => print(error.toString()),
        stompConnectHeaders: {'Authorization': 'Bearer $token'},
        webSocketConnectHeaders: {'Authorization': 'Bearer $token'},
      ),
    );

    stompClient!.activate();
  }

  void _onConnect(StompFrame frame) {
    // A user subscribes to their own private queue for notifications
    stompClient!.subscribe(
      destination: '/user/queue/notifications',
      callback: (frame) {
        if (frame.body != null) {
          final newNotification = NotificationModel.fromJson(jsonDecode(frame.body!));
          
          _notifications.insert(0, newNotification); // Add to top of the list
          _unreadCount++;
          notifyListeners(); // Tell the UI to update
        }
      },
    );
    print("NotificationService: Connected and subscribed to notifications.");
    // Fetch initial data after connecting
    fetchNotifications();
    fetchUnreadCount();
  }

  Future<void> fetchNotifications() async {
   // This calls the getUserNotifications function you already created in ApiService
  final response = await _apiService.getUserNotifications();
    if (response.status == 'OK' && response.data != null) {
      _notifications = response.data!;
      notifyListeners(); // This tells the UI to rebuild with the new list
    }
  }

  Future<void> fetchUnreadCount() async {
    // This calls the getUnreadCount function you already created in ApiService
    final response = await _apiService.getUnreadCount();
    if (response.status == 'OK' && response.data != null) {
      _unreadCount = response.data!;
      notifyListeners(); // This tells the UI to rebuild the badge
    }
  }

  Future<void> markAsRead(String notificationId) async {
    // This will be a new method in your ApiService to call PATCH /api/notifications/{id}/read
    await _apiService.markNotificationAsRead(notificationId);
    // After marking as read, refresh the data
    fetchUnreadCount();
    final notif = _notifications.firstWhere((n) => n.id == notificationId);
    notif.read = true;
    notifyListeners();
  }

  void disconnect() {
    stompClient?.deactivate();
  }

Future<void> markAllAsRead() async {
    // Tell the API to mark them all as read in the database
    final response = await _apiService.markAllNotificationsAsRead();
    
    if (response.status == 'OK') {
      // If successful, update the local state immediately
      _unreadCount = 0;
      for (var notification in _notifications) {
        notification.read = true;
      }
      // Tell the UI (the badge and the list) to update
      notifyListeners();
    }
  }
}