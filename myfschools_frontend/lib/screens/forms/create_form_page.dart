import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../controllers/forms_controller.dart';
import '../../services/api_client.dart';

class CreateFormPage extends StatefulWidget {
  const CreateFormPage({super.key});

  @override
  State<CreateFormPage> createState() => _CreateFormPageState();
}

class _CreateFormPageState extends State<CreateFormPage> {
  final FormsController _formsCtrl = Get.find<FormsController>();
  final _formKey = GlobalKey<FormState>();

  String _selectedFormType = 'nghi_hoc';
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  DateTime? _selectedAbsentDate;
  XFile? _selectedImage;
  int? _assignedTo; // null = gửi GVCN mặc định
  List<Map<String, dynamic>> _teacherList = [];
  bool _loadingTeachers = true;
  
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    try {
      final res = await ApiClient().dio.get('messages/my-teachers');
      if (res.statusCode == 200) {
        setState(() {
          _teacherList = List<Map<String, dynamic>>.from(res.data);
        });
      }
    } catch (_) {}
    setState(() => _loadingTeachers = false);
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.navyMid),
              title: const Text('Chọn từ Thư viện'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  // TỐI ƯU HẠ TẦNG NÉN MÁY CHỦ BẰNG LOSSY COMPRESSION
                  maxWidth: 1920,
                  maxHeight: 1920,
                  imageQuality: 80, // Giảm chất lượng màu xuống 80% (Cứu băng thông)
                );
                if (picked != null) setState(() => _selectedImage = picked);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.orange),
              title: const Text('Chụp ảnh mới'),
              onTap: () async {
                Navigator.pop(context);
                final picked = await _picker.pickImage(
                  source: ImageSource.camera,
                  maxWidth: 1920,
                  maxHeight: 1920,
                  imageQuality: 80, 
                );
                if (picked != null) setState(() => _selectedImage = picked);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _submitData() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Nếu chọn Xin Nghỉ Học hoặc Phép Ra Ngoài mà quên không chọn ngày thì huỷ.
    if ((_selectedFormType == 'nghi_hoc' || _selectedFormType == 'phep_ra_ngoai') && _selectedAbsentDate == null) {
      Get.snackbar('Lỗi', 'Vui lòng chọn Ngày xin nghỉ', backgroundColor: Colors.red.withOpacity(0.1), colorText: Colors.red);
      return;
    }

    // Convert DateTime to YYYY-MM-DD
    String? dateStr;
    if (_selectedAbsentDate != null) {
      dateStr = '${_selectedAbsentDate!.year}-${_selectedAbsentDate!.month.toString().padLeft(2, '0')}-${_selectedAbsentDate!.day.toString().padLeft(2, '0')}';
    }

    final success = await _formsCtrl.createForm(
      formType: _selectedFormType,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      absentDate: dateStr,
      attachment: _selectedImage,
      assignedTo: _assignedTo,
    );

    if (success) {
      Get.back(); // Trở về mảng Form List sau khi thành công.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Viết đơn mới', style: TextStyle(color: AppColors.navyMid, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: AppColors.navyMid), onPressed: () => Get.back()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chọn loại Đơn
              const Text('Loại Đơn', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyMid)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedFormType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: const [
                  DropdownMenuItem(value: 'nghi_hoc', child: Text('Đơn xin nghỉ học')),
                  DropdownMenuItem(value: 'phep_ra_ngoai', child: Text('Đơn xin phép ra ngoài')),
                  DropdownMenuItem(value: 'mien_hoan_thi', child: Text('Đơn xin miễn/hoãn thi')),
                  DropdownMenuItem(value: 'khieu_nai_diem', child: Text('Đơn khiếu nại điểm')),
                  DropdownMenuItem(value: 'xac_nhan_hoc_sinh', child: Text('Xin giấy xác nhận Học sinh')),
                  DropdownMenuItem(value: 'khac', child: Text('Ý kiến khác / Phản hồi')),
                ],
                onChanged: (val) {
                  setState(() => _selectedFormType = val!);
                },
              ),
              const SizedBox(height: 20),

              // Chọn gửi cho GV nào
              const Text('Gửi đơn cho', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyMid)),
              const SizedBox(height: 8),
              _loadingTeachers
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                  : DropdownButtonFormField<int?>(
                      value: _assignedTo,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('GVCN lớp (mặc định)')),
                        ..._teacherList.map((t) => DropdownMenuItem<int?>(
                          value: t['teacherId'] as int,
                          child: Text('${t['name']} (${t['type'] == 'GVCN' ? 'GVCN' : t['subjectName'] ?? 'GVBM'})'),
                        )),
                      ],
                      onChanged: (val) => setState(() => _assignedTo = val),
                    ),
              const SizedBox(height: 20),

              // Nếu là Nghỉ học/Ra ngoài thì hiện Picker Date
              if (_selectedFormType == 'nghi_hoc' || _selectedFormType == 'phep_ra_ngoai') ...[
                const Text('Ngày nghỉ nộp đơn', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyMid)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 3)), // Cho phép nghỉ nguội lùi 3 ngày
                      lastDate: DateTime.now().add(const Duration(days: 60)), // Hoặc nghỉ tương lai
                    );
                    if (picked != null) setState(() => _selectedAbsentDate = picked);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      _selectedAbsentDate == null 
                          ? 'Chọn ngày nghỉ...' 
                          : '${_selectedAbsentDate!.day}/${_selectedAbsentDate!.month}/${_selectedAbsentDate!.year}',
                      style: TextStyle(color: _selectedAbsentDate == null ? Colors.grey : Colors.black, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Tiêu đề
              const Text('Tiêu đề', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyMid)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                validator: (val) => val == null || val.isEmpty ? 'Hãy nhập tiêu đề đơn' : null,
                decoration: InputDecoration(
                  hintText: 'VD: Xin nghỉ ốm, V/v tham gia Hội thao, ...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Nội dung chi tiết
              const Text('Nội dung / Lý do cụ thể', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyMid)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                validator: (val) => val == null || val.length < 10 ? 'Vui lòng mô tả ít nhất 10 ký tự' : null,
                decoration: InputDecoration(
                  hintText: 'Ghi chi tiết hoàn cảnh...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // Hình ảnh Đính kèm
              const Text('Tệp đính kèm (Ảnh minh chứng)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navyMid)),
              const SizedBox(height: 8),
              if (_selectedImage != null)
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_selectedImage!.path), 
                        width: double.infinity, 
                        height: 200, 
                        fit: BoxFit.cover
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.white),
                      onPressed: () => setState(() => _selectedImage = null),
                    )
                  ],
                )
              else
                InkWell(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Tải ảnh lên (Khám bệnh, Chữ ký...)', style: TextStyle(color: Colors.grey)),
                        Text('Được tự động nén Full HD', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 40),

              // Nút Submit
              Obx(() => SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _formsCtrl.isSubmitting.value ? null : _submitData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _formsCtrl.isSubmitting.value
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Gửi Đơn', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }
}
