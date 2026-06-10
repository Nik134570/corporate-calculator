import 'package:calculator/core/api/api_client.dart';
import 'package:calculator/features/notifications/data/models/notification_model.dart';

class NotificationRepository {
  final ApiClient _api;
  NotificationRepository(this._api);

  Future<List<NotificationModel>> getAll() async {
    final response = await _api.dio.get('/notifications');
    final data = response.data['data'] as List;
    return data.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _api.dio.get('/notifications');
    return response.data['unreadCount'] as int? ?? 0;
  }

  Future<void> markAllRead() async {
    await _api.dio.patch('/notifications/read-all');
  }

  Future<void> markRead(String id) async {
    await _api.dio.patch('/notifications/$id/read');
  }
}
