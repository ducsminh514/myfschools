import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/controllers/attendance_controller.dart';

/// Màn hình xem lịch sử điểm danh cho Học sinh
class AttendanceHistoryPage extends StatelessWidget {
  const AttendanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(AttendanceController());

    // Fetch dữ liệu lần đầu khi trang mở — không dùng onInit để tránh gọi cả khi GV dùng controller này
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ctrl.myRecords.isEmpty) ctrl.fetchMyAttendance();
    });

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Lịch sử điểm danh',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.orange));
        }

        final summary = ctrl.summary.value;
        final records = ctrl.myRecords;

        return RefreshIndicator(
          color: AppColors.orange,
          onRefresh: ctrl.fetchMyAttendance,
          child: CustomScrollView(
            slivers: [
              // ── Summary Card ──
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.orange, AppColors.orangeSoft],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tổng kết', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(label: 'Có mặt', value: '${summary['present'] ?? 0}', color: Colors.white),
                          _StatItem(label: 'Vắng',   value: '${summary['absent'] ?? 0}',  color: Colors.amber.shade200),
                          _StatItem(label: 'Muộn',   value: '${summary['late'] ?? 0}',    color: Colors.orange.shade200),
                          _StatItem(label: 'Có phép',value: '${summary['excused'] ?? 0}', color: Colors.lightBlue.shade200),
                          _StatItem(label: 'Tỉ lệ',  value: '${summary['attendancePct'] ?? 0}%', color: Colors.white),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Danh sách bản ghi ──
              records.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Chưa có dữ liệu điểm danh', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _AttendanceCard(record: records[i]),
                        childCount: records.length,
                      ),
                    ),
            ],
          ),
        );
      }),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
      ],
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> record;
  const _AttendanceCard({required this.record});

  Color _statusColor(String status) {
    switch (status) {
      case 'present':  return Colors.green;
      case 'absent':   return Colors.red;
      case 'late':     return Colors.orange;
      case 'excused':  return Colors.blue;
      default:         return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'present':  return 'Có mặt';
      case 'absent':   return 'Vắng';
      case 'late':     return 'Muộn';
      case 'excused':  return 'Có phép';
      default:         return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = record['status'] ?? 'absent';
    final color  = _statusColor(status);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(
            status == 'present'
                ? Icons.check_circle_outline
                : status == 'late'
                    ? Icons.timer_outlined
                    : status == 'excused'
                        ? Icons.verified_outlined   // Có phép — xanh
                        : Icons.cancel_outlined,    // absent — đỏ
            color: color, size: 24,
          ),
        ),
        title: Text(record['subject'] ?? 'N/A',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
        subtitle: Text('Tiết ${record['period'] ?? '-'} • ${record['startTime'] ?? '--:--'} • ${record['date'] ?? ''}',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
          child: Text(_statusLabel(status),
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
