import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/models/home_models.dart' ;
import 'package:myfschools/controllers/home_controller.dart';
import 'package:myfschools/screens/home/widgets/feature_grid.dart';
import 'package:myfschools/screens/home/widgets/schedule_card.dart';
import 'package:myfschools/screens/home/widgets/notice_card.dart';
import 'package:myfschools/screens/home/widgets/bottom_nav.dart';
import 'package:myfschools/screens/home/widgets/home_header.dart';
import 'package:myfschools/screens/profile/profile_page.dart';
import 'package:myfschools/screens/schedule/weekly_schedule_page.dart';
import 'package:myfschools/screens/grades/grades_page.dart';
import 'package:myfschools/screens/forms/form_list_page.dart';
import 'package:myfschools/controllers/notifications_controller.dart';
import 'package:myfschools/screens/notifications/notifications_page.dart';
import 'package:myfschools/screens/messages/messages_page.dart';
import 'package:myfschools/screens/attendance/attendance_history_page.dart';
import 'package:myfschools/screens/attendance/attendance_sheet_page.dart';
import 'package:myfschools/screens/class_management/class_management_page.dart';
import 'package:myfschools/screens/grades/grade_entry_page.dart';
import 'package:myfschools/screens/events/events_page.dart';
import 'package:myfschools/screens/clubs/clubs_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tabIndex = 0;
  final HomeController _homeCtrl = Get.put(HomeController());
  final _ = Get.put(NotificationsController()); // Phải put trước khi HomeHeader gọi Get.find

  // --- Features list (vẫn để tạm do chưa có API cấu hình menu động) ---

  List<FeatureItem> _getFilteredFeatures(List<String> roles) {
    final features = <FeatureItem>[];
    bool isStudent = roles.contains('student');
    bool isTeacher = roles.contains('teacher');

    // Luôn hiển thị (Dùng chung)
    features.add(const FeatureItem(icon: Icons.notifications_outlined, label: 'Thông báo', color: AppColors.orange, bg: AppColors.orangeSoft));

    if (isStudent) {
      features.add(const FeatureItem(icon: Icons.campaign_outlined, label: 'Sự Kiện', color: AppColors.navyMid, bg: AppColors.navyLight));
      features.add(const FeatureItem(icon: Icons.bar_chart_rounded, label: 'Điểm HK', color: AppColors.orange, bg: AppColors.orangeSoft));
      features.add(const FeatureItem(icon: Icons.calendar_month_outlined, label: 'Lịch Học', color: AppColors.navyMid, bg: AppColors.navyLight));
      features.add(const FeatureItem(icon: Icons.description_outlined, label: 'Đơn Từ', color: AppColors.orange, bg: AppColors.orangeSoft));
      features.add(const FeatureItem(icon: Icons.how_to_reg_outlined, label: 'Điểm danh', color: AppColors.green, bg: AppColors.greenLight));
      features.add(const FeatureItem(icon: Icons.emoji_events_outlined, label: 'CLB', color: AppColors.green, bg: AppColors.greenLight));
    }

    if (isTeacher) {
      // Mọi GV đều có Nhập điểm
      features.add(const FeatureItem(icon: Icons.edit_note_outlined, label: 'Nhập điểm', color: AppColors.navyMid, bg: AppColors.navyLight));
    }

    // Chỉ GVCN mới có Duyệt Đơn + Điểm danh + Quản lý lớp
    if (isTeacher && _homeCtrl.userInfo.value?.isHomeroom == true) {
      features.add(const FeatureItem(icon: Icons.groups_outlined, label: 'Quản lý lớp', color: AppColors.navyMid, bg: AppColors.navyLight));
      features.add(const FeatureItem(icon: Icons.fact_check_outlined, label: 'Duyệt Đơn', color: AppColors.green, bg: AppColors.greenLight));
      features.add(const FeatureItem(icon: Icons.how_to_reg_outlined, label: 'Điểm danh', color: AppColors.orange, bg: AppColors.orangeSoft));
    }

    return features;
  }

  /// Bottom sheet chọn lớp/môn để nhập điểm
  void _showSubjectPicker() {
    final subjects = _homeCtrl.userInfo.value?.teachingSubjects ?? [];
    if (subjects.isEmpty) {
      Get.snackbar('Thông báo', 'Bạn chưa được phân công giảng dạy môn nào',
        snackPosition: SnackPosition.BOTTOM);
      return;
    }
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Chọn lớp / môn để nhập điểm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...subjects.map((s) => ListTile(
              leading: const Icon(Icons.class_outlined, color: AppColors.navyMid),
              title: Text(s.subjectName),
              subtitle: Text(s.className),
              onTap: () {
                Get.back();
                Get.to(() => GradeEntryPage(classSubjectId: s.id),
                  transition: Transition.cupertino);
              },
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent(UserInfo user) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Skeletonizer(
            enabled: _homeCtrl.isLoading.value,
            child: HomeHeader(user: user),
          ),
        ),
        Expanded(
          child: Skeletonizer(
            enabled: _homeCtrl.isLoading.value,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      FeatureGrid(
                        items: _getFilteredFeatures(user.roles),
                        onTap: (item) {
                          if (item.label == 'Điểm HK') {
                            Get.to(() => const GradesPage(), transition: Transition.cupertino);
                          } else if (item.label == 'Lịch Học') {
                            setState(() => _tabIndex = 2);
                          } else if (item.label == 'Đơn Từ') {
                            Get.to(() => const FormListPage(), transition: Transition.cupertino);
                          } else if (item.label == 'Duyệt Đơn') {
                            Get.to(() => const FormListPage(), transition: Transition.cupertino);
                          } else if (item.label == 'Thông báo') {
                            Get.to(() => const NotificationsPage(), transition: Transition.cupertino);
                          } else if (item.label == 'Điểm danh') {
                            if (user.roles.contains('teacher')) {
                              Get.to(() => const AttendanceSheetPage(), transition: Transition.cupertino);
                            } else {
                              Get.to(() => const AttendanceHistoryPage(), transition: Transition.cupertino);
                            }
                          } else if (item.label == 'Nhập điểm') {
                            _showSubjectPicker();
                          } else if (item.label == 'Quản lý lớp') {
                            Get.to(() => const ClassManagementPage(), transition: Transition.cupertino);
                          } else if (item.label == 'Sự Kiện') {
                            Get.to(() => const EventsPage(), transition: Transition.cupertino);
                          } else if (item.label == 'CLB') {
                            Get.to(() => const ClubsPage(), transition: Transition.cupertino);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                          if (_homeCtrl.todaySchedule.isNotEmpty)
                            ScheduleCard(
                              items: _homeCtrl.todaySchedule,
                              onSeeMore: () => setState(() => _tabIndex = 2),
                            )
                          else
                            _buildEmptySchedule(),
                      const SizedBox(height: 24),
                      NoticeCard(
                        items: _homeCtrl.notices.isNotEmpty
                            ? _homeCtrl.notices
                            : [
                                const NoticeItem(
                                  title: 'Không có thông báo mới',
                                  tag: 'Hệ thống',
                                  tagColor: AppColors.navyLight,
                                ),
                              ],
                      ),
                      const SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }



  Widget _buildEmptySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('LỊCH HÔM NAY', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.navy, letterSpacing: 0.5)),
            TextButton(
              onPressed: () => setState(() => _tabIndex = 2),
              child: const Text('Xem thêm →',
                  style: TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            children: [
              Icon(Icons.event_available, size: 40, color: AppColors.green.withOpacity(0.6)),
              const SizedBox(height: 8),
              const Text('Hôm nay không có lịch dạy',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Nghỉ ngơi hoặc xem lịch tuần để chuẩn bị',
                style: TextStyle(fontSize: 12, color: AppColors.textSub)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getBody(UserInfo user) {
    switch (_tabIndex) {
      case 0: return _buildHomeContent(user);
      case 1: return const MessagesBody();
      case 2: return const WeeklySchedulePage();
      case 3: return const ProfilePage();
      default: return _buildHomeContent(user);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Obx(() {
        // Lấy Data động từ State Manager (API /home/dashboard)
        final user = _homeCtrl.userInfo.value ?? const UserInfo(
          name: 'Đang tải...',
          className: '---',
          id: '---',
          gpa: 0,
          attendance: 0,
          pendingForms: 0,
        );

        return Column(
          children: [
            Expanded(child: _getBody(user)),

            // Bottom nav
            HomeBottomNav(
              currentIndex: _tabIndex,
              onTap: (i) => setState(() => _tabIndex = i),
            ),
          ],
        );
      }),
    );
  }
}