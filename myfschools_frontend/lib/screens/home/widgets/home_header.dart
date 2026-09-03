import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/models/home_models.dart' ;
import 'package:get/get.dart';
import 'package:myfschools/controllers/notifications_controller.dart';
import 'package:myfschools/screens/notifications/notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeHeader extends StatelessWidget {
  final UserInfo user;
  const HomeHeader({super.key, required this.user});

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navyMid],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('EEEE, dd/MM/yyyy', 'vi').format(DateTime.now()),
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                    const SizedBox(height: 3),
                    Text(
                      'Xin chào, ${user.name.split(' ').last} 👋',
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  // Bell
                  GestureDetector(
                    onTap: () => Get.to(() => const NotificationsPage(), transition: Transition.cupertino),
                    child: Stack(
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 20),
                        ),
                        Obx(() {
                          final notiCtrl = Get.find<NotificationsController>();
                          if (notiCtrl.unreadCount.value == 0) return const SizedBox.shrink();
                          return Positioned(
                            top: 6, right: 6,
                            child: Container(
                              width: 8, height: 8,
                              decoration: BoxDecoration(
                                color: AppColors.orange,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.navy, width: 1.5),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Avatar
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      user.name.split(' ').map((w) => w[0]).take(3).join(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Stat strip (Học sinh)
          if (user.roles.contains('student'))
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Row(
                children: [
                  _StatChip(label: 'GPA', value: user.gpa.toString(), bar: user.gpa / 10),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Chuyên cần', value: '${user.attendance.toInt()}%', bar: user.attendance / 100),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Đơn chờ', value: user.pendingForms.toString(), bar: user.pendingForms / 10),
                ],
              ),
            ),

          // Stat strip (Giáo viên)
          if (user.roles.contains('teacher'))
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Row(
                children: [
                  _StatChip(
                    label: user.isHomeroom ? 'Chủ nhiệm' : 'Vai trò',
                    value: user.isHomeroom ? (user.homeroomClassName ?? '---') : 'GVBM',
                    bar: 1.0,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(
                    label: 'Môn dạy',
                    value: user.teachingSubjects.length.toString(),
                    bar: user.teachingSubjects.length / 10,
                  ),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Đơn chờ', value: user.pendingForms.toString(), bar: user.pendingForms / 10),
                ],
              ),
            ),
        ],
      ),
    );
  }
}


class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final double bar; // 0.0 – 1.0

  const _StatChip({required this.label, required this.value, required this.bar});

  @override
  Widget build(BuildContext ctx) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 10)),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: bar.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: Colors.white.withOpacity(0.15),
                valueColor: const AlwaysStoppedAnimation(AppColors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}