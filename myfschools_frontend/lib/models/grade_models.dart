import 'package:flutter/material.dart';
import 'package:myfschools/constants/app_colors.dart';

class GradeItem {
  final String subjectName;
  final String subjectShortName;
  final double? scoreOral;
  final List<double> scores15m;
  final List<double> scores1h;
  final double? scoreFinal;
  final double? gpaSubject;
  final String? gradeLabel;

  GradeItem({
    required this.subjectName,
    required this.subjectShortName,
    this.scoreOral,
    required this.scores15m,
    required this.scores1h,
    this.scoreFinal,
    this.gpaSubject,
    this.gradeLabel,
  });

  factory GradeItem.fromJson(Map<String, dynamic> json) {
    return GradeItem(
      subjectName: json['subjectName'] ?? '',
      subjectShortName: json['subjectShortName'] ?? '',
      scoreOral: (json['scoreOral'] as num?)?.toDouble(),
      scores15m: (json['scores15m'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      scores1h: (json['scores1h'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      scoreFinal: (json['scoreFinal'] as num?)?.toDouble(),
      gpaSubject: (json['gpaSubject'] as num?)?.toDouble(),
      gradeLabel: json['gradeLabel'],
    );
  }

  Color get labelColor {
    switch (gradeLabel) {
      case 'Gioi': return AppColors.orange;
      case 'Kha':  return AppColors.navyMid;
      case 'TBinh': return Colors.grey;
      case 'Yeu':   return Colors.red;
      default:     return AppColors.textSub;
    }
  }

  String get labelText {
    switch (gradeLabel) {
      case 'Gioi': return 'Giỏi';
      case 'Kha':  return 'Khá';
      case 'TBinh': return 'Trình độ TB';
      case 'Yeu':   return 'Yếu';
      case 'Kem':   return 'Kém';
      default:     return '---';
    }
  }
}

class SemesterGrades {
  final String studentName;
  final String className;
  final List<GradeItem> grades;
  final double? overallGpa;

  SemesterGrades({
    required this.studentName,
    required this.className,
    required this.grades,
    this.overallGpa,
  });

  factory SemesterGrades.fromJson(Map<String, dynamic> json) {
    return SemesterGrades(
      studentName: json['studentName'] ?? '',
      className: json['className'] ?? '',
      overallGpa: (json['overallGpa'] as num?)?.toDouble(),
      grades: (json['grades'] as List?)
          ?.map((e) => GradeItem.fromJson(e))
          .toList() ?? [],
    );
  }
}
