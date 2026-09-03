import 'package:flutter/material.dart';

class UserInfo {
  final String name;
  final String className;
  final String id;
  final double gpa;
  final double attendance;
  final int pendingForms;
  final List<String> roles;
  final String? studentCode;
  final bool isHomeroom; // true = GVCN, false = GVBM
  final String? homeroomClassName;
  final List<TeachingSubject> teachingSubjects;

  const UserInfo({
    required this.name,
    required this.className,
    required this.id,
    required this.gpa,
    required this.attendance,
    required this.pendingForms,
    this.roles = const [],
    this.studentCode,
    this.isHomeroom = false,
    this.homeroomClassName,
    this.teachingSubjects = const [],
  });
}

/// Môn/lớp mà GV đang dạy
class TeachingSubject {
  final int id;
  final String subjectName;
  final String className;

  const TeachingSubject({required this.id, required this.subjectName, required this.className});

  factory TeachingSubject.fromJson(Map<String, dynamic> json) => TeachingSubject(
    id: json['id'] ?? 0,
    subjectName: json['subjectName'] ?? '',
    className: json['className'] ?? '',
  );
}

class ScheduleItem {
  final String period;
  final String time;
  final String subject;
  final String room;
  final String teacher;
  final Color color;

  const ScheduleItem({
    required this.period,
    required this.time,
    required this.subject,
    required this.room,
    required this.teacher,
    required this.color,
  });
}

class NoticeItem {
  final String title;
  final String tag;
  final Color tagColor;

  const NoticeItem({
    required this.title,
    required this.tag,
    required this.tagColor,
  });

  factory NoticeItem.fromJson(Map<String, dynamic> json) {
    final type = json['notiType'] ?? 'he_thong';
    String label = 'Hệ thống';
    Color color = const Color(0xFF0D174C); // Navy gốc của AppColors

    switch (type) {
      case 'hoc_vu':
        label = 'Học vụ';
        color = const Color(0xFFF26F21); // Cam FPT
        break;
      case 'su_kien':
        label = 'Sự kiện';
        color = const Color(0xFF82C341); // Xanh lá FPT
        break;
      case 'tai_chinh':
        label = 'Tài chính';
        color = Colors.redAccent;
        break;
    }

    return NoticeItem(
      title: json['title'] ?? 'Thông báo mới',
      tag: label,
      tagColor: color,
    );
  }
}

class FeatureItem {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;

  const FeatureItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });
}