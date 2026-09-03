import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/class_management_controller.dart';
import 'student_detail_page.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ClassManagementPage extends GetView<ClassManagementController> {
  const ClassManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get.put chỉ tạo mới nếu chưa tồn tại, trả existing nếu đã put
    Get.put(ClassManagementController());
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Obx(() => Text(
          'Lớp ${controller.dashboard.value['className'] ?? '---'}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        )),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Obx(() => Skeletonizer(
        enabled: controller.isLoading.value,
        child: RefreshIndicator(
          onRefresh: () async {
            await controller.fetchDashboard();
            await controller.fetchStudents();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDashboard(controller),
                const SizedBox(height: 16),
                _buildStudentList(controller),
              ],
            ),
          ),
        ),
      )),
    );
  }

  // ── Dashboard tổng quan ──
  Widget _buildDashboard(ClassManagementController controller) {
    final d = controller.dashboard.value;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navyDark, AppColors.navyMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: AppColors.navyDark.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.school_outlined, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              Text(
                'Lớp ${d['className'] ?? '---'}',
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statCard('Sĩ số', '${d['totalStudents'] ?? 0}', Icons.people_outline),
              const SizedBox(width: 12),
              _statCard('Nam', '${d['maleCount'] ?? 0}', Icons.male),
              const SizedBox(width: 12),
              _statCard('Nữ', '${d['femaleCount'] ?? 0}', Icons.female),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('TBC GPA', '${d['averageGpa'] ?? 0}', Icons.bar_chart),
              const SizedBox(width: 12),
              _statCard('Chuyên cần', '${d['attendanceRate'] ?? 0}%', Icons.check_circle_outline),
              const SizedBox(width: 12),
              _statCard('Đơn chờ', '${d['pendingForms'] ?? 0}', Icons.assignment_late_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700,
            )),
            Text(label, style: TextStyle(
              color: Colors.white.withOpacity(0.7), fontSize: 10,
            )),
          ],
        ),
      ),
    );
  }

  // ── Danh sách học sinh ──
  Widget _buildStudentList(ClassManagementController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Danh sách học sinh',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyDark)),
              const Spacer(),
              Text('${controller.students.length} HS',
                style: TextStyle(fontSize: 13, color: AppColors.textLight)),
            ],
          ),
          const SizedBox(height: 12),
          if (controller.isLoadingStudents.value && controller.students.isEmpty)
            ...List.generate(5, (_) => _studentSkeleton())
          else if (controller.students.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Lớp chưa có học sinh', style: TextStyle(color: AppColors.textLight)),
            ))
          else
            ...controller.students.map((s) => _studentTile(s, controller)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _studentTile(Map<String, dynamic> s, ClassManagementController controller) {
    final gpa = (s['gpa'] ?? 0).toDouble();
    final attendance = s['attendanceRate'] ?? 0;
    final gender = s['gender'] == 'male' ? 'Nam' : 'Nữ';

    return GestureDetector(
      onTap: () {
        controller.fetchStudentDetail(s['studentId']);
        Get.to(() => StudentDetailPage(studentId: s['studentId']),
          transition: Transition.cupertino);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.navyLight,
              child: Text(
                (s['fullName'] ?? 'N')[0].toUpperCase(),
                style: const TextStyle(color: AppColors.navyDark, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            // Thông tin
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s['fullName'] ?? '', style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.navyDark,
                  )),
                  const SizedBox(height: 3),
                  Text('${s['studentCode'] ?? ''} · $gender',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                ],
              ),
            ),
            // GPA + Chuyên cần
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: gpa >= 8.0 ? AppColors.greenLight : gpa >= 6.5 ? AppColors.orangeSoft : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('GPA ${gpa.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: gpa >= 8.0 ? AppColors.green : gpa >= 6.5 ? AppColors.orange : Colors.red,
                    )),
                ),
                const SizedBox(height: 4),
                Text('$attendance%', style: TextStyle(
                  fontSize: 11, color: attendance >= 80 ? AppColors.green : Colors.red,
                )),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textLight, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _studentSkeleton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      height: 72,
    );
  }
}
