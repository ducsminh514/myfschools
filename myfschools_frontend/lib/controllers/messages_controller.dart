import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../services/api_client.dart';

class ConversationItem {
  final int id;
  final String name;
  final String role;
  final String avatarUrl;
  final String lastMessage;
  final String time;
  final int unread;
  final bool isOnline;
  final String type;

  ConversationItem({
    required this.id,
    required this.name,
    required this.role,
    this.avatarUrl = '',
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.isOnline,
    required this.type,
  });

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      id: json['id'] ?? 0,
      name: json['targetName'] ?? '',
      role: json['targetRole'] ?? '',
      avatarUrl: json['targetAvatarUrl'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      time: json['time'] ?? '',
      unread: json['unreadCount'] ?? 0,
      isOnline: json['isOnline'] ?? false,
      type: json['type'] ?? 'teacher',
    );
  }
}

class ChatMessage {
  final int id;
  final int senderId;
  final bool isMe;
  final String content;
  final String time;
  final String date;
  final bool isRead;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.isMe,
    required this.content,
    required this.time,
    required this.date,
    required this.isRead,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? 0,
      senderId: json['senderId'] ?? 0,
      isMe: json['isMe'] ?? false,
      content: json['content'] ?? '',
      time: json['time'] ?? '',
      date: json['date'] ?? '',
      isRead: json['isRead'] ?? false,
    );
  }
}

class MessagesController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxList<ConversationItem> conversations = <ConversationItem>[].obs;
  final RxList<ChatMessage> currentMessages = <ChatMessage>[].obs;
  final RxInt currentUserId = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchConversations();
  }

  Future<void> fetchConversations() async {
    isLoading.value = true;
    try {
      final response = await ApiClient().dio.get('/messages/conversations');
      if (response.statusCode == 200) {
        conversations.value = (response.data as List)
            .map((e) => ConversationItem.fromJson(e))
            .toList();
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải tin nhắn');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> getChatDetail(int conversationId) async {
    currentMessages.clear();
    try {
      final response = await ApiClient().dio.get('/messages/$conversationId');
      if (response.statusCode == 200) {
        final data = response.data;
        // Trích xuất list messages từ ConversationDetailResponse
        if (data['messages'] != null) {
          final List<ChatMessage> msgs = (data['messages'] as List)
              .map((e) => ChatMessage.fromJson(e))
              .toList();
          currentMessages.value = msgs;
          // Xác định ID user hiện tại dựa trên người gửi khác với giáo viên
          // (Tạm thời suy diễn để gán isMe nếu DB không trả về UserID rõ)
          // Cập nhật lại UI sẽ tính isMe sau.
        }
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải chi tiết');
    }
  }

  Future<bool> sendMessage(int conversationId, String content) async {
    try {
      final response = await ApiClient().dio.post(
          '/messages/$conversationId/send',
          data: {'content': content});
      if (response.statusCode == 200) {
        // Thêm tin nhắn mới vào list hiện tại để UI tự update
        final newMsg = ChatMessage.fromJson(response.data);
        currentMessages.add(newMsg);
        fetchConversations(); // Update lại list ngoài màng hình home
        return true;
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể gửi tin');
    }
    return false;
  }

  int get totalUnread => conversations.fold(0, (sum, c) => sum + c.unread);
  
  List<ConversationItem> get teacherList => conversations.where((c) => c.type == 'teacher').toList();
  List<ConversationItem> get studentList => conversations.where((c) => c.type == 'student').toList();
  List<ConversationItem> get adminList => conversations.where((c) => c.type != 'teacher' && c.type != 'student').toList();

  // ── DS giáo viên cho HS chọn nhắn tin ──
  final RxList<Map<String, dynamic>> myTeachers = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingTeachers = false.obs;

  Future<void> fetchMyTeachers() async {
    isLoadingTeachers.value = true;
    try {
      final resp = await ApiClient().dio.get('/messages/my-teachers');
      if (resp.statusCode == 200) {
        myTeachers.value = List<Map<String, dynamic>>.from(resp.data);
      }
    } catch (_) {}
    isLoadingTeachers.value = false;
  }

  // ── DS học sinh cho GV chọn nhắn tin ──
  final RxList<Map<String, dynamic>> myStudents = <Map<String, dynamic>>[].obs;
  final RxBool isLoadingStudents = false.obs;

  Future<void> fetchMyStudents() async {
    isLoadingStudents.value = true;
    try {
      final resp = await ApiClient().dio.get('/messages/my-students');
      if (resp.statusCode == 200) {
        myStudents.value = List<Map<String, dynamic>>.from(resp.data);
      }
    } catch (_) {}
    isLoadingStudents.value = false;
  }

  /// Tạo hoặc tìm conversation với 1 GV → trả conversationId
  Future<int?> startConversation(int teacherId) async {
    try {
      final resp = await ApiClient().dio.post('/messages/start', data: {'targetUserId': teacherId});
      if (resp.statusCode == 200) {
        fetchConversations();
        return resp.data['conversationId'];
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể bắt đầu cuộc trò chuyện');
    }
    return null;
  }
}
