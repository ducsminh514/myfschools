import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/controllers/grades_controller.dart';
import 'package:myfschools/models/grade_models.dart';
import 'package:skeletonizer/skeletonizer.dart';

class GradesPage extends StatelessWidget {
  final int? preselectedClassSubjectId;
  const GradesPage({super.key, this.preselectedClassSubjectId});

  @override
  Widget build(BuildContext context) {
    final gradesCtrl = Get.put(GradesController());

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Bảng điểm HK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final data = gradesCtrl.semesterGrades.value;
        final grades = data?.grades ?? [];

        return Skeletonizer(
          enabled: gradesCtrl.isLoading.value,
          child: Column(
            children: [
              // Header Card
              _buildHeader(data),
              
              // Grades List
              Expanded(
                child: grades.isEmpty && !gradesCtrl.isLoading.value
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: grades.isEmpty ? 5 : grades.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        if (grades.isEmpty) {
                          // Mock item for Skeletonizer
                          return _buildGradeCard(GradeItem(
                            subjectName: 'Loading Subject', subjectShortName: 'Load', 
                            scores15m: [0, 0], scores1h: [0], gpaSubject: 0));
                        }
                        return _buildGradeCard(grades[i]);
                      },
                    ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHeader(SemesterGrades? data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data?.studentName ?? 'Đang tải...', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Lớp: ${data?.className ?? '---'}', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                const Text('GPA', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(
                  data?.overallGpa?.toStringAsFixed(2) ?? '0.0',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.orange),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('Chưa có dữ liệu điểm học kỳ này', style: TextStyle(color: Colors.grey)));
  }

  Widget _buildGradeCard(GradeItem item) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(item.subjectName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: item.labelColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(
                  item.labelText,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: item.labelColor),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildScoreColumn('Miệng', item.scoreOral?.toString() ?? '-'),
              _buildScoreColumn('15p', item.scores15m.isEmpty ? '-' : item.scores15m.join(', ')),
              _buildScoreColumn('1 Tiết', item.scores1h.isEmpty ? '-' : item.scores1h.join(', ')),
              _buildScoreColumn('Thi', item.scoreFinal?.toString() ?? '-'),
              _buildScoreColumn('Phẩy', item.gpaSubject?.toStringAsFixed(1) ?? '-', isFocus: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn(String label, String value, {bool isFocus = false}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isFocus ? 16 : 13,
            fontWeight: isFocus ? FontWeight.bold : FontWeight.w500,
            color: isFocus ? AppColors.orange : AppColors.navyMid,
          ),
        ),
      ],
    );
  }
}
