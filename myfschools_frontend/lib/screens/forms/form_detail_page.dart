import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../controllers/forms_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/form_model.dart';

/// Trang xem chi tiết 1 đơn từ — dùng cho cả HS (xem) lẫn GV (xem + duyệt)
class FormDetailPage extends StatelessWidget {
  final FormModel form;
  const FormDetailPage({super.key, required this.form});

  static const Map<String, String> _formTypeLabels = {
    'nghi_hoc': 'Đơn xin nghỉ học',
    'phep_ra_ngoai': 'Đơn xin phép ra ngoài',
    'mien_hoan_thi': 'Đơn xin miễn/hoãn thi',
    'khieu_nai_diem': 'Đơn khiếu nại điểm',
    'xac_nhan_hoc_sinh': 'Xin giấy xác nhận Học sinh',
    'khac': 'Ý kiến khác / Phản hồi',
  };

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final isTeacher = authCtrl.currentUser.value?.roles.contains('teacher') ?? false;
    final formsCtrl = Get.find<FormsController>();

    final statusColor = _statusColor(form.status);
    final statusText = _statusText(form.status);
    final formTypeLabel = _formTypeLabels[form.formType] ?? form.formType;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Chi tiết đơn từ',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card: loại đơn + trạng thái
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_statusIcon(form.status), size: 14, color: statusColor),
                            const SizedBox(width: 6),
                            Text(statusText,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
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
                  const SizedBox(height: 14),
                  Text(form.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.navyLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(formTypeLabel,
                        style: const TextStyle(fontSize: 12, color: AppColors.navyMid, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Học sinh (chỉ hiện cho GV)
            if (isTeacher && form.studentName != null) ...[
              _sectionCard(
                icon: Icons.person_outline,
                title: 'Học sinh',
                content: form.studentName!,
              ),
              const SizedBox(height: 12),
            ],

            // Ngày nghỉ (nếu có)
            if (form.absentDate != null) ...[
              _sectionCard(
                icon: Icons.event_outlined,
                title: 'Ngày nghỉ / Ngày liên quan',
                content: form.absentDate!,
              ),
              const SizedBox(height: 12),
            ],

            // Nội dung
            _sectionCard(
              icon: Icons.description_outlined,
              title: 'Nội dung đơn',
              content: form.content,
              multiline: true,
            ),

            // Lý do từ chối (nếu có)
            if (form.rejectReason != null && form.rejectReason!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 18),
                        const SizedBox(width: 8),
                        const Text('Lý do từ chối', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(form.rejectReason!, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],

            // Ảnh đính kèm
            if (form.attachmentUrl != null && form.attachmentUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Tệp đính kèm',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyMid, fontSize: 14)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CachedNetworkImage(
                  imageUrl: '${AppConstants.uploadsFolder}${form.attachmentUrl}',
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (ctx, _) => Container(
                    height: 200,
                    color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator(color: AppColors.orange)),
                  ),
                  errorWidget: (ctx, _, __) => Container(
                    height: 120,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
                    child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Actions cho GV: duyệt / từ chối (nếu còn pending)
            if (isTeacher && form.status.toLowerCase() == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                      label: const Text('Từ chối', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _showRejectDialog(context, formsCtrl),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      label: const Text('Phê duyệt', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        await formsCtrl.reviewForm(form.id, 'Approved', null);
                        Get.back();
                      },
                    ),
                  ),
                ],
              ),
            ],

            // Action cho HS: thu hồi đơn (nếu còn pending)
            if (!isTeacher && form.status.toLowerCase() == 'pending') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                  label: const Text('Thu hồi đơn', style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    await formsCtrl.deleteForm(form.id);
                    Get.back();
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(BuildContext context, FormsController ctrl) {
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
        Get.back(); // Đóng dialog
        await ctrl.reviewForm(form.id, 'Rejected', reasonCtrl.text);
        Get.back(); // Quay về list
      },
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required String content, bool multiline = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.orange),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(fontSize: 15, color: AppColors.navy),
              maxLines: multiline ? null : 2),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return AppColors.green;
      case 'rejected': return Colors.redAccent;
      default: return Colors.orange;
    }
  }

  String _statusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return 'Đã phê duyệt';
      case 'rejected': return 'Bị từ chối';
      default: return 'Đang chờ duyệt';
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Icons.check_circle_outline;
      case 'rejected': return Icons.cancel_outlined;
      default: return Icons.hourglass_empty_outlined;
    }
  }
}
