import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/controllers/clubs_controller.dart';
import 'package:myfschools/models/club_model.dart';
import 'package:myfschools/services/api_client.dart';

/// Màn hình quản lý CLB — chỉ dành cho Trưởng CLB (leader)
class ClubManagePage extends StatefulWidget {
  final ClubModel club;
  const ClubManagePage({super.key, required this.club});

  @override
  State<ClubManagePage> createState() => _ClubManagePageState();
}

class _ClubManagePageState extends State<ClubManagePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final ClubsController _ctrl = Get.find<ClubsController>();

  bool _loadingPending = true;
  List<ClubMemberModel> _pending = [];
  List<ClubMemberModel> _members = [];
  List<ClubSessionModel> _sessions = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadDetail();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() => _loadingPending = true);
    try {
      final resp = await ApiClient().dio.get('/clubs/${widget.club.id}');
      if (resp.statusCode == 200) {
        final data = Map<String, dynamic>.from(resp.data);
        final club = ClubModel.fromJson(data);
        setState(() {
          _members  = club.members;
          _sessions = club.sessions;
        });

        final pendingResp = await ApiClient().dio.get('/clubs/${widget.club.id}/pending-members');
        if (pendingResp.statusCode == 200) {
          setState(() {
            _pending = (pendingResp.data as List)
                .map((e) => ClubMemberModel.fromJson(Map<String, dynamic>.from(e)))
                .toList();
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingPending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Quản lý: ${widget.club.name}',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: 'Duyệt đơn${_pending.isNotEmpty ? " (${_pending.length})" : ""}'),
            const Tab(text: 'Thành viên'),
            const Tab(text: 'Lịch SH'),
          ],
        ),
      ),
      body: _loadingPending
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildPendingTab(),
                _buildMembersTab(),
                _buildSessionsTab(),
              ],
            ),
    );
  }

  // ── Tab 1: Duyệt đơn ─────────────────────────────────────────────────────

  Widget _buildPendingTab() {
    if (_pending.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 8),
            Text('Không có đơn chờ duyệt', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final m = _pending[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.orange.withOpacity(0.1),
                child: Text(m.name[0], style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (m.className != null)
                      Text(m.className!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('Gửi đơn: ${m.joinedAt}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nút duyệt
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline, color: AppColors.green),
                    tooltip: 'Duyệt',
                    onPressed: () async {
                      final ok = await _ctrl.approveMember(widget.club.id, m.id, true);
                      if (ok) _loadDetail();
                    },
                  ),
                  // Nút từ chối
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                    tooltip: 'Từ chối',
                    onPressed: () async {
                      final ok = await _ctrl.approveMember(widget.club.id, m.id, false);
                      if (ok) _loadDetail();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Tab 2: Thành viên ─────────────────────────────────────────────────────

  Widget _buildMembersTab() {
    if (_members.isEmpty) {
      return const Center(child: Text('Chưa có thành viên được duyệt', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _members.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = _members[i];
        final isLeader = m.role == 'leader';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: isLeader ? AppColors.orange.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
            child: Text(m.name[0], style: TextStyle(color: isLeader ? AppColors.orange : Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          title: Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('Từ ${m.joinedAt}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: isLeader
              ? const Text('👑', style: TextStyle(fontSize: 18))
              : PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'remove') {
                      final confirm = await _showConfirmDialog(
                          'Xoá thành viên', 'Bạn có chắc muốn xoá ${m.name} khỏi CLB?');
                      if (confirm == true) {
                        final ok = await _ctrl.removeMember(widget.club.id, m.id);
                        if (ok) _loadDetail();
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'remove',
                        child: Text('Xoá khỏi CLB', style: TextStyle(color: Colors.red))),
                  ],
                ),
        );
      },
    );
  }

  // ── Tab 3: Lịch sinh hoạt ─────────────────────────────────────────────────

  Widget _buildSessionsTab() {
    return Column(
      children: [
        // Nút thêm lịch
        Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddSessionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Thêm lịch sinh hoạt'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ),
        Expanded(
          child: _sessions.isEmpty
              ? const Center(child: Text('Chưa có lịch sinh hoạt', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: _sessions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final s = _sessions[i];
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                      ),
                      child: Row(
                        children: [
                          Container(width: 4, height: 40,
                              decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text(s.sessionAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                if (s.location != null)
                                  Text('📍 ${s.location}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () async {
                              final confirm = await _showConfirmDialog('Xoá lịch', 'Xoá lịch sinh hoạt "${s.title}"?');
                              if (confirm == true) {
                                try {
                                  await ApiClient().dio.delete('/clubs/${widget.club.id}/sessions/${s.id}');
                                  _loadDetail();
                                } catch (_) {}
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Xác nhận', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  Future<void> _showAddSessionDialog() async {
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime? pickedDate;
    TimeOfDay? pickedTime;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Thêm lịch sinh hoạt'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Tên buổi *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: locationCtrl,
                    decoration: const InputDecoration(labelText: 'Địa điểm', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                // Chọn ngày giờ
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined, color: AppColors.orange),
                  title: Text(pickedDate == null
                      ? 'Chọn ngày'
                      : '${pickedDate!.day}/${pickedDate!.month}/${pickedDate!.year}'),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 1)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) setDlgState(() => pickedDate = d);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time, color: AppColors.orange),
                  title: Text(pickedTime == null ? 'Chọn giờ' : pickedTime!.format(ctx)),
                  onTap: () async {
                    final t = await showTimePicker(context: ctx, initialTime: const TimeOfDay(hour: 14, minute: 0));
                    if (t != null) setDlgState(() => pickedTime = t);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Huỷ')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: Colors.white),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty || pickedDate == null || pickedTime == null) {
                  Get.snackbar('Thiếu thông tin', 'Vui lòng nhập đầy đủ tiêu đề, ngày và giờ');
                  return;
                }
                final sessionAt = DateTime(
                  pickedDate!.year, pickedDate!.month, pickedDate!.day,
                  pickedTime!.hour, pickedTime!.minute,
                );
                Navigator.pop(ctx);
                final ok = await _ctrl.addSession(
                  widget.club.id, titleCtrl.text.trim(),
                  locationCtrl.text.trim().isEmpty ? null : locationCtrl.text.trim(),
                  sessionAt,
                );
                if (ok) _loadDetail();
              },
              child: const Text('Thêm'),
            ),
          ],
        ),
      ),
    );
  }
}
