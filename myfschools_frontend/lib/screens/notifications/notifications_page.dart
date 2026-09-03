import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../constants/app_colors.dart';
import '../../controllers/notifications_controller.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final notiCtrl = Get.put(NotificationsController());

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('Thông báo', style: TextStyle(color: AppColors.navyMid, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.navyMid, size: 20),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all, color: AppColors.navyMid),
            onPressed: () => notiCtrl.markAllAsRead(),
            tooltip: 'Đánh dấu tất cả đã đọc',
          )
        ],
      ),
      body: Obx(() {
        if (notiCtrl.isLoading.value && notiCtrl.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notiCtrl.notifications.isEmpty) {
          return const Center(child: Text('Bạn chưa có thông báo nào.', style: TextStyle(color: Colors.grey)));
        }

        return RefreshIndicator(
          onRefresh: () => notiCtrl.fetchNotifications(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notiCtrl.notifications.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, index) {
              final noti = notiCtrl.notifications[index];
              return GestureDetector(
                onTap: () => notiCtrl.navigateToDetail(noti),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: noti.isRead ? Colors.white : Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: noti.isRead ? null : Border.all(color: Colors.blue.withOpacity(0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getIconColor(noti.notiType).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_getIcon(noti.notiType), color: _getIconColor(noti.notiType), size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    noti.title,
                                    style: TextStyle(
                                      fontWeight: noti.isRead ? FontWeight.w600 : FontWeight.bold,
                                      fontSize: 15,
                                      color: AppColors.navyMid,
                                    ),
                                  ),
                                ),
                                if (!noti.isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  )
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              noti.body,
                              style: const TextStyle(color: AppColors.navyLight, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatTime(noti.createdAt),
                              style: const TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'FormStatus': return Icons.assignment_turned_in;
      case 'Grade': return Icons.grade;
      case 'Attendance': return Icons.calendar_today;
      default: return Icons.notifications;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'FormStatus': return Colors.orange;
      case 'Grade': return Colors.green;
      case 'Attendance': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${date.day}/${date.month}/${date.year}';
  }
}
