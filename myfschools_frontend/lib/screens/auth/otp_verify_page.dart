import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/services/api_client.dart';
import 'reset_password_page.dart';

/// Bước 2 – Nhập OTP 6 số (có đếm ngược 5 phút + nút gửi lại)
class OtpVerifyPage extends StatefulWidget {
  final String phone;

  const OtpVerifyPage({super.key, required this.phone});

  @override
  State<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends State<OtpVerifyPage> {
  final List<TextEditingController> _otpCtrls = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isLoading     = false;
  bool _isResending   = false;
  int _secondsLeft    = 300; // 5 phút
  bool _canResend     = false; // Cho phép gửi lại sau khi timer hết
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsLeft = 300;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  String get _formattedTime {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _currentOtp => _otpCtrls.map((c) => c.text).join();

  Future<void> _verifyOtp() async {
    if (_currentOtp.length != 6) {
      Get.snackbar('Lỗi', 'Vui lòng nhập đủ 6 số OTP');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final resp = await ApiClient().dio.post('auth/verify-otp', data: {
        'phone': widget.phone,
        'otp': _currentOtp,
      });
      if (resp.statusCode == 200) {
        final resetToken = resp.data['resetToken'];
        Get.to(() => ResetPasswordPage(resetToken: resetToken));
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'OTP không chính xác');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Gửi lại OTP — reset timer + xóa các ô nhập
  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    try {
      final resp = await ApiClient().dio.post('auth/forgot-password', data: {'phone': widget.phone});
      if (resp.statusCode == 200) {
        // Xóa các ô OTP cũ
        for (var c in _otpCtrls) { c.clear(); }
        _focusNodes[0].requestFocus();
        _startTimer();
        Get.snackbar('Đã gửi lại', 'OTP mới đã được gửi đến ${widget.phone}',
          backgroundColor: Colors.green.shade50, colorText: Colors.green.shade800);
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể gửi lại OTP');
    } finally {
      setState(() => _isResending = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _otpCtrls) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
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
        title: const Text('Xác nhận OTP', style: TextStyle(color: AppColors.navyMid, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.sms_outlined, size: 64, color: AppColors.orange),
            const SizedBox(height: 24),
            const Text('Nhập mã OTP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.navy)),
            const SizedBox(height: 8),
            Text('Nhập mã 6 số đã gửi đến email của bạn', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            // 6 ô nhập OTP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (i) => SizedBox(
                width: 46,
                child: TextField(
                  controller: _otpCtrls[i],
                  focusNode: _focusNodes[i],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.orange, width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    if (val.isNotEmpty && i < 5) {
                      _focusNodes[i + 1].requestFocus();
                    } else if (val.isEmpty && i > 0) {
                      _focusNodes[i - 1].requestFocus();
                    }
                    // Auto-submit khi nhập đủ 6 số
                    if (_currentOtp.length == 6) _verifyOtp();
                  },
                ),
              )),
            ),
            const SizedBox(height: 24),
            // Đếm ngược + nút gửi lại
            Center(
              child: _canResend
                  ? TextButton.icon(
                      icon: _isResending
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange))
                          : const Icon(Icons.refresh, color: AppColors.orange, size: 18),
                      label: Text(_isResending ? 'Đang gửi...' : 'Gửi lại OTP',
                          style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600)),
                      onPressed: _isResending ? null : _resendOtp,
                    )
                  : Text(
                      'OTP hết hạn sau $_formattedTime',
                      style: const TextStyle(color: Colors.grey),
                    ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || _secondsLeft <= 0) ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _secondsLeft <= 0 ? 'OTP đã hết hạn' : 'Xác nhận',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
