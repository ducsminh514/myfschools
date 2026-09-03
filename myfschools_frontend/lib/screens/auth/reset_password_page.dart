import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/services/api_client.dart';

/// Bước 3 – Nhập mật khẩu mới sau khi xác nhận OTP thành công
class ResetPasswordPage extends StatefulWidget {
  final String resetToken;
  const ResetPasswordPage({super.key, required this.resetToken});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _newPassCtrl    = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  bool _isLoading       = false;
  bool _showNewPass     = false;
  bool _showConfirmPass = false;

  Future<void> _resetPassword() async {
    final newPass = _newPassCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (newPass.length < 6) {
      Get.snackbar('Lỗi', 'Mật khẩu mới phải từ 6 ký tự trở lên');
      return;
    }
    if (newPass != confirm) {
      Get.snackbar('Lỗi', 'Nhập lại mật khẩu không khớp');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final resp = await ApiClient().dio.post('auth/reset-password', data: {
        'resetToken': widget.resetToken,
        'newPassword': newPass,
      });
      if (resp.statusCode == 200) {
        Get.snackbar('Thành công', 'Đặt lại mật khẩu thành công! Vui lòng đăng nhập lại.',
          backgroundColor: Colors.green.shade50, colorText: Colors.green.shade800,
          duration: const Duration(seconds: 3));
        // Về màn login, xoá toàn bộ stack
        Get.offAllNamed('/login');
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể đặt lại mật khẩu');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.navyMid),
          onPressed: () => Get.back(),
        ),
        title: const Text('Đặt lại mật khẩu',
            style: TextStyle(color: AppColors.navyMid, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.lock_open_outlined, size: 64, color: AppColors.orange),
            const SizedBox(height: 24),
            const Text('Mật khẩu mới',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 8),
            Text('Nhập mật khẩu mới cho tài khoản của bạn',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            TextField(
              controller: _newPassCtrl,
              obscureText: !_showNewPass,
              decoration: InputDecoration(
                labelText: 'Mật khẩu mới',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.orange),
                suffixIcon: IconButton(
                  icon: Icon(_showNewPass ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey),
                  onPressed: () => setState(() => _showNewPass = !_showNewPass),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.orange, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmCtrl,
              obscureText: !_showConfirmPass,
              decoration: InputDecoration(
                labelText: 'Nhập lại mật khẩu',
                prefixIcon: const Icon(Icons.lock_outline, color: AppColors.orange),
                suffixIcon: IconButton(
                  icon: Icon(_showConfirmPass ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey),
                  onPressed: () => setState(() => _showConfirmPass = !_showConfirmPass),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.orange, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Đặt lại mật khẩu',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
