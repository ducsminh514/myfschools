import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/attendance_controller.dart';
import '../../controllers/home_controller.dart';
import 'package:intl/intl.dart';

/// GVCN: chọn tiết → xem DS học sinh → điểm danh → submit
class AttendanceSheetPage extends StatefulWidget {
  const AttendanceSheetPage({super.key});

  @override
  State<AttendanceSheetPage> createState() => _AttendanceSheetPageState();
}

class _AttendanceSheetPageState extends State<AttendanceSheetPage> {
  final AttendanceController _ctrl = Get.put(AttendanceController());
  final _homeCtrl = Get.find<HomeController>();

  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _schedules = [];
  int? _selectedScheduleId;
  bool _loadingSchedules = true;
  String? _selectedClassName;
  String? _selectedSubjectName;

  @override
  void initState() {
    super.initState();
    _loadSchedulesFromHome();
  }

  String get _dateStr =>
      '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

  String get _dateDisplay =>
      DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate);

  /// Lấy lịch dạy từ HomeController (đã fetch sẵn) — không gọi API lần 2
  void _loadSchedulesFromHome() {
    final scheduleItems = _homeCtrl.todaySchedule;
    // Convert ScheduleItem to Map to keep the existing flow
    // Cần schedule id — dùng index tạm nếu không có id trong ScheduleItem
    // Vì HomeController ScheduleItem không chứa id, ta cần lấy raw data trực tiếp
    _fetchSchedulesRaw();
  }

  /// Fetch raw schedule data (cần schedule.id cho API điểm danh)
  Future<void> _fetchSchedulesRaw() async {
    setState(() => _loadingSchedules = true);
    try {
      final resp = await _homeCtrl.fetchScheduleRaw();
      if (resp != null) {
        setState(() {
          _schedules = resp;
        });
      }
    } catch (_) {}
    setState(() => _loadingSchedules = false);
  }

  void _selectScheduleAndLoad(Map<String, dynamic> schedule) {
    setState(() {
      _selectedScheduleId = schedule['id'];
      // BE: GV dashboard trả className qua 'teacherName' field (dòng 195 HomeController)
      _selectedClassName = schedule['teacherName'] ?? '';
      _selectedSubjectName = schedule['subjectName'] ?? '';
    });
    _ctrl.fetchClassSheet(_selectedScheduleId!, _dateStr);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      if (_selectedScheduleId != null) {
        _ctrl.fetchClassSheet(_selectedScheduleId!, _dateStr);
      }
    }
  }

  void _submitSheet() async {
    if (_selectedScheduleId == null) return;
    final ok = await _ctrl.submitAttendance(_selectedScheduleId!, _dateStr);
    if (ok) {
      // Quay lại sau khi submit thành công
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Điểm danh lớp',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          // Chọn ngày
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: Column(
        children: [
          // Ngày + Lớp
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.navy.withOpacity(0.05),
            child: Row(
              children: [
                const Icon(Icons.date_range, size: 16, color: AppColors.navyMid),
                const SizedBox(width: 8),
                Text(_dateDisplay,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyMid)),
                const Spacer(),
                if (_selectedClassName != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$_selectedClassName • $_selectedSubjectName',
                        style: const TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),

          // Chọn tiết (nếu chưa chọn)
          if (_selectedScheduleId == null) ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Chọn tiết học để điểm danh',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.navyMid)),
            ),
            const SizedBox(height: 12),
            if (_loadingSchedules)
              const Center(child: CircularProgressIndicator(color: AppColors.orange))
            else if (_schedules.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('Hôm nay không có tiết dạy', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _schedules.length,
                  itemBuilder: (_, i) {
                    final s = _schedules[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.orange.withOpacity(0.1),
                          child: Text('T${s['periodNo']}',
                              style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(s['subjectName'] ?? 'N/A',
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                            '${s['startTime']} - ${s['endTime']} • Phòng ${s['room'] ?? 'N/A'} • ${s['teacherName'] ?? ''}'),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.orange),
                        onTap: () => _selectScheduleAndLoad(s),
                      ),
                    );
                  },
                ),
              ),
          ],

          // DS học sinh (sau khi chọn tiết)
          if (_selectedScheduleId != null)
            Expanded(
              child: Obx(() {
                if (_ctrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.orange));
                }
                if (_ctrl.classSheet.isEmpty) {
                  return const Center(child: Text('Không có học sinh trong lớp'));
                }
                return Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Text('${_ctrl.classSheet.length} học sinh',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navyMid)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedScheduleId = null;
                                _selectedClassName = null;
                                _selectedSubjectName = null;
                              });
                              _ctrl.classSheet.clear();
                            },
                            icon: const Icon(Icons.swap_horiz, size: 16),
                            label: const Text('Đổi tiết', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    // List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _ctrl.classSheet.length,
                        itemBuilder: (_, i) {
                          final student = _ctrl.classSheet[i];
                          final status = student['status'] ?? 'present';
                          return _StudentAttendanceCard(
                            name: student['studentName'] ?? '',
                            code: student['studentCode'] ?? '',
                            status: status,
                            note: student['note'],
                            onStatusChanged: (newStatus) {
                              _ctrl.updateStudentStatus(student['studentId'], newStatus);
                            },
                          );
                        },
                      ),
                    ),
                    // Submit button
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Obx(() => SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _ctrl.isSubmitting.value ? null : _submitSheet,
                          icon: _ctrl.isSubmitting.value
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.check_circle, color: Colors.white),
                          label: Text(
                            _ctrl.isSubmitting.value ? 'Đang lưu...' : 'Lưu điểm danh',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      )),
                    ),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _StudentAttendanceCard extends StatelessWidget {
  final String name, code;
  final String status;
  final String? note;
  final ValueChanged<String> onStatusChanged;

  const _StudentAttendanceCard({
    required this.name,
    required this.code,
    required this.status,
    this.note,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.navyMid.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name.split(' ').last[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.navyMid, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          // Name + Code
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(code, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          // Status chips
          _StatusChip(label: 'CM', isActive: status == 'present', color: Colors.green,
              onTap: () => onStatusChanged('present')),
          const SizedBox(width: 4),
          _StatusChip(label: 'V', isActive: status == 'absent', color: Colors.red,
              onTap: () => onStatusChanged('absent')),
          const SizedBox(width: 4),
          _StatusChip(label: 'M', isActive: status == 'late', color: Colors.orange,
              onTap: () => onStatusChanged('late')),
          const SizedBox(width: 4),
          _StatusChip(label: 'P', isActive: status == 'excused', color: Colors.blue,
              onTap: () => onStatusChanged('excused')),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: isActive ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? color : color.withOpacity(0.3), width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
