import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/controllers/auth_controller.dart';
import 'package:myfschools/controllers/schedule_controller.dart';
import 'package:myfschools/models/schedule_models.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:intl/intl.dart';

/// TKB dạng bảng + tab Hôm nay + chuyển tuần
class WeeklySchedulePage extends StatefulWidget {
  const WeeklySchedulePage({super.key});

  @override
  State<WeeklySchedulePage> createState() => _WeeklySchedulePageState();
}

class _WeeklySchedulePageState extends State<WeeklySchedulePage>
    with SingleTickerProviderStateMixin {
  late final ScheduleController _scheduleCtrl;
  late final bool _isTeacher;
  late final TabController _tabController;

  // Số tuần offset tính từ tuần hiện tại (0 = tuần này, -1 = tuần trước, +1 = tuần sau)
  int _weekOffset = 0;

  // Ngày đầu tuần (Thứ 2) của tuần đang xem
  late DateTime _weekStart;

  static const _dayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

  @override
  void initState() {
    super.initState();
    _scheduleCtrl = Get.put(ScheduleController());
    _isTeacher = Get.find<AuthController>().currentUser.value?.roles.contains('teacher') ?? false;

    // Tab 0 = "Hôm nay" theo danh sách, Tab 1..6 = T2..T7
    final todayIdx = _todayTabIndex(); // 1-6 hoặc 0 nếu cuối tuần
    _tabController = TabController(
      length: 7, // Hôm nay + T2..T7
      vsync: this,
      initialIndex: todayIdx > 0 ? todayIdx : 1,
    );
    _updateWeekStart();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateWeekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _weekStart = DateTime(monday.year, monday.month, monday.day)
        .add(Duration(days: _weekOffset * 7));
  }

  void _changeWeek(int delta) {
    setState(() {
      _weekOffset += delta;
      _updateWeekStart();
    });
  }

  void _resetToThisWeek() {
    setState(() {
      _weekOffset = 0;
      _updateWeekStart();
    });
  }

  // Ngày cụ thể của từng cột (T2..T7)
  DateTime _dayDate(int colIndex) => _weekStart.add(Duration(days: colIndex));

  // Tab index của ngày hôm nay (1=T2..6=T7), 0 nếu cuối tuần/ngoài phạm vi
  int _todayTabIndex() {
    final wd = DateTime.now().weekday; // 1=Mon..7=Sun
    if (wd >= 1 && wd <= 6) return wd; // T2..T7 → tab 1..6
    return 0; // Chủ nhật → Hôm nay tab
  }

  String _formatWeekHeader() {
    final end = _weekStart.add(const Duration(days: 5));
    final fmt = DateFormat('dd/MM');
    return '${fmt.format(_weekStart)} – ${fmt.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        elevation: 0,
        title: Obx(() => Text(
          _isTeacher
              ? 'Lịch dạy - ${_scheduleCtrl.className.value}'
              : 'Lịch học - Lớp ${_scheduleCtrl.className.value}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        )),
        // Nút chuyển tuần
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(88),
          child: Column(
            children: [
              // Row chuyển tuần
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => _changeWeek(-1),
                      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 28),
                      tooltip: 'Tuần trước',
                    ),
                    GestureDetector(
                      onTap: _weekOffset != 0 ? _resetToThisWeek : null,
                      child: Column(
                        children: [
                          Text(
                            _weekOffset == 0 ? 'Tuần này' : (_weekOffset < 0 ? '${_weekOffset.abs()} tuần trước' : '$_weekOffset tuần sau'),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _formatWeekHeader(),
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          if (_weekOffset != 0)
                            Text(
                              'Bấm để về tuần này',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _changeWeek(1),
                      icon: const Icon(Icons.chevron_right, color: Colors.white, size: 28),
                      tooltip: 'Tuần sau',
                    ),
                  ],
                ),
              ),
              // TabBar
              TabBar(
                controller: _tabController,
                isScrollable: false,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 12),
                tabs: [
                  const Tab(text: 'Hôm nay'),
                  ..._dayNames.map((d) => Tab(text: d)),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        return TabBarView(
          controller: _tabController,
          children: [
            // Tab 0: Hôm nay — dạng danh sách với trạng thái tiết
            _buildTodayTab(),
            // Tab 1..6: T2..T7
            ...List.generate(6, (index) {
              final day = index + 2;
              final items = _scheduleCtrl.getSchedulesByDay(day);
              return Skeletonizer(
                enabled: _scheduleCtrl.isLoading.value,
                child: items.isEmpty && !_scheduleCtrl.isLoading.value
                    ? _buildEmptyState()
                    : _buildDaySchedule(items, date: _dayDate(index)),
              );
            }),
          ],
        );
      }),
    );
  }

  // ── Tab Hôm nay ────────────────────────────────────────────────────────────

  Widget _buildTodayTab() {
    final now = DateTime.now();
    final todayDow = now.weekday + 1; // Dart: 1=Mon → dayOfWeek 2=Mon
    final todayItems = _scheduleCtrl.getSchedulesByDay(todayDow);

    if (_scheduleCtrl.isLoading.value) {
      return const Center(child: CircularProgressIndicator(color: AppColors.orange));
    }

    if (todayItems.isEmpty) {
      return _buildEmptyState(message: 'Hôm nay không có tiết học nào 🎉');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: todayItems.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => _buildTodayCard(todayItems[i], now),
    );
  }

  Widget _buildTodayCard(WeeklyScheduleItem item, DateTime now) {
    // Parse giờ từ "07:15" → TimeOfDay
    final startParts = item.startTime.split(':');
    final endParts = item.endTime.split(':');
    final startDt = DateTime(now.year, now.month, now.day,
        int.tryParse(startParts.first) ?? 0, int.tryParse(startParts.last) ?? 0);
    final endDt = DateTime(now.year, now.month, now.day,
        int.tryParse(endParts.first) ?? 0, int.tryParse(endParts.last) ?? 0);

    String statusLabel;
    Color statusColor;
    IconData statusIcon;

    if (now.isBefore(startDt)) {
      statusLabel = 'Sắp diễn ra';
      statusColor = Colors.orange;
      statusIcon = Icons.schedule_outlined;
    } else if (now.isAfter(endDt)) {
      statusLabel = 'Đã xong';
      statusColor = Colors.grey;
      statusIcon = Icons.check_circle_outline;
    } else {
      statusLabel = 'Đang học';
      statusColor = AppColors.green;
      statusIcon = Icons.radio_button_checked;
    }

    final isMorning = item.periodNo <= 5;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: statusLabel == 'Đang học'
            ? Border.all(color: AppColors.green, width: 1.5)
            : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Cột tiết
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isMorning ? AppColors.orangeSoft : AppColors.navyLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Tiết', style: TextStyle(fontSize: 9, color: isMorning ? AppColors.orange : AppColors.navyMid)),
                  Text('${item.periodNo}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isMorning ? AppColors.orange : AppColors.navyMid)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Nội dung
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(item.subjectName,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 11, color: statusColor),
                            const SizedBox(width: 4),
                            Text(statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${item.startTime} – ${item.endTime}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Icon(Icons.room_outlined, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(item.room, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(item.teacherName, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab tuần ───────────────────────────────────────────────────────────────

  Widget _buildDaySchedule(List<WeeklyScheduleItem> items, {DateTime? date}) {
    final displayItems = items.isEmpty
        ? List.generate(5, (i) => WeeklyScheduleItem(
            dayOfWeek: 0, periodNo: i + 1,
            subjectName: 'Loading Name', subjectShortName: 'Load',
            room: 'P.000', startTime: '07:00', endTime: '07:45', teacherName: 'Teacher'))
        : items;

    return Column(
      children: [
        // Tiêu đề ngày
        if (date != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.white,
            child: Center(
              child: Text(
                DateFormat('EEEE, dd/MM/yyyy', 'vi').format(date),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.navyMid),
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: displayItems.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final item = displayItems[i];
              final isMorning = item.periodNo <= 5;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        decoration: BoxDecoration(
                          color: isMorning ? AppColors.orangeSoft : AppColors.navyLight,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Tiết', style: TextStyle(fontSize: 10, color: isMorning ? AppColors.orange : AppColors.navyMid)),
                            Text('${item.periodNo}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isMorning ? AppColors.orange : AppColors.navyMid)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item.subjectName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.bg, borderRadius: BorderRadius.circular(4)),
                                    child: Text(item.room, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.navyMid)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('${item.startTime} - ${item.endTime}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(item.teacherName, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({String message = 'Không có lịch học cho ngày này'}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        ],
      ),
    );
  }
}
