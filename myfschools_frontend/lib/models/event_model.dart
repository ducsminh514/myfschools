class EventModel {
  final int id;
  final String title;
  final String? description;
  final String? eventType;
  final String? location;
  final String? bannerUrl;
  final String startAt;
  final String endAt;
  final String? startAtRaw; // ISO string để tính countdown
  final int? maxCapacity;
  final int currentRegistrations;
  final int? slotsLeft;
  final bool isRegistered;
  final bool isFull;
  final bool isUpcoming;
  final bool isOngoing;
  final bool isPast;

  EventModel({
    required this.id,
    required this.title,
    this.description,
    this.eventType,
    this.location,
    this.bannerUrl,
    required this.startAt,
    required this.endAt,
    this.startAtRaw,
    this.maxCapacity,
    required this.currentRegistrations,
    this.slotsLeft,
    required this.isRegistered,
    required this.isFull,
    required this.isUpcoming,
    required this.isOngoing,
    required this.isPast,
  });

  factory EventModel.fromJson(Map<String, dynamic> j) {
    T pick<T>(List<String> keys, T fallback) {
      for (final k in keys) {
        if (j.containsKey(k) && j[k] != null) return j[k] as T;
      }
      return fallback;
    }

    return EventModel(
      id:                    pick(['Id', 'id'], 0),
      title:                 pick(['Title', 'title'], ''),
      description:           j['Description'] ?? j['description'],
      eventType:             j['EventType'] ?? j['eventType'],
      location:              j['Location'] ?? j['location'],
      bannerUrl:             j['BannerUrl'] ?? j['bannerUrl'],
      startAt:               pick(['StartAt', 'startAt'], ''),
      endAt:                 pick(['EndAt', 'endAt'], ''),
      startAtRaw:            j['StartAtRaw'] ?? j['startAtRaw'],
      maxCapacity:           j['MaxCapacity'] ?? j['maxCapacity'],
      currentRegistrations:  pick(['CurrentRegistrations', 'currentRegistrations'], 0),
      slotsLeft:             j['SlotsLeft'] ?? j['slotsLeft'],
      isRegistered:          pick(['IsRegistered', 'isRegistered'], false),
      isFull:                pick(['IsFull', 'isFull'], false),
      isUpcoming:            pick(['IsUpcoming', 'isUpcoming'], false),
      isOngoing:             pick(['IsOngoing', 'isOngoing'], false),
      isPast:                pick(['IsPast', 'isPast'], false),
    );
  }

  /// Màu badge theo loại sự kiện
  static const _typeLabels = {
    'hoi_thao':    'Hội thao',
    'van_nghe':    'Văn nghệ',
    'hoi_trai':    'Hội trại',
    'huong_nghiep':'Hướng nghiệp',
    'hoc_thuat':   'Học thuật',
    'khac':        'Khác',
  };

  String get typeLabel => _typeLabels[eventType] ?? 'Sự kiện';
}
