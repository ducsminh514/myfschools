import 'package:flutter/material.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/models/home_models.dart' ;
import 'package:myfschools/constants/section_type.dart';


class NoticeCard extends StatelessWidget {
  final List<NoticeItem> items;
  const NoticeCard({super.key, required this.items});

  @override
  Widget build(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle('Thông báo'),
            TextButton(
              onPressed: () {},
              child: const Text('Tất cả →',
                  style: TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            // Áp dụng viền Glow siêu nhẹ
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final n = items[i];
              return Column(
                children: [
                  _InteractiveNoticeItem(
                    n: n,
                    isFirst: i == 0,
                    isLast: i == items.length - 1,
                  ),
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

class _InteractiveNoticeItem extends StatefulWidget {
  final NoticeItem n;
  final bool isFirst;
  final bool isLast;

  const _InteractiveNoticeItem({
    required this.n,
    required this.isFirst,
    required this.isLast,
  });

  @override
  State<_InteractiveNoticeItem> createState() => _InteractiveNoticeItemState();
}

class _InteractiveNoticeItemState extends State<_InteractiveNoticeItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.isFirst
        ? const BorderRadius.vertical(top: Radius.circular(16))
        : widget.isLast
        ? const BorderRadius.vertical(bottom: Radius.circular(16))
        : BorderRadius.zero;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.fastOutSlowIn,
        child: Container(
          // Trùm nền trong suốt để bắt trọn Hit-box tương tác của ngón tay
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: borderRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.n.title,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: widget.n.tagColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(widget.n.tag,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: widget.n.tagColor)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: AppColors.textLight, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}