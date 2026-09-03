import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../controllers/forms_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../constants/app_constants.dart';
import 'create_form_page.dart';
import 'form_detail_page.dart';

class FormListPage extends StatefulWidget {
  const FormListPage({super.key});

  @override
  State<FormListPage> createState() => _FormListPageState();
}

class _FormListPageState extends State<FormListPage> with SingleTickerProviderStateMixin {
  late final FormsController _formsCtrl;
  late final bool _isTeacher;
  late final TabController _tabController;

  // Thứ tự: pending, approved, rejected, all
  static const _tabs = [
    {'label': 'Chờ duyệt', 'status': 'pending'},
    {'label': 'Đã duyệt',  'status': 'approved'},
    {'label': 'Từ chối',   'status': 'rejected'},
    {'label': 'Tất cả',    'status': ''},
  ];

  @override
  void initState() {
    super.initState();
    _formsCtrl = Get.put(FormsController());
    final authCtrl = Get.find<AuthController>();
    _isTeacher = authCtrl.currentUser.value?.roles.contains('teacher') ?? false;
    _tabController = TabController(length: _tabs.length, vsync: this);

    if (_isTeacher) {
      _formsCtrl.fetchTeacherForms();
    } else {
      _formsCtrl.fetchMyForms();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<dynamic> _filtered(List<dynamic> all, String statusFilter) {
    if (statusFilter.isEmpty) return all;
    return all.where((f) => f.status.toLowerCase() == statusFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          _isTeacher ? 'Duyệt đơn học vụ' : 'Đơn từ học vụ',
          style: const TextStyle(color: AppColors.navyMid, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.navyMid, size: 20),
          onPressed: () => Get.back(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.orange,
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: _tabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      floatingActionButton: _isTeacher
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Get.to(() => const CreateFormPage(), transition: Transition.downToUp),
              backgroundColor: AppColors.orange,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Nộp đơn mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
      body: Obx(() {
        final allList = _isTeacher ? _formsCtrl.teacherForms : _formsCtrl.myForms;

        if (_formsCtrl.isLoading.value && allList.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: AppColors.orange));
        }

        return TabBarView(
          controller: _tabController,
          children: _tabs.map((tab) {
            final list = _filtered(allList, tab['status']!);

            if (list.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      tab['status'] == 'pending'
                          ? (_isTeacher ? 'Không có đơn nào chờ duyệt' : 'Không có đơn nào đang chờ')
                          : 'Không có đơn nào',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => _isTeacher ? _formsCtrl.fetchTeacherForms() : _formsCtrl.fetchMyForms(),
              color: AppColors.orange,
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 12, bottom: 100, left: 16, right: 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, index) {
                  final form = list[index];
                  return _buildFormCard(ctx, form);
                },
              ),
            );
          }).toList(),
        );
      }),
    );
  }

  Widget _buildFormCard(BuildContext ctx, dynamic form) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (form.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Chờ duyệt';
        statusIcon = Icons.hourglass_empty_outlined;
        break;
      case 'approved':
        statusColor = AppColors.green;
        statusText = 'Đã duyệt';
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rejected':
        statusColor = Colors.redAccent;
        statusText = 'Từ chối';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Không rõ';
        statusIcon = Icons.help_outline;
    }

    return GestureDetector(
      onTap: () => Get.to(() => FormDetailPage(form: form), transition: Transition.rightToLeft),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 5),
                      Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${form.createdAt.day}/${form.createdAt.month}/${form.createdAt.year}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_isTeacher)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'HS: ${form.studentName ?? "N/A"}',
                  style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            Text(
              form.title.isNotEmpty ? form.title : 'Đơn từ',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navyMid),
            ),
            const SizedBox(height: 4),
            Text(
              form.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.navyLight, fontSize: 14),
            ),

            if (form.attachmentUrl != null && form.attachmentUrl!.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: '${AppConstants.uploadsFolder}${form.attachmentUrl}',
                  height: 120, width: double.infinity, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],

            // Quick actions cho GV - pending tab
            if (_isTeacher && form.status.toLowerCase() == 'pending') ...[
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _showReviewDialog(ctx, form, 'Rejected'),
                    child: const Text('Từ chối', style: TextStyle(color: Colors.redAccent)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      await _formsCtrl.reviewForm(form.id, 'Approved', null);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, elevation: 0),
                    child: const Text('Phê duyệt', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],

            // Quick action cho HS - pending
            if (!_isTeacher && form.status.toLowerCase() == 'pending') ...[
              const Divider(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _formsCtrl.deleteForm(form.id),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 16),
                  label: const Text('Thu hồi', style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            ],

            // Lý do từ chối
            if (form.rejectReason != null && form.rejectReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Lý do: ${form.rejectReason}',
                    style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
              ),
            ],

            // Hint xem chi tiết
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Text('Xem chi tiết', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext ctx, dynamic form, String status) {
    final reasonCtrl = TextEditingController();
    Get.defaultDialog(
      title: 'Lý do từ chối',
      content: TextField(
        controller: reasonCtrl,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: 'Nhập lý do từ chối...',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textConfirm: 'Xác nhận từ chối',
      textCancel: 'Huỷ',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () async {
        Get.back();
        await _formsCtrl.reviewForm(form.id, status, reasonCtrl.text);
      },
    );
  }
}
