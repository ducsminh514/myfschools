import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:myfschools/screens/login.dart';
import 'package:myfschools/screens/home/home_page.dart';
import 'package:myfschools/controllers/auth_controller.dart';
import 'package:myfschools/screens/forms/form_list_page.dart';
import 'package:myfschools/screens/notifications/notifications_page.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Bắt buộc khai báo khi dùng SharedPreferences ở hàm main/Init
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi'); // Init locale 'vi' cho DateFormat
  runApp(const MyApp());
}

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AuthController(), permanent: true);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'FPT School',
      debugShowCheckedModeBanner: false,
      initialBinding: InitialBinding(), // Chạy cục Binding tiêm Dependencies
      home: const RootScreen(), // Kiểm soát luồng ở Root
        getPages: [
          GetPage(name: '/login', page: () => const LoginPage()),
          GetPage(name: '/home', page: () => const HomePage()),
          GetPage(name: '/forms', page: () => const FormListPage()),
          GetPage(name: '/notifications', page: () => const NotificationsPage()),
        ],
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GetX<AuthController>(
          builder: (auth) {
            // Check coi trong SharePref có báo token chưa
            if (auth.currentUser.value != null) {
              return const HomePage();
            }
            // Không có thì bay về Login
            return const LoginPage();
          },
        ),
      ),
    );
  }
}