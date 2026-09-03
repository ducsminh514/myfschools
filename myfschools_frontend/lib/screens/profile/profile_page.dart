import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/controllers/auth_controller.dart';
import 'package:myfschools/controllers/profile_controller.dart';
import 'package:myfschools/constants/app_constants.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final profileCtrl = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Cá nhân', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.orange,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _showLogoutDialog(context, authCtrl),
          )
        ],
      ),
      body: Obx(() {
        final data = profileCtrl.profileData;
        final detail = data['detail'];

        return Skeletonizer(
          enabled: profileCtrl.isLoading.value,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar & Name Section — Bấm để đổi ảnh đại diện
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final source = await showModalBottomSheet<ImageSource>(
                      context: context,
                      builder: (_) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt),
                            title: const Text('Chụp ảnh'),
                            onTap: () => Get.back(result: ImageSource.camera),
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library),
                            title: const Text('Chọn từ thư viện'),
                            onTap: () => Get.back(result: ImageSource.gallery),
                          ),
                        ],
                      ),
                    );
                    if (source == null) return;
                    final file = await picker.pickImage(source: source, imageQuality: 80);
                    if (file != null) await profileCtrl.uploadAvatar(file);
                  },
                  child: Stack(
                    children: [
                      Obx(() {
                        final avatarUrl = profileCtrl.profileData['avatarUrl'];
                        return CircleAvatar(
                          radius: 50,
                          backgroundColor: AppColors.orangeSoft,
                          backgroundImage: avatarUrl != null && avatarUrl.toString().isNotEmpty
                              ? NetworkImage('${AppConstants.baseUrl}$avatarUrl')
                              : null,
                          child: avatarUrl == null || avatarUrl.toString().isEmpty
                              ? const Icon(Icons.person, size: 50, color: AppColors.orange)
                              : null,
                        );
                      }),
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data['fullName'] ?? 'Đang tải...',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
                Text(
                  'Mã số: ${data['studentCode'] ?? data['id'] ?? '---'}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                // Hiển thị danh sách vai trò (Roles)
                Wrap(
                  spacing: 8,
                  children: (data['roles'] as List<dynamic>?)?.map((role) {
                    return Chip(
                      label: Text(
                        role.toString().toUpperCase(),
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: AppColors.navyMid,
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList() ?? [],
                ),
                const SizedBox(height: 32),

                // Info Section — Theo role
                if (data['roles'] != null && (data['roles'] as List).contains('teacher') && data['teacherDetail'] != null) ...[
                  // ═══ GV: Thông tin giảng dạy ═══
                  _buildInfoCard('Thông tin giảng dạy', [
                    _buildInfoRow(
                      Icons.school_outlined, 
                      'Vai trò', 
                      data['teacherDetail']['isHomeroom'] == true 
                        ? 'GVCN - ${data['teacherDetail']['homeroomClassName'] ?? ''}' 
                        : 'Giáo viên bộ môn',
                    ),
                    _buildInfoRow(Icons.email_outlined, 'Email', data['email'] ?? 'Chưa cập nhật'),
                    _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', data['phone'] ?? 'Chưa cập nhật'),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoCard('Môn dạy', [
                    if (data['teacherDetail']['teachingSubjects'] != null)
                      ...(data['teacherDetail']['teachingSubjects'] as List).map((s) => 
                        _buildInfoRow(Icons.menu_book_outlined, s['className'] ?? '', s['subjectName'] ?? '')),
                    if (data['teacherDetail']['teachingSubjects'] == null || (data['teacherDetail']['teachingSubjects'] as List).isEmpty)
                      _buildInfoRow(Icons.info_outline, 'Chưa có', 'Chưa được phân công'),
                  ]),
                ] else ...[
                  // ═══ HS: Thông tin cơ bản + gia đình ═══
                  _buildInfoCard('Thông tin cơ bản', [
                    _buildInfoRow(Icons.calendar_today, 'Ngày sinh', _formatDate(detail?['birthDate'])),
                    _buildInfoRow(Icons.person_outline, 'Giới tính', detail?['gender'] == 'male' ? 'Nam' : 'Nữ'),
                    _buildInfoRow(Icons.location_on_outlined, 'Địa chỉ', detail?['address'] ?? 'Chưa cập nhật'),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoCard('Thông tin gia đình', [
                    _buildInfoRow(Icons.family_restroom, 'Phụ huynh', detail?['parentName'] ?? 'Chưa cập nhật'),
                    _buildInfoRow(Icons.phone_outlined, 'Số điện thoại', detail?['parentPhone'] ?? '---'),
                  ]),
                ],

                const SizedBox(height: 32),
                // Actions
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showChangePasswordDialog(context, profileCtrl),
                    icon: const Icon(Icons.lock_outline),
                    label: const Text('Đổi mật khẩu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.orange),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context, authCtrl),
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                const Text('Phiên bản 1.0.0', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navyMid)),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '---';
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showLogoutDialog(BuildContext context, AuthController authCtrl) {
    Get.dialog(
      AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi hệ thống FPT School?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () => authCtrl.logout(), child: const Text('Đăng xuất', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, ProfileController profileCtrl) {
    Get.dialog(_ChangePasswordDialog(profileCtrl: profileCtrl));
  }
}

/// Dialog đổi mật khẩu với show/hide toggle
class _ChangePasswordDialog extends StatefulWidget {
  final ProfileController profileCtrl;
  const _ChangePasswordDialog({required this.profileCtrl});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _oldPassCtrl     = TextEditingController();
  final _newPassCtrl     = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _showOld          = false;
  bool _showNew          = false;
  bool _showConfirm      = false;
  bool _isLoading        = false;

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newPassCtrl.text.length < 6) {
      Get.snackbar('Lỗi', 'Mật khẩu mới phải từ 6 ký tự trở lên');
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      Get.snackbar('Lỗi', 'Mật khẩu nhập lại không khớp');
      return;
    }
    setState(() => _isLoading = true);
    final success = await widget.profileCtrl.changePassword(_oldPassCtrl.text, _newPassCtrl.text);
    if (success) {
      Get.back();
      Get.find<AuthController>().logout();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Widget _passField(String label, TextEditingController ctrl, bool show, VoidCallback toggle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        obscureText: !show,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.orange),
          suffixIcon: IconButton(
            icon: Icon(show ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: toggle,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.orange, width: 2),
          ),
          isDense: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Đổi mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _passField('Mật khẩu cũ', _oldPassCtrl, _showOld, () => setState(() => _showOld = !_showOld)),
            _passField('Mật khẩu mới', _newPassCtrl, _showNew, () => setState(() => _showNew = !_showNew)),
            _passField('Nhập lại mật khẩu', _confirmPassCtrl, _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Huỷ')),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
          child: _isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Cập nhật', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

