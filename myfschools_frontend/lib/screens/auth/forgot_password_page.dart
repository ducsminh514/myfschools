import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/services/api_client.dart';
import 'otp_verify_page.dart';

/// Bước 1 – Nhập số điện thoại để nhận OTP
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập số điện thoại');
      return;
    }
    setState(() => _isLoading = true);
    try {
      // Tăng timeout vì BE cần thời gian gửi email SMTP (~3-5s)
      final resp = await ApiClient().dio.post(
        'auth/forgot-password',
        data: {'phone': phone},
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );
      if (resp.statusCode == 200) {
        // Hiện thông báo thành công từ BE (có email masked)
        final msg = resp.data['message'] ?? 'OTP đã được gửi';
        Get.snackbar('✅ Thành công', msg,
            snackPosition: SnackPosition.TOP,
            backgroundColor: Colors.green.shade50,
            colorText: Colors.green.shade800,
            duration: const Duration(seconds: 3));
        // Chuyển sang màn nhập OTP
        Get.to(() => OtpVerifyPage(phone: phone));
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể gửi OTP');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Quên mật khẩu', style: TextStyle(color: AppColors.navyMid, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.lock_reset, size: 64, color: AppColors.orange),
            const SizedBox(height: 24),
            const Text('Nhập số điện thoại', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 8),
            Text('Chúng tôi sẽ gửi mã OTP 6 số đến email liên kết với số điện thoại của bạn', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Số điện thoại',
                prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.orange),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.orange, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Gửi mã OTP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
