import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/controllers/home_controller.dart';

class HomeBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HomeBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext ctx) {
    final isTeacher = Get.find<HomeController>().userInfo.value?.roles.contains('teacher') ?? false;
    final tabs = [
      (Icons.home_rounded,        'Trang chủ'),
      (Icons.chat_bubble_outline, 'Tin nhắn'),
      (Icons.calendar_today_outlined, isTeacher ? 'Lịch dạy' : 'Lịch học'),
      (Icons.person_outline,      'Cá nhân'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.orange,
        boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      padding: const EdgeInsets.only(top: 10, bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(tabs.length, (i) {
          final active = i == currentIndex;
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: active ? Colors.white.withOpacity(0.22) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tabs[i].$1, color: active ? Colors.white : Colors.white.withOpacity(0.6), size: 22),
                ),
                const SizedBox(height: 3),
                Text(
                  tabs[i].$2,
                  style: TextStyle(
                    fontSize: 10,
                    color: active ? Colors.white : Colors.white.withOpacity(0.6),
                    fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

