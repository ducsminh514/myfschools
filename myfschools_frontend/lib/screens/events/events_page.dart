import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/controllers/events_controller.dart';
import 'package:myfschools/models/event_model.dart';
import 'package:myfschools/screens/events/event_detail_page.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final EventsController _ctrl = Get.put(EventsController());

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
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
        title: const Text('Sự Kiện trường',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Sắp diễn ra'),
            Tab(text: 'Đã qua'),
            Tab(text: 'Đã đăng ký'),
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
            _buildEventList(_ctrl.upcomingEvents, emptyMsg: 'Hiện không có sự kiện sắp diễn ra'),
            _buildEventList(_ctrl.pastEvents, emptyMsg: 'Chưa có sự kiện đã qua'),
            _buildEventList(_ctrl.myRegistrations, emptyMsg: 'Bạn chưa đăng ký sự kiện nào'),
          ],
        );
      }),
    );
  }

  Widget _buildEventList(List<EventModel> items, {required String emptyMsg}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey.withOpacity(0.4)),
            const SizedBox(height: 12),
            Text(emptyMsg, style: const TextStyle(color: Colors.grey, fontSize: 15)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () => _ctrl.fetchAll(),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _EventCard(event: items[i], ctrl: _ctrl),
      ),
    );
  }
}

// ── Event Card ──────────────────────────────────────────────────────────────

class _EventCard extends StatelessWidget {
  final EventModel event;
  final EventsController ctrl;
  const _EventCard({required this.event, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => EventDetailPage(eventId: event.id),
          transition: Transition.cupertino),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            if (event.bannerUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(event.bannerUrl!, height: 140, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              )
            else
              _buildBannerPlaceholder(),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge loại + ngày
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TypeBadge(eventType: event.eventType),
                      Text(event.startAt.split(' ').first,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Tên sự kiện
                  Text(event.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  // Địa điểm + giờ
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text('${event.location ?? "TBA"} · ${event.startAt.split(' ').last}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Slot + nút
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Slot còn lại
                      if (event.maxCapacity != null)
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              event.isFull
                                  ? 'Hết chỗ'
                                  : '${event.slotsLeft} chỗ còn',
                              style: TextStyle(
                                fontSize: 12,
                                color: event.isFull ? Colors.red : Colors.grey,
                                fontWeight: event.isFull ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox.shrink(),

                      // Nút đăng ký / trạng thái
                      _RegisterButton(event: event, ctrl: ctrl),
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

  Widget _buildBannerPlaceholder() {
    final color = _TypeBadge.colorFor(event.eventType);
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Icon(Icons.event_rounded, size: 40, color: color.withOpacity(0.5)),
      ),
    );
  }
}

// ── Register Button ──────────────────────────────────────────────────────────

class _RegisterButton extends StatefulWidget {
  final EventModel event;
  final EventsController ctrl;
  const _RegisterButton({required this.event, required this.ctrl});

  @override
  State<_RegisterButton> createState() => _RegisterButtonState();
}

class _RegisterButtonState extends State<_RegisterButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;

    if (e.isPast) {
      return const Text('Đã kết thúc', style: TextStyle(fontSize: 12, color: Colors.grey));
    }
    if (e.isRegistered) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 14, color: AppColors.green),
            SizedBox(width: 4),
            Text('Đã đăng ký', style: TextStyle(fontSize: 12, color: AppColors.green, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    if (e.isFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
        child: const Text('Hết chỗ', style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
      );
    }

    return GestureDetector(
      onTap: _loading ? null : _doRegister,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.orange, Color(0xFFF97316)]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: _loading
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Đăng ký →', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _doRegister() async {
    setState(() => _loading = true);
    await widget.ctrl.register(widget.event.id);
    if (mounted) setState(() => _loading = false);
  }
}

// ── Type Badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  final String? eventType;
  const _TypeBadge({this.eventType});

  static Color colorFor(String? type) => switch (type) {
    'hoc_thuat'    => const Color(0xFF3B82F6), // xanh dương
    'hoi_thao'     => AppColors.orange,
    'van_nghe'     => const Color(0xFF8B5CF6), // tím
    'hoi_trai'     => AppColors.green,
    'huong_nghiep' => const Color(0xFF92400E), // nâu
    _              => Colors.grey,
  };

  static String labelFor(String? type) => switch (type) {
    'hoc_thuat'    => 'Học thuật',
    'hoi_thao'     => 'Hội thao',
    'van_nghe'     => 'Văn nghệ',
    'hoi_trai'     => 'Hội trại',
    'huong_nghiep' => 'Hướng nghiệp',
    _              => 'Sự kiện',
  };

  @override
  Widget build(BuildContext context) {
    final color = colorFor(eventType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(labelFor(eventType),
          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w700)),
    );
  }
}
