import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/controllers/clubs_controller.dart';
import 'package:myfschools/models/club_model.dart';
import 'package:myfschools/screens/clubs/club_detail_page.dart';

class ClubsPage extends StatefulWidget {
  const ClubsPage({super.key});

  @override
  State<ClubsPage> createState() => _ClubsPageState();
}

class _ClubsPageState extends State<ClubsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final ClubsController _ctrl = Get.put(ClubsController());

  static const _types = [
    ('', 'Tất cả'),
    ('hoc_thuat', 'Học thuật'),
    ('the_thao', 'Thể thao'),
    ('nghe_thuat', 'Nghệ thuật'),
    ('tinh_nguyen', 'Tình nguyện'),
    ('khac', 'Khác'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        elevation: 0,
        title: const Text('Câu Lạc Bộ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Khám phá'),
            Tab(text: 'CLB của tôi'),
          ],
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.orange));
        }
        return TabBarView(
          controller: _tabCtrl,
          children: [
            _buildExploreTab(),
            _buildMyClubsTab(),
          ],
        );
      }),
    );
  }

  // ── Tab 1: Khám phá ────────────────────────────────────────────────────────

  Widget _buildExploreTab() {
    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () => _ctrl.fetchAll(),
      child: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 52,
            child: Obx(() => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _types.map((t) {
                final active = _ctrl.selectedType.value == t.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(t.$2),
                    selected: active,
                    onSelected: (_) => _ctrl.fetchClubs(type: t.$1),
                    selectedColor: AppColors.orange.withOpacity(0.15),
                    checkmarkColor: AppColors.orange,
                    labelStyle: TextStyle(
                      color: active ? AppColors.orange : Colors.grey.shade700,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(color: active ? AppColors.orange : Colors.grey.shade300),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            )),
          ),

          // Danh sách CLB
          Expanded(
            child: Obx(() {
              if (_ctrl.clubs.isEmpty) {
                return const Center(child: Text('Không có CLB nào', style: TextStyle(color: Colors.grey)));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _ctrl.clubs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _ClubCard(club: _ctrl.clubs[i], ctrl: _ctrl),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Tab 2: CLB của tôi ─────────────────────────────────────────────────────

  Widget _buildMyClubsTab() {
    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () => _ctrl.fetchAll(),
      child: Obx(() {
        if (_ctrl.myClubs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off_outlined, size: 64, color: Colors.grey.withOpacity(0.4)),
                const SizedBox(height: 12),
                const Text('Bạn chưa tham gia CLB nào',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _tabCtrl.animateTo(0),
                  child: const Text('Khám phá CLB →', style: TextStyle(color: AppColors.orange)),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _ctrl.myClubs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _MyClubCard(club: _ctrl.myClubs[i], ctrl: _ctrl),
        );
      }),
    );
  }
}

// ── Club Card (Khám phá) ──────────────────────────────────────────────────────

class _ClubCard extends StatelessWidget {
  final ClubModel club;
  final ClubsController ctrl;
  const _ClubCard({required this.club, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ClubDetailPage(clubId: club.id),
          transition: Transition.cupertino),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            // Logo
            _ClubLogo(logoUrl: club.logoUrl, clubType: club.clubType, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TypeBadge(clubType: club.clubType, label: club.typeLabel),
                      _RegStatusBadge(regStatus: club.regStatus),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(club.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navy),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.people_outline, size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        club.maxMembers != null
                            ? '${club.memberCount}/${club.maxMembers} thành viên'
                            : '${club.memberCount} thành viên',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  if (club.advisorName != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text('GV: ${club.advisorName}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  _JoinStatusRow(club: club, ctrl: ctrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Club Card ──────────────────────────────────────────────────────────────

class _MyClubCard extends StatelessWidget {
  final ClubModel club;
  final ClubsController ctrl;
  const _MyClubCard({required this.club, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ClubDetailPage(clubId: club.id),
          transition: Transition.cupertino),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          border: club.isLeader
              ? Border.all(color: AppColors.orange.withOpacity(0.4), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ClubLogo(logoUrl: club.logoUrl, clubType: club.clubType, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(club.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navy)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (club.isLeader) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('👑 Trưởng CLB',
                                  style: TextStyle(fontSize: 11, color: AppColors.orange, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                          ] else if (club.isPending) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text('⏳ Chờ duyệt',
                                  style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          _TypeBadge(clubType: club.clubType, label: club.typeLabel),
                        ],
                      ),
                    ],
                  ),
                ),
                if (club.isLeader)
                  const Icon(Icons.chevron_right, color: AppColors.orange),
              ],
            ),
            // Lịch sinh hoạt tiếp theo
            if (club.nextSession != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${club.nextSession!['title']} · ${club.nextSession!['sessionAt']}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSub),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Join Status Row ───────────────────────────────────────────────────────────

class _JoinStatusRow extends StatefulWidget {
  final ClubModel club;
  final ClubsController ctrl;
  const _JoinStatusRow({required this.club, required this.ctrl});

  @override
  State<_JoinStatusRow> createState() => _JoinStatusRowState();
}

class _JoinStatusRowState extends State<_JoinStatusRow> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.club;

    // Đã là thành viên
    if (c.isMember) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: AppColors.green),
          SizedBox(width: 4),
          Text('Đã tham gia', style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w600)),
        ],
      );
    }
    // Đang chờ duyệt
    if (c.isPending) {
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pending_outlined, size: 14, color: Colors.amber),
          SizedBox(width: 4),
          Text('Chờ duyệt', style: TextStyle(fontSize: 12, color: Colors.amber, fontWeight: FontWeight.w600)),
        ],
      );
    }

    // Trạng thái đăng ký
    if (c.regStatus == 'not_open') {
      return const Text('Chưa mở ĐK', style: TextStyle(fontSize: 12, color: Colors.grey));
    }
    if (c.regStatus == 'closed') {
      return const Text('Hết hạn ĐK', style: TextStyle(fontSize: 12, color: Colors.red));
    }
    if (c.regStatus == 'full') {
      return const Text('Đầy thành viên', style: TextStyle(fontSize: 12, color: Colors.red));
    }

    // Có thể đăng ký
    return GestureDetector(
      onTap: _loading ? null : _doJoin,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.orange, Color(0xFFF97316)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: _loading
            ? const SizedBox(width: 14, height: 14,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Đăng ký →',
                style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _doJoin() async {
    setState(() => _loading = true);
    await widget.ctrl.join(widget.club.id);
    if (mounted) setState(() => _loading = false);
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _ClubLogo extends StatelessWidget {
  final String? logoUrl;
  final String? clubType;
  final double size;
  const _ClubLogo({this.logoUrl, this.clubType, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(clubType);
    if (logoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: Image.network(logoUrl!, width: size, height: size, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _placeholder(color)),
      );
    }
    return _placeholder(color);
  }

  Widget _placeholder(Color color) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(size * 0.25),
    ),
    child: Icon(Icons.groups_rounded, size: size * 0.5, color: color.withOpacity(0.6)),
  );
}

class _TypeBadge extends StatelessWidget {
  final String? clubType;
  final String label;
  const _TypeBadge({this.clubType, required this.label});

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(clubType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _RegStatusBadge extends StatelessWidget {
  final String regStatus;
  const _RegStatusBadge({required this.regStatus});

  @override
  Widget build(BuildContext context) {
    return switch (regStatus) {
      'open'     => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.green.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: const Text('🟢 Đang mở ĐK', style: TextStyle(fontSize: 10, color: AppColors.green, fontWeight: FontWeight.bold)),
        ),
      'closed'   => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: const Text('🔴 Hết hạn', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
        ),
      'full'     => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: Colors.grey.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: const Text('Đầy', style: TextStyle(fontSize: 10, color: Colors.grey)),
        ),
      _          => const SizedBox.shrink(), // not_open: không hiện
    };
  }
}

Color _typeColor(String? type) => switch (type) {
  'hoc_thuat'   => const Color(0xFF3B82F6),
  'the_thao'    => AppColors.orange,
  'nghe_thuat'  => const Color(0xFF8B5CF6),
  'tinh_nguyen' => AppColors.green,
  _             => Colors.blueGrey,
};
