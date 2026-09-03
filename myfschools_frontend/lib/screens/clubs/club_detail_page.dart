import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/controllers/clubs_controller.dart';
import 'package:myfschools/models/club_model.dart';
import 'package:myfschools/screens/clubs/club_manage_page.dart';

class ClubDetailPage extends StatefulWidget {
  final int clubId;
  const ClubDetailPage({super.key, required this.clubId});

  @override
  State<ClubDetailPage> createState() => _ClubDetailPageState();
}

class _ClubDetailPageState extends State<ClubDetailPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  ClubModel? _club;
  late final TabController _tabCtrl;

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
    setState(() => _isLoading = true);
    final ctrl = Get.find<ClubsController>();
    final club = await ctrl.fetchClubDetail(widget.clubId);
    if (mounted) setState(() { _club = club; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.orange)));
    }
    if (_club == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.orange,
            title: const Text('Chi tiết CLB', style: TextStyle(color: Colors.white))),
        body: const Center(child: Text('Không tìm thấy CLB')),
      );
    }

    final c = _club!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 180,
            backgroundColor: AppColors.orange,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(c),
            ),
            actions: [
              if (c.isLeader)
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () => Get.to(() => ClubManagePage(club: c))
                      ?.then((_) => _loadDetail()),
                  tooltip: 'Quản lý CLB',
                ),
            ],
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Giới thiệu'),
                Tab(text: 'Thành viên'),
                Tab(text: 'Lịch SH'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildAboutTab(c),
            _buildMembersTab(c),
            _buildSessionsTab(c),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(c),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(ClubModel c) {
    final color = _typeColor(c.clubType);
    return Container(
      color: color.withOpacity(0.85),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 60, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo lớn
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: c.logoUrl != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(18),
                        child: Image.network(c.logoUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _logoPlaceholder(color)))
                    : _logoPlaceholder(color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(c.name, style: const TextStyle(color: Colors.white,
                        fontSize: 18, fontWeight: FontWeight.bold), maxLines: 2),
                    const SizedBox(height: 4),
                    Text(c.typeLabel, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('${c.memberCount}${c.maxMembers != null ? "/${c.maxMembers}" : ""} thành viên',
                        style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _logoPlaceholder(Color color) =>
      Icon(Icons.groups_rounded, size: 36, color: Colors.white.withOpacity(0.7));

  // ── Tab 1: Giới thiệu ──────────────────────────────────────────────────────

  Widget _buildAboutTab(ClubModel c) {
    final regColor = switch (c.regStatus) {
      'open'   => AppColors.green,
      'closed' => Colors.red,
      _        => Colors.grey,
    };
    final regLabel = switch (c.regStatus) {
      'open'     => '🟢 Đang mở đăng ký${c.regCloseAt != null ? " · hết ${c.regCloseAt}" : ""}',
      'closed'   => '🔴 Đã hết hạn đăng ký',
      'full'     => '⚫ Đầy thành viên',
      _          => c.regOpenAt != null ? '⏳ Mở đăng ký từ ${c.regOpenAt}' : 'Chưa mở đăng ký',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Trạng thái đăng ký
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: regColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(regLabel, style: TextStyle(color: regColor, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 14),

        // GV cố vấn
        if (c.advisorName != null)
          _InfoCard(children: [
            _InfoRow(icon: Icons.person_outlined, label: 'GV Cố vấn', value: c.advisorName!),
          ]),

        const SizedBox(height: 14),

        // Mô tả
        if (c.description != null && c.description!.isNotEmpty) ...[
          const Text('📋 Giới thiệu CLB',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 8),
          Text(c.description!, style: const TextStyle(fontSize: 14, color: AppColors.textSub, height: 1.6)),
        ],
      ],
    );
  }

  // ── Tab 2: Thành viên ──────────────────────────────────────────────────────

  Widget _buildMembersTab(ClubModel c) {
    if (c.members.isEmpty) {
      return const Center(child: Text('Chưa có thành viên', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: c.members.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final m = c.members[i];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: m.role == 'leader'
                ? AppColors.orange.withOpacity(0.15)
                : Colors.grey.withOpacity(0.12),
            child: Text(m.name.isNotEmpty ? m.name[0] : '?',
                style: TextStyle(color: m.role == 'leader' ? AppColors.orange : Colors.grey.shade600,
                    fontWeight: FontWeight.bold)),
          ),
          title: Text(m.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text('Từ ${m.joinedAt}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          trailing: m.role == 'leader'
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Text('👑 Trưởng', style: TextStyle(fontSize: 11, color: AppColors.orange)))
              : null,
        );
      },
    );
  }

  // ── Tab 3: Lịch sinh hoạt ─────────────────────────────────────────────────

  Widget _buildSessionsTab(ClubModel c) {
    if (c.sessions.isEmpty) {
      return const Center(child: Text('Chưa có lịch sinh hoạt', style: TextStyle(color: Colors.grey)));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: c.sessions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final s = c.sessions[i];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
          ),
          child: Row(
            children: [
              Container(
                width: 4, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.orange, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navy)),
                    const SizedBox(height: 2),
                    Text(s.sessionAt, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    if (s.location != null)
                      Text('📍 ${s.location}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Bottom Bar ─────────────────────────────────────────────────────────────

  Widget? _buildBottomBar(ClubModel c) {
    if (c.isMember || c.isLeader) return null; // Đã là thành viên → không hiện

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
      ),
      child: _ActionButton(club: c, onDone: _loadDetail),
    );
  }
}

// ── Bottom Action Button ───────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final ClubModel club;
  final VoidCallback onDone;
  const _ActionButton({required this.club, required this.onDone});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.club;
    final ctrl = Get.find<ClubsController>();

    if (c.isPending) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.amber.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('⏳ Đơn đang chờ duyệt', style: TextStyle(color: Colors.amber)),
        ),
      );
    }

    if (!c.canJoin) {
      final label = switch (c.regStatus) {
        'not_open' => 'Chưa mở đăng ký',
        'closed'   => 'Đã hết hạn đăng ký',
        'full'     => 'CLB đã đầy thành viên',
        _          => 'Không thể đăng ký',
      };
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.grey.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : () async {
          setState(() => _loading = true);
          await ctrl.join(c.id);
          widget.onDone();
          if (mounted) setState(() => _loading = false);
        },
        icon: _loading
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.group_add_outlined),
        label: const Text('Gửi đơn đăng ký', style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ── Shared ────────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
    ),
    child: Column(children: children.map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: w)).toList()),
  );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey),
      const SizedBox(width: 8),
      Text('$label: ', style: const TextStyle(fontSize: 13, color: Colors.grey)),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.textSub))),
    ],
  );
}

Color _typeColor(String? type) => switch (type) {
  'hoc_thuat'   => const Color(0xFF3B82F6),
  'the_thao'    => AppColors.orange,
  'nghe_thuat'  => const Color(0xFF8B5CF6),
  'tinh_nguyen' => AppColors.green,
  _             => Colors.blueGrey,
};
