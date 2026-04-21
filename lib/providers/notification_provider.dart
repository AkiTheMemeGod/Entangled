import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notification_model.dart';
import 'auth_provider.dart';

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value(const <NotificationModel>[]);
  }
  return ref.watch(firestoreServiceProvider).streamNotifications(user.id);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifications =
      ref.watch(notificationsProvider).value ?? const <NotificationModel>[];
  return notifications.where((item) => !item.isRead).length;
});
