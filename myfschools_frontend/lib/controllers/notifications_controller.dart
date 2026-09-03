import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../services/api_client.dart';
import 'package:flutter/material.dart';

class NotificationsController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxInt unreadCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final response = await ApiClient().dio.get('notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        notifications.value = data.map((e) => NotificationModel.fromJson(e)).toList();
        _updateUnreadCount();
      }
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể lấy thông báo. Vui lòng kiểm tra kết nối mạng.',
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  Future<void> markAsRead(int id) async {
    try {
      final response = await ApiClient().dio.post('notifications/$id/read');
      if (response.statusCode == 200) {
        final index = notifications.indexWhere((n) => n.id == id);
        if (index != -1) {
          final oldNoti = notifications[index];
          notifications[index] = NotificationModel(
            id: oldNoti.id,
            title: oldNoti.title,
            body: oldNoti.body,
            notiType: oldNoti.notiType,
            refId: oldNoti.refId,
            refType: oldNoti.refType,
            isRead: true,
            createdAt: oldNoti.createdAt,
          );
          _updateUnreadCount();
        }
      }
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể đánh dấu đã đọc');
    }
  }

  void navigateToDetail(NotificationModel noti) {
    if (!noti.isRead) markAsRead(noti.id);
    
    // Logic điều hướng thông minh dựa trên NotiType
    if (noti.notiType == 'FormStatus' && noti.refType == 'Form') {
      // Nếu là thông báo về đơn từ, chuyển hướng sang trang Lịch sử đơn
      // (Trong tương lai có thể chuyển vào trang Chi tiết đơn cụ thể)
      Get.toNamed('/forms'); 
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final response = await ApiClient().dio.post('notifications/read-all');
      if (response.statusCode == 200) {
        notifications.value = notifications.map((n) {
          return NotificationModel(
            id: n.id,
            title: n.title,
            body: n.body,
            notiType: n.notiType,
            refId: n.refId,
            refType: n.refType,
            isRead: true,
            createdAt: n.createdAt,
          );
        }).toList();
        _updateUnreadCount();
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }
}
