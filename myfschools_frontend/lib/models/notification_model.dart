class NotificationModel {
  final int id;
  final String title;
  final String body;
  final String notiType;
  final int? refId;
  final String? refType;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.notiType,
    this.refId,
    this.refType,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      notiType: json['notiType'],
      refId: json['refId'],
      refType: json['refType'],
      isRead: json['isRead'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
