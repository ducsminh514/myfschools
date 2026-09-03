import 'package:flutter/material.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/models/home_models.dart' ;
import 'package:myfschools/constants/section_type.dart';
class FeatureGrid extends StatelessWidget {
  final List<FeatureItem> items;
  final Function(FeatureItem)? onTap;
  const FeatureGrid({super.key, required this.items, this.onTap});

  @override
  Widget build(BuildContext ctx) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Chức năng'),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.95,
          ),
          itemBuilder: (ctx, i) => _FeatureCard(
            item: items[i],
            onTap: onTap,
          ),
        ),
      ],
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final FeatureItem item;
  final Function(FeatureItem)? onTap;
  const _FeatureCard({required this.item, this.onTap});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext ctx) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (widget.onTap != null) widget.onTap!(widget.item);
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0, // Micro-animation lún nút thần thánh
        duration: const Duration(milliseconds: 150),
        curve: Curves.fastOutSlowIn,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                // Đổ bóng Glow rất nhạt tệp với tone màu của Item cho cảm giác Premium Clean
                color: widget.item.color.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  color: widget.item.bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.item.icon, color: widget.item.color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                widget.item.label,
                style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}