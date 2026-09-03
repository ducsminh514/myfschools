import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../models/event_model.dart';
import '../services/api_client.dart';

class EventsController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<EventModel> upcomingEvents = <EventModel>[].obs;
  final RxList<EventModel> pastEvents = <EventModel>[].obs;
  final RxList<EventModel> myRegistrations = <EventModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchAll();
  }

  Future<void> fetchAll() async {
    isLoading.value = true;
    try {
      await Future.wait([
        fetchUpcoming(silent: true),
        fetchPast(silent: true),
        fetchMyRegistrations(silent: true),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchUpcoming({bool silent = false}) async {
    if (!silent) isLoading.value = true;
    try {
      final resp = await ApiClient().dio.get('/events', queryParameters: {'filter': 'upcoming'});
      if (resp.statusCode == 200) {
        upcomingEvents.value = (resp.data as List)
            .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } on DioException catch (e) {
      if (!silent) Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải sự kiện');
    } finally {
      if (!silent) isLoading.value = false;
    }
  }

  Future<void> fetchPast({bool silent = false}) async {
    try {
      final resp = await ApiClient().dio.get('/events', queryParameters: {'filter': 'past'});
      if (resp.statusCode == 200) {
        pastEvents.value = (resp.data as List)
            .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } on DioException catch (_) {}
  }

  // Dùng filter=registered để BE trả về đầy đủ IsRegistered, IsFull, states
  Future<void> fetchMyRegistrations({bool silent = false}) async {
    try {
      final resp = await ApiClient().dio.get('/events', queryParameters: {'filter': 'registered'});
      if (resp.statusCode == 200) {
        myRegistrations.value = (resp.data as List)
            .map((e) => EventModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } on DioException catch (_) {}
  }

  Future<bool> register(int eventId) async {
    try {
      final resp = await ApiClient().dio.post('/events/$eventId/register');
      if (resp.statusCode == 200) {
        Get.snackbar('🎉 Thành công', 'Đăng ký sự kiện thành công!',
            snackPosition: SnackPosition.BOTTOM);
        // Refresh cả 3 lists
        await Future.wait([fetchUpcoming(silent: true), fetchMyRegistrations(silent: true)]);
        return true;
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Đăng ký thất bại';
      Get.snackbar('Lỗi', msg, snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }

  Future<bool> unregister(int eventId) async {
    try {
      final resp = await ApiClient().dio.delete('/events/$eventId/unregister');
      if (resp.statusCode == 200) {
        Get.snackbar('Đã huỷ', 'Huỷ đăng ký thành công',
            snackPosition: SnackPosition.BOTTOM);
        await Future.wait([fetchUpcoming(silent: true), fetchMyRegistrations(silent: true)]);
        return true;
      }
    } on DioException catch (e) {
      final msg = e.response?.data['message'] ?? 'Huỷ đăng ký thất bại';
      Get.snackbar('Lỗi', msg, snackPosition: SnackPosition.BOTTOM);
    }
    return false;
  }
}
