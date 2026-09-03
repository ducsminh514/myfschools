import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../constants/app_colors.dart';
import '../../controllers/messages_controller.dart';
import '../../controllers/home_controller.dart';
import 'chat_detail_page.dart';
import 'widgets/conversation_card.dart';
import 'package:skeletonizer/skeletonizer.dart';

// MessagesBody được nhúng trực tiếp vào HomePage
// để giữ bottom nav luôn hiển thị
class MessagesBody extends StatefulWidget {
  const MessagesBody({super.key});

  @override
  State<MessagesBody> createState() => _MessagesBodyState();
}

class _MessagesBodyState extends State<MessagesBody> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  final _msgCtrl = Get.put(MessagesController());
  late bool _isTeacher;

  @override
  void initState() {
    super.initState();
    final homeCtrl = Get.find<HomeController>();
    _isTeacher = homeCtrl.userInfo.value?.roles.contains('teacher') ?? false;
  }

  /// Nút soạn tin: HS → chọn GV, GV → chọn HS
  void _showContactPicker() {
    if (_isTeacher) {
      _showStudentPicker();
    } else {
      _showTeacherPicker();
    }
  }

  /// HS: Hiện DS giáo viên để chọn nhắn tin
  void _showTeacherPicker() async {

    // Fetch DS GV nếu chưa có
    if (_msgCtrl.myTeachers.isEmpty) {
      await _msgCtrl.fetchMyTeachers();
    }

    if (!mounted) return;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() {
          if (_msgCtrl.isLoadingTeachers.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.orange));
          }
          final teachers = _msgCtrl.myTeachers;
          if (teachers.isEmpty) {
            return const Center(child: Text('Không tìm thấy giáo viên'));
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Giáo viên của tôi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyMid)),
              const SizedBox(height: 4),
              const Text('Chọn giáo viên để bắt đầu trò chuyện',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: teachers.length,
                  itemBuilder: (_, i) {
                    final t = teachers[i];
                    final type = t['type'] == 'GVCN' ? 'Giáo viên chủ nhiệm' : t['subjectName'] ?? 'GVBM';
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: t['type'] == 'GVCN'
                            ? AppColors.orange.withOpacity(0.15)
                            : AppColors.navyMid.withOpacity(0.1),
                        child: Text(
                          (t['name'] ?? '?').toString().split(' ').last[0].toUpperCase(),
                          style: TextStyle(
                            color: t['type'] == 'GVCN' ? AppColors.orange : AppColors.navyMid,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(t['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(type, style: const TextStyle(fontSize: 12)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: t['type'] == 'GVCN' ? AppColors.orange.withOpacity(0.1) : AppColors.navyLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          t['type'] ?? '',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: t['type'] == 'GVCN' ? AppColors.orange : AppColors.navyMid,
                          ),
                        ),
                      ),
                      onTap: () {
                        Get.back();
                        // Tìm conversation đã có hoặc tạo mới
                        final teacherId = t['teacherId'] as int;
                        final existing = _msgCtrl.conversations.firstWhereOrNull(
                          (c) => c.name == t['name'],
                        );
                        if (existing != null) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatDetailPage(conversation: existing),
                          ));
                        } else {
                          // Tạo mới conversation
                          _msgCtrl.startConversation(teacherId).then((convId) {
                            if (convId != null) {
                              _msgCtrl.fetchConversations().then((_) {
                                final newConv = _msgCtrl.conversations.firstWhereOrNull((c) => c.id == convId);
                                if (newConv != null && mounted) {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => ChatDetailPage(conversation: newConv),
                                  ));
                                }
                              });
                            }
                          });
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  /// GV: Hiện DS học sinh để chọn nhắn tin
  void _showStudentPicker() async {
    if (_msgCtrl.myStudents.isEmpty) {
      await _msgCtrl.fetchMyStudents();
    }
    if (!mounted) return;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Obx(() {
          if (_msgCtrl.isLoadingStudents.value) {
            return const Center(child: CircularProgressIndicator(color: AppColors.orange));
          }
          final students = _msgCtrl.myStudents;
          if (students.isEmpty) {
            return const Center(child: Text('Không tìm thấy học sinh'));
          }

          // Group theo lớp
          final grouped = <String, List<Map<String, dynamic>>>{};
          for (final s in students) {
            final cls = s['className'] ?? 'Khác';
            grouped.putIfAbsent(cls, () => []).add(s);
          }
          final classNames = grouped.keys.toList()..sort();

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Học sinh của tôi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navyMid)),
              const SizedBox(height: 4),
              Text('${students.length} học sinh',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: classNames.length,
                  itemBuilder: (_, ci) {
                    final cls = classNames[ci];
                    final list = grouped[cls]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text('Lớp $cls', style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.orange)),
                        ),
                        ...list.map((s) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.navyMid.withOpacity(0.1),
                            child: Text(
                              (s['name'] ?? '?').toString().split(' ').last[0].toUpperCase(),
                              style: const TextStyle(color: AppColors.navyMid, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          title: Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(s['studentCode'] ?? '', style: const TextStyle(fontSize: 11)),
                          onTap: () {
                            Get.back();
                            final studentId = s['studentId'] as int;
                            final existing = _msgCtrl.conversations.firstWhereOrNull(
                              (c) => c.name == s['name'],
                            );
                            if (existing != null) {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ChatDetailPage(conversation: existing),
                              ));
                            } else {
                              _msgCtrl.startConversation(studentId).then((convId) {
                                if (convId != null) {
                                  _msgCtrl.fetchConversations().then((_) {
                                    final newConv = _msgCtrl.conversations.firstWhereOrNull((c) => c.id == convId);
                                    if (newConv != null && mounted) {
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (_) => ChatDetailPage(conversation: newConv),
                                      ));
                                    }
                                  });
                                }
                              });
                            }
                          },
                        )),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ConversationItem> get _currentList =>
      _isTeacher ? _msgCtrl.studentList : _msgCtrl.teacherList;

  List<ConversationItem> get _filtered {
    // Luôn cung cấp mảng giả nếu đang Loading để Skeletonizer có UI dựng hình
    if (_msgCtrl.isLoading.value && _currentList.isEmpty) {
      return List.generate(5, (index) => ConversationItem(
        id: 0, name: 'Đang tải dữ liệu', role: 'Giáo viên',
        lastMessage: 'Đang tải dữ liệu vui lòng chờ', time: '00:00',
        unread: 0, isOnline: false, type: 'teacher'
      ));
    }

    if (_searchQuery.isEmpty) return _currentList;
    final q = _searchQuery.toLowerCase();
    return _currentList
        .where((c) =>
    c.name.toLowerCase().contains(q) ||
        c.lastMessage.toLowerCase().contains(q))
        .toList();
  }

  int get _totalUnread => _msgCtrl.totalUnread;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Obx(() {
        return Skeletonizer(
          enabled: _msgCtrl.isLoading.value,
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(child: _buildList()),
            ],
          ),
        );
      }),
    );
  }

  // ── Header ──
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navyMid],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Text(
              'Tin nhắn',
              style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            // Nút soạn tin mới: HS bấm → hiện DS giáo viên
            GestureDetector(
              onTap: _showContactPicker,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }



  // ── Search bar ──
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm tin nhắn...',
          hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppColors.textLight, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close, color: AppColors.textLight, size: 18),
            onPressed: () => setState(() {
              _searchCtrl.clear();
              _searchQuery = '';
            }),
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Danh sách hội thoại ──
  Widget _buildList() {
    if (_filtered.isEmpty && !_msgCtrl.isLoading.value) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline,
                size: 52, color: AppColors.textLight.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text(
              'Không tìm thấy tin nhắn',
              style: TextStyle(color: AppColors.textLight, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: _filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) => ConversationCard(
        item: _filtered[i],
        onTap: () {
          if (!_msgCtrl.isLoading.value) {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(conversation: _filtered[i]),
              ),
            ).then((_) {
              // Reload List sau khi đọc Message
              _msgCtrl.fetchConversations();
            });
          }
        },
      ),
    );
  }
}