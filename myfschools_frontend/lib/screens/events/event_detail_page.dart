import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/controllers/events_controller.dart';
import 'package:myfschools/models/event_model.dart';
import 'package:myfschools/services/api_client.dart';

class EventDetailPage extends StatefulWidget {
  final int eventId;
  const EventDetailPage({super.key, required this.eventId});

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  bool _isLoading = true;
  EventModel? _event;
  Timer? _countdownTimer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final resp = await ApiClient().dio.get('/events/${widget.eventId}');
      if (resp.statusCode == 200) {
        final evnt = EventModel.fromJson(Map<String, dynamic>.from(resp.data));
        setState(() {
          _event = evnt;
          _isLoading = false;
        });
        _startCountdown(evnt);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _startCountdown(EventModel evnt) {
    if (evnt.startAtRaw == null) return;
    try {
      final startAt = DateTime.parse(evnt.startAtRaw!);
      final diff = startAt.difference(DateTime.now());
      // Countdown chỉ khi còn <= 7 ngày
      if (diff.isNegative || diff.inDays > 7) return;
      setState(() => _remaining = diff);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        final d = startAt.difference(DateTime.now());
        if (d.isNegative) {
          _countdownTimer?.cancel();
          _loadDetail(); // Refresh status
        } else {
          setState(() => _remaining = d);
        }
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.orange)),
      );
    }
    if (_event == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.orange, title: const Text('Chi tiết', style: TextStyle(color: Colors.white))),
        body: const Center(child: Text('Không tìm thấy sự kiện')),
      );
    }
    final e = _event!;
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // AppBar với banner
          SliverAppBar(
            expandedHeight: e.bannerUrl != null ? 220 : 100,
            pinned: true,
            backgroundColor: AppColors.orange,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: e.bannerUrl != null
                  ? Image.network(e.bannerUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildBannerPlaceholder(e))
                  : _buildBannerPlaceholder(e),
            ),
            title: Text(e.title,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge loại
                  _TypeBadgeLarge(eventType: e.eventType),
                  const SizedBox(height: 12),

                  // Tên sự kiện
                  Text(e.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 6),

                  // Countdown timer (nếu còn <= 7 ngày)
                  if (_remaining > Duration.zero) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_outlined, color: AppColors.orange, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Còn ${_remaining.inDays} ngày ${_remaining.inHours.remainder(24)} giờ ${_remaining.inMinutes.remainder(60)} phút',
                            style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Thông tin sự kiện
                  _InfoCard(children: [
                    _InfoRow(icon: Icons.location_on_outlined, text: e.location ?? 'TBA'),
                    _InfoRow(icon: Icons.calendar_today_outlined, text: '${e.startAt} → ${e.endAt}'),
                    if (e.maxCapacity != null)
                      _InfoRow(
                        icon: Icons.people_outline,
                        text: '${e.currentRegistrations}/${e.maxCapacity} đã đăng ký',
                        color: e.isFull ? Colors.red : null,
                      ),
                  ]),
                  const SizedBox(height: 12),

                  // Progress bar slot
                  if (e.maxCapacity != null) ...[
                    _SlotProgressBar(current: e.currentRegistrations, max: e.maxCapacity!),
                    const SizedBox(height: 16),
                  ],

                  // Mô tả
                  if (e.description != null && e.description!.isNotEmpty) ...[
                    const Text('📝 Mô tả', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy)),
                    const SizedBox(height: 8),
                    Text(e.description!, style: const TextStyle(fontSize: 14, color: AppColors.textSub, height: 1.5)),
                    const SizedBox(height: 24),
                  ],

                  // Nút hành động
                  _ActionButton(event: e, onDone: _loadDetail),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerPlaceholder(EventModel e) {
    final color = _typeBadgeColor(e.eventType);
    return Container(
      color: color.withOpacity(0.15),
      child: Center(child: Icon(Icons.event_rounded, size: 60, color: color.withOpacity(0.4))),
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: children.map((w) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: w)).toList(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: color ?? AppColors.textSub))),
      ],
    );
  }
}

// ── Slot Progress Bar ─────────────────────────────────────────────────────────

class _SlotProgressBar extends StatelessWidget {
  final int current;
  final int max;
  const _SlotProgressBar({required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    final pct = (current / max).clamp(0.0, 1.0);
    final color = pct < 0.8 ? AppColors.green : (pct < 0.95 ? Colors.orange : Colors.red);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${(pct * 100).toStringAsFixed(0)}% đã đăng ký',
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
            Text('Còn ${max - current} chỗ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

// ── Action Button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  final EventModel event;
  final VoidCallback onDone;
  const _ActionButton({required this.event, required this.onDone});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final ctrl = Get.find<EventsController>();

    if (e.isPast) {
      return _buildDisabledBtn('Sự kiện đã kết thúc', Colors.grey);
    }
    if (e.isOngoing) {
      return _buildDisabledBtn('Sự kiện đang diễn ra', AppColors.green);
    }
    if (e.isRegistered) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _loading ? null : () async {
            // Xác nhận huỷ
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Huỷ đăng ký'),
                content: const Text('Bạn có chắc chắn muốn huỷ đăng ký sự kiện này?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Không')),
                  TextButton(onPressed: () => Navigator.pop(context, true),
                      child: const Text('Huỷ đăng ký', style: TextStyle(color: Colors.red))),
                ],
              ),
            );
            if (confirm == true) {
              setState(() => _loading = true);
              await ctrl.unregister(e.id);
              widget.onDone();
              if (mounted) setState(() => _loading = false);
            }
          },
          icon: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.check_circle_outline, color: AppColors.green),
          label: const Text('Đã đăng ký · Bấm để huỷ', style: TextStyle(color: AppColors.green)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.green),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );
    }
    if (e.isFull) {
      return _buildDisabledBtn('Hết chỗ đăng ký', Colors.red);
    }

    // Nút đăng ký chính
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : () async {
          setState(() => _loading = true);
          await ctrl.register(e.id);
          widget.onDone();
          if (mounted) setState(() => _loading = false);
        },
        icon: _loading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.how_to_reg_outlined),
        label: const Text('Đăng ký tham gia', style: TextStyle(fontSize: 16)
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildDisabledBtn(String label, Color color) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: color.withOpacity(0.1),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Type Badge Large ──────────────────────────────────────────────────────────

class _TypeBadgeLarge extends StatelessWidget {
  final String? eventType;
  const _TypeBadgeLarge({this.eventType});

  @override
  Widget build(BuildContext context) {
    final color = _typeBadgeColor(eventType);
    final label = _typeBadgeLabel(eventType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

Color _typeBadgeColor(String? type) => switch (type) {
  'hoc_thuat'    => const Color(0xFF3B82F6),
  'hoi_thao'     => AppColors.orange,
  'van_nghe'     => const Color(0xFF8B5CF6),
  'hoi_trai'     => AppColors.green,
  'huong_nghiep' => const Color(0xFF92400E),
  _              => Colors.grey,
};

String _typeBadgeLabel(String? type) => switch (type) {
  'hoc_thuat'    => 'Học thuật',
  'hoi_thao'     => 'Hội thao',
  'van_nghe'     => 'Văn nghệ',
  'hoi_trai'     => 'Hội trại',
  'huong_nghiep' => 'Hướng nghiệp',
  _              => 'Sự kiện',
};
