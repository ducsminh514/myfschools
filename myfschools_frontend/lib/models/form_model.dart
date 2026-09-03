class FormModel {
  final int id;
  final String formType;
  final String title;
  final String content;
  final String? absentDate;
  final String? attachmentUrl;
  final String status;
  final String? rejectReason;
  final String? studentName; // Tên học sinh (dành cho Giáo viên)
  final DateTime createdAt;

  FormModel({
    required this.id,
    required this.formType,
    required this.title,
    required this.content,
    this.absentDate,
    this.attachmentUrl,
    required this.status,
    this.rejectReason,
    this.studentName,
    required this.createdAt,
  });

  factory FormModel.fromJson(Map<String, dynamic> json) {
    return FormModel(
      id: json['id'] ?? 0,
      formType: json['formType'] ?? 'Other',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      absentDate: json['absentDate'],
      attachmentUrl: json['attachmentUrl'],
      status: json['status'] ?? 'pending',
      rejectReason: json['rejectReason'],
      studentName: json['studentName'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }
}
