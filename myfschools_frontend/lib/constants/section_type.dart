import 'package:flutter/material.dart';
import 'package:myfschools/constants/app_colors.dart';


class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text);

  @override
  Widget build(BuildContext ctx) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary, letterSpacing: 1,
    ),
  );
}