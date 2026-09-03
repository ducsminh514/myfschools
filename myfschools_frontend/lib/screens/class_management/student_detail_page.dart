import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/class_management_controller.dart';
import 'package:skeletonizer/skeletonizer.dart';

class StudentDetailPage extends StatelessWidget {
  final int studentId;
  const StudentDetailPage({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ClassManagementController>();
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Obx(() {
        final data = ctrl.studentDetail.value;
        final isLoading = ctrl.isLoadingDetail.value;

        return Skeletonizer(
          enabled: isLoading,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.orange, Color(0xFFE8651A)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(
                              ((data['fullName'] as String?) ?? 'N').isNotEmpty
                                  ? ((data['fullName'] as String?) ?? 'N')[0].toUpperCase()
                                  : 'N',
                              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(data['fullName'] ?? 'Đang tải...',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                          Text(data['studentCode'] ?? '',
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Thông tin cá nhân ──
                      _sectionTitle('Thông tin cá nhân', Icons.person_outline),
                      _infoCard([
                        _infoRow('Họ tên', data['fullName'] ?? '---'),
                        _infoRow('Mã HS', data['studentCode'] ?? '---'),
                        _infoRow('Giới tính', data['gender'] == 'male' ? 'Nam' : data['gender'] == 'female' ? 'Nữ' : '---'),
                        _infoRow('Ngày sinh', _formatDate(data['birthDate'])),
                        _infoRow('Địa chỉ', data['address'] ?? '---'),
                        _infoRow('SĐT', data['phone'] ?? '---'),
                      ]),

                      const SizedBox(height: 16),

                      // ── Phụ huynh ──
                      _sectionTitle('Thông tin phụ huynh', Icons.family_restroom),
                      _infoCard([
                        _infoRow('Họ tên PH', data['parentName'] ?? '---'),
                        _infoRow('SĐT PH', data['parentPhone'] ?? '---'),
                        _infoRow('Email PH', data['parentEmail'] ?? '---'),
                      ]),

                      const SizedBox(height: 16),

                      // ── Học lực ──
                      _sectionTitle('Học lực', Icons.bar_chart_rounded),
                      _gpaCard(data),
                      const SizedBox(height: 8),
                      _buildGradesTable(data),

                      const SizedBox(height: 16),

                      // ── Chuyên cần ──
                      _sectionTitle('Chuyên cần', Icons.check_circle_outline),
                      _attendanceCard(data),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navyMid, size: 20),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navyDark,
          )),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textLight))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _gpaCard(Map<String, dynamic> data) {
    final gpa = (data['gpa'] ?? 0).toDouble();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: gpa >= 8.0 ? AppColors.greenLight : gpa >= 6.5 ? AppColors.orangeSoft : Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(
              gpa.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                color: gpa >= 8.0 ? AppColors.green : gpa >= 6.5 ? AppColors.orange : Colors.red,
              ),
            )),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('GPA Học kỳ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(
                gpa >= 8.0 ? 'Giỏi' : gpa >= 6.5 ? 'Khá' : gpa >= 5.0 ? 'Trung bình' : 'Yếu',
                style: TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGradesTable(Map<String, dynamic> data) {
    final grades = (data['subjectGrades'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (grades.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: const Center(child: Text('Chưa có điểm', style: TextStyle(color: AppColors.textLight))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 14,
          headingRowHeight: 36,
          dataRowMinHeight: 32,
          dataRowMaxHeight: 36,
          headingTextStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.navyDark),
          dataTextStyle: const TextStyle(fontSize: 11, color: AppColors.textDark),
          columns: const [
            DataColumn(label: Text('Môn')),
            DataColumn(label: Text('Miệng')),
            DataColumn(label: Text('15p')),
            DataColumn(label: Text('1 tiết')),
            DataColumn(label: Text('Cuối kỳ')),
            DataColumn(label: Text('TBM')),
          ],
          rows: grades.map((g) => DataRow(cells: [
            DataCell(SizedBox(width: 70, child: Text(g['subjectName'] ?? '', overflow: TextOverflow.ellipsis))),
            DataCell(Text(_score(g['scoreOral']))),
            DataCell(Text(_score(g['score15m1']))),
            DataCell(Text(_score(g['score1h1']))),
            DataCell(Text(_score(g['scoreFinal']))),
            DataCell(Text(_score(g['gpaSubject']), style: const TextStyle(fontWeight: FontWeight.w600))),
          ])).toList(),
        ),
      ),
    );
  }

  Widget _attendanceCard(Map<String, dynamic> data) {
    final total = data['totalSessions'] ?? 0;
    final present = data['presentSessions'] ?? 0;
    final absent = data['absentSessions'] ?? 0;
    final rate = data['attendanceRate'] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _attendanceStat('Tổng', '$total', AppColors.navyMid),
              _attendanceStat('Có mặt', '$present', AppColors.green),
              _attendanceStat('Vắng', '$absent', Colors.red),
              _attendanceStat('Tỉ lệ', '$rate%', rate >= 80 ? AppColors.green : Colors.red),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: total > 0 ? present.toDouble() / total.toDouble() : 0,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(rate >= 80 ? AppColors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textLight)),
      ],
    );
  }

  String _score(dynamic score) {
    if (score == null) return '-';
    return (score as num).toStringAsFixed(1);
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '---';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr.toString();
    }
  }
}
