import 'package:flutter/material.dart';
import 'package:myfschools/constants/app_colors.dart';

class WeeklyScheduleItem {
  final int dayOfWeek;
  final int periodNo;
  final String subjectName;
  final String subjectShortName;
  final String room;
  final String startTime;
  final String endTime;
  final String teacherName;

  WeeklyScheduleItem({
    required this.dayOfWeek,
    required this.periodNo,
    required this.subjectName,
    required this.subjectShortName,
    required this.room,
    required this.startTime,
    required this.endTime,
    required this.teacherName,
  });

  factory WeeklyScheduleItem.fromJson(Map<String, dynamic> json) {
    return WeeklyScheduleItem(
      dayOfWeek: json['dayOfWeek'] ?? 0,
      periodNo: json['periodNo'] ?? 0,
      subjectName: json['subjectName'] ?? '',
      subjectShortName: json['subjectShortName'] ?? '',
      room: json['room'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      teacherName: json['teacherName'] ?? '',
    );
  }

  Color get color {
    // Logic gán màu dựa trên môn học hoặc tiết học
    if (periodNo <= 5) return AppColors.orange;
    return AppColors.navyMid;
  }
}
