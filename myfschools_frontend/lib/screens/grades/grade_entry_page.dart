import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:myfschools/constants/app_colors.dart';
import 'package:myfschools/services/api_client.dart';

/// Controller quản lý state nhập điểm cho GV
class GradeEntryController extends GetxController {
  final RxBool isLoading      = false.obs;
  final RxBool isSaving       = false.obs;
  final RxString subjectName  = ''.obs;
  final RxString className    = ''.obs;
  final RxList<Map<String, dynamic>> students = <Map<String, dynamic>>[].obs;

  Future<void> fetchClassGrades(int classSubjectId) async {
    isLoading.value = true;
    try {
      final resp = await ApiClient().dio.get('/grades/class', queryParameters: {'classSubjectId': classSubjectId});
      if (resp.statusCode == 200) {
        subjectName.value = resp.data['subject'] ?? '';
        className.value   = resp.data['className'] ?? '';
        students.value    = List<Map<String, dynamic>>.from(
          (resp.data['students'] as List).map((e) => Map<String, dynamic>.from(e))
        );
      }
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể tải bảng điểm');
    } finally {
      isLoading.value = false;
    }
  }

  /// Lưu điểm — FIX: trả về updated data từ server + cập nhật list
  Future<bool> saveGrade(int classSubjectId, Map<String, dynamic> studentData, int index) async {
    isSaving.value = true;
    try {
      final gradeId = studentData['gradeId'];
      final body = {
        'studentId': studentData['studentId'],
        'classSubjectId': classSubjectId,
        'scoreOral':  studentData['scoreOral'],
        'score15m1': studentData['score15m1'], 'score15m2': studentData['score15m2'], 'score15m3': studentData['score15m3'],
        'score1h1':  studentData['score1h1'],  'score1h2':  studentData['score1h2'],  'score1h3':  studentData['score1h3'],
        'scoreFinal': studentData['scoreFinal'],
      };
      final resp = await ApiClient().dio.put('/grades/${gradeId ?? 0}', data: body);

      if (resp.statusCode == 200) {
        // FIX #2: Cập nhật GPA real-time vào list
        final newGpa = resp.data['gpaSubject'];
        if (index >= 0 && index < students.length) {
          students[index] = {
            ...students[index],
            ...studentData,
            'gpaSubject': newGpa,
          };
          students.refresh(); // trigger Obx rebuild
        }
        Get.snackbar('Đã lưu', 'GPA môn: ${newGpa ?? 'N/A'}',
          backgroundColor: Colors.green.shade50, colorText: Colors.green.shade800);
        return true;
      }
      return false;
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Lưu điểm thất bại');
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> finalizeGrades(int classSubjectId) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Chốt điểm?'),
        content: const Text('Sau khi chốt, điểm sẽ không thể chỉnh sửa. Bạn có chắc chắn?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Chốt điểm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ApiClient().dio.post('/grades/finalize/$classSubjectId');
      Get.snackbar('Đã chốt', 'Điểm học kỳ đã được khóa',
        backgroundColor: Colors.orange.shade50, colorText: AppColors.orange);
      fetchClassGrades(classSubjectId); // Reload để cập nhật isFinalized flag
    } on DioException catch (e) {
      Get.snackbar('Lỗi', e.response?.data['message'] ?? 'Không thể chốt điểm');
    }
  }
}

/// Màn hình nhập điểm cho Giáo viên
class GradeEntryPage extends StatefulWidget {
  final int classSubjectId;
  const GradeEntryPage({super.key, required this.classSubjectId});

  @override
  State<GradeEntryPage> createState() => _GradeEntryPageState();
}

class _GradeEntryPageState extends State<GradeEntryPage> {
  late final GradeEntryController ctrl;

  @override
  void initState() {
    super.initState();
    ctrl = Get.put(GradeEntryController());
    ctrl.fetchClassGrades(widget.classSubjectId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Obx(() => Text(
          ctrl.subjectName.isNotEmpty ? ctrl.subjectName.value : 'Nhập điểm',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        )),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock, color: Colors.white),
            tooltip: 'Chốt điểm',
            onPressed: () => ctrl.finalizeGrades(widget.classSubjectId),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.orange));
        }
        if (ctrl.students.isEmpty) {
          return const Center(child: Text('Không có học sinh nào', style: TextStyle(color: Colors.grey)));
        }

        return Column(
          children: [
            // FIX #5: Header info lớp/môn rõ ràng
            _buildClassHeader(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: ctrl.students.length,
                itemBuilder: (ctx, i) {
                  final student = ctrl.students[i];
                  final isFinalized = student['isFinalized'] == true;
                  return _StudentGradeCard(
                    student: student,
                    index: i,
                    isFinalized: isFinalized,
                    classSubjectId: widget.classSubjectId,
                    ctrl: ctrl,
                  );
                },
              ),
            ),
          ],
        );
      }),
    );
  }

  /// FIX #5: Header hiện tên lớp, tên môn, số HS
  Widget _buildClassHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      decoration: const BoxDecoration(
        color: AppColors.orange,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => Text(
                  'Lớp ${ctrl.className.value}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                )),
                const SizedBox(height: 2),
                Obx(() => Text(
                  'Môn: ${ctrl.subjectName.value}',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                )),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Obx(() => Text(
              '${ctrl.students.length} HS',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            )),
          ),
        ],
      ),
    );
  }
}

/// FIX #1: InputFormatter giới hạn điểm 0-10
class _ScoreInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final value = double.tryParse(newValue.text);
    if (value == null) return oldValue;
    if (value < 0 || value > 10) return oldValue;
    return newValue;
  }
}

class _StudentGradeCard extends StatefulWidget {
  final Map<String, dynamic> student;
  final int index;
  final bool isFinalized;
  final int classSubjectId;
  final GradeEntryController ctrl;
  const _StudentGradeCard({
    required this.student,
    required this.index,
    required this.isFinalized,
    required this.classSubjectId,
    required this.ctrl,
  });

  @override
  State<_StudentGradeCard> createState() => _StudentGradeCardState();
}

class _StudentGradeCardState extends State<_StudentGradeCard> {
  // Controllers cho từng ô điểm
  late Map<String, TextEditingController> _ctrls;

  @override
  void initState() {
    super.initState();
    _ctrls = {
      'scoreOral':  TextEditingController(text: _fmt(widget.student['scoreOral'])),
      'score15m1': TextEditingController(text: _fmt(widget.student['score15m1'])),
      'score15m2': TextEditingController(text: _fmt(widget.student['score15m2'])),
      'score15m3': TextEditingController(text: _fmt(widget.student['score15m3'])),
      'score1h1':  TextEditingController(text: _fmt(widget.student['score1h1'])),
      'score1h2':  TextEditingController(text: _fmt(widget.student['score1h2'])),
      'score1h3':  TextEditingController(text: _fmt(widget.student['score1h3'])),
      'scoreFinal':TextEditingController(text: _fmt(widget.student['scoreFinal'])),
    };
  }

  String _fmt(dynamic v) => v == null ? '' : v.toString();
  double? _parseScore(String key) => double.tryParse(_ctrls[key]!.text);

  /// FIX #4: Build data TRƯỚC, rồi gọi saveGrade CÓ await — không race condition
  Future<void> _handleSave() async {
    final updated = {
      ...widget.student,
      'scoreOral':  _parseScore('scoreOral'),
      'score15m1': _parseScore('score15m1'), 'score15m2': _parseScore('score15m2'), 'score15m3': _parseScore('score15m3'),
      'score1h1':  _parseScore('score1h1'),  'score1h2':  _parseScore('score1h2'),  'score1h3':  _parseScore('score1h3'),
      'scoreFinal': _parseScore('scoreFinal'),
    };
    // FIX #4: Truyền data hoàn chỉnh + index vào controller, không mutate widget.student trực tiếp
    await widget.ctrl.saveGrade(widget.classSubjectId, updated, widget.index);
  }

  @override
  void dispose() {
    for (var c in _ctrls.values) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gpa = widget.student['gpaSubject'];

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.orangeSoft,
          child: Text(
            (widget.student['studentName'] as String?)?.isNotEmpty == true
                ? (widget.student['studentName'] as String)[0].toUpperCase()
                : '?',
            style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(widget.student['studentName'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.navy)),
        subtitle: Text(
          gpa != null ? 'GPA: $gpa${widget.isFinalized ? ' 🔒' : ''}' : 'Chưa nhập điểm',
          style: TextStyle(fontSize: 12, color: gpa != null ? AppColors.orange : Colors.grey),
        ),
        children: widget.isFinalized
            ? [const Padding(padding: EdgeInsets.all(12), child: Text('Điểm đã được chốt 🔒', style: TextStyle(color: Colors.grey)))]
            : [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _scoreRow('Điểm miệng', ['scoreOral']),
                      _scoreRow('Điểm 15p', ['score15m1', 'score15m2', 'score15m3']),
                      _scoreRow('Điểm 1 tiết', ['score1h1', 'score1h2', 'score1h3']),
                      _scoreRow('Cuối kỳ', ['scoreFinal']),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Lưu điểm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          // FIX #4: async save, không race condition
                          onPressed: _handleSave,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                )
              ],
      ),
    );
  }

  Widget _scoreRow(String label, List<String> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey))),
          ...keys.map((k) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: TextField(
                controller: _ctrls[k],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                // FIX #1: Validate điểm phải 0-10
                inputFormatters: [_ScoreInputFormatter()],
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '0.0',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.orange),
                  ),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
