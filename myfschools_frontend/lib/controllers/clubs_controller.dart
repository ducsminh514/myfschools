import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../models/club_model.dart';
import '../services/api_client.dart';

class ClubsController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<ClubModel> clubs = <ClubModel>[].obs;
  final RxList<ClubModel> myClubs = <ClubModel>[].obs;
  final RxString selectedType = ''.obs; // filter

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      await Future.wait([fetchClubs(), fetchMyClubs()]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchClubs({String? type}) async {
    try {
      final params = <String, dynamic>{};
      if (type != null && type.isNotEmpty) params['type'] = type;
      final resp = await ApiClient().dio.get('/clubs', queryParameters: params);
      if (resp.statusCode == 200) {
        clubs.value = (resp.data as List)
            .map((e) => ClubModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        selectedType.value = type ?? '';
      }
    } on DioException catch (e) {
      // Chỉ show lỗi khi user chủ động filter — không show khi auto-load
      if (type != null) {
        Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải danh sách CLB',
            snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  Future<void> fetchMyClubs() async {
    try {
      final resp = await ApiClient().dio.get('/clubs/my-clubs');
      if (resp.statusCode == 200) {
        myClubs.value = (resp.data as List)
            .map((e) => ClubModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } on DioException catch (_) {}
  }

  Future<ClubModel?> fetchClubDetail(int id) async {
    try {
      final resp = await ApiClient().dio.get('/clubs/$id');
      if (resp.statusCode == 200) {
        return ClubModel.fromJson(Map<String, dynamic>.from(resp.data));
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải thông tin CLB');
    }
    return null;
  }

  Future<bool> join(int clubId) async {
    try {
      final resp = await ApiClient().dio.post('/clubs/$clubId/join');
      if (resp.statusCode == 200) {
        Get.snackbar('📩 Đã gửi đơn', 'Chờ Trưởng CLB duyệt!',
            snackPosition: SnackPosition.BOTTOM);
        await fetchAll();
        return true;
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Đăng ký thất bại',
          snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }

  Future<bool> leave(int clubId) async {
    try {
      final resp = await ApiClient().dio.delete('/clubs/$clubId/leave');
      if (resp.statusCode == 200) {
        Get.snackbar('Đã rời CLB', '', snackPosition: SnackPosition.BOTTOM);
        await fetchAll();
        return true;
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Thất bại',
          snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }

  Future<bool> approveMember(int clubId, int memberId, bool approve) async {
    try {
      final resp = await ApiClient().dio.patch(
        '/clubs/$clubId/members/$memberId',
        data: {'status': approve ? 'approved' : 'rejected'},
      );
      if (resp.statusCode == 200) return true;
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Thất bại');
    }
    return false;
  }

  Future<bool> removeMember(int clubId, int memberId) async {
    try {
      final resp = await ApiClient().dio.delete('/clubs/$clubId/members/$memberId');
      if (resp.statusCode == 200) return true;
      return false;
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể xóa thành viên',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  Future<bool> addSession(int clubId, String title, String? location, DateTime sessionAt) async {
    try {
      final resp = await ApiClient().dio.post('/clubs/$clubId/sessions', data: {
        'title': title,
        'location': location,
        'sessionAt': sessionAt.toIso8601String(),
      });
      if (resp.statusCode == 200) {
        Get.snackbar('✅ Đã thêm', 'Lịch sinh hoạt mới đã được thêm');
        return true;
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể thêm lịch sinh hoạt',
          snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }
}
