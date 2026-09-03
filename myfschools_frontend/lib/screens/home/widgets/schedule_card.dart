import 'package:flutter/material.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/models/home_models.dart' ;
import 'package:myfschools/constants/section_type.dart';


class ScheduleCard extends StatelessWidget {
  final List<ScheduleItem> items;
  final VoidCallback? onSeeMore;
  const ScheduleCard({super.key, required this.items, this.onSeeMore});

  @override
  Widget build(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle('Lịch hôm nay'),
            TextButton(
              onPressed: onSeeMore,
              child: const Text('Xem thêm →',
                  style: TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // Sửa BoxShadow thành bóng màu Navy cực nhạt & lan toả lớn
            boxShadow: [
              BoxShadow(
                  color: AppColors.navy.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final s = items[i];
              return Column(
                children: [
                  _InteractiveScheduleItem(s: s),
                  if (i < items.length - 1)
                    const Divider(height: 1, color: AppColors.border, indent: 16, endIndent: 16),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _InteractiveScheduleItem extends StatefulWidget {
  final ScheduleItem s;
  const _InteractiveScheduleItem({required this.s});

  @override
  State<_InteractiveScheduleItem> createState() => _InteractiveScheduleItemState();
}

class _InteractiveScheduleItemState extends State<_InteractiveScheduleItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.fastOutSlowIn,
        child: Container(
          color: Colors.transparent, // Bắt sự kiện Tap trên toàn Row
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              // Color bar
              Container(width: 3, height: 40, decoration: BoxDecoration(color: widget.s.color, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 12),
              // Period + time
              SizedBox(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.s.period, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(widget.s.time, style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Subject + teacher
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.s.subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('${widget.s.teacher} · ${widget.s.room}', style: const TextStyle(fontSize: 11, color: AppColors.textSub)),
                  ],
                ),
              ),
              // Giả lập trạng thái lớp đang học
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }
}