class ClubSessionModel {
  final int id;
  final String title;
  final String? location;
  final String sessionAt;

  ClubSessionModel({required this.id, required this.title, this.location, required this.sessionAt});

  factory ClubSessionModel.fromJson(Map<String, dynamic> j) => ClubSessionModel(
    id:        j['Id'] ?? j['id'] ?? 0,
    title:     j['Title'] ?? j['title'] ?? '',
    location:  j['Location'] ?? j['location'],
    sessionAt: j['SessionAt'] ?? j['sessionAt'] ?? '',
  );
}

class ClubMemberModel {
  final int id;
  final int studentId;
  final String name;
  final String? className;
  final String role;
  final String joinedAt;

  ClubMemberModel({
    required this.id, required this.studentId, required this.name,
    this.className, required this.role, required this.joinedAt,
  });

  factory ClubMemberModel.fromJson(Map<String, dynamic> j) => ClubMemberModel(
    id:        j['Id'] ?? j['id'] ?? 0,
    studentId: j['StudentId'] ?? j['studentId'] ?? 0,
    name:      j['Name'] ?? j['name'] ?? '',
    className: j['ClassName'] ?? j['className'],
    role:      j['Role'] ?? j['role'] ?? 'member',
    joinedAt:  j['JoinedAt'] ?? j['joinedAt'] ?? '',
  );
}

class ClubModel {
  final int id;
  final String name;
  final String? clubType;
  final String typeLabel;
  final String? description;
  final String? logoUrl;
  final int? advisorId;
  final String? advisorName;
  final int memberCount;
  final int? maxMembers;
  // memberStatus: 'none' | 'pending' | 'approved' | 'rejected'
  final String memberStatus;
  final String? myRole;
  final bool isLeader;
  // regStatus: 'not_open' | 'open' | 'closed' | 'full'
  final String regStatus;
  final String? regOpenAt;
  final String? regCloseAt;

  // Chi tiết (chỉ có ở GetClub endpoint)
  final List<ClubMemberModel> members;
  final List<ClubSessionModel> sessions;

  // CLB của tôi: lịch sinh hoạt tiếp theo
  final Map<String, dynamic>? nextSession;

  ClubModel({
    required this.id,
    required this.name,
    this.clubType,
    required this.typeLabel,
    this.description,
    this.logoUrl,
    this.advisorId,
    this.advisorName,
    required this.memberCount,
    this.maxMembers,
    required this.memberStatus,
    this.myRole,
    required this.isLeader,
    required this.regStatus,
    this.regOpenAt,
    this.regCloseAt,
    this.members = const [],
    this.sessions = const [],
    this.nextSession,
  });

  factory ClubModel.fromJson(Map<String, dynamic> j) {
    T? pick<T>(List<String> keys) {
      for (final k in keys) {
        if (j.containsKey(k) && j[k] != null) return j[k] as T;
      }
      return null;
    }

    return ClubModel(
      id:          pick(['Id', 'id']) ?? 0,
      name:        pick(['Name', 'name']) ?? '',
      clubType:    pick(['ClubType', 'clubType']),
      typeLabel:   pick(['TypeLabel', 'typeLabel']) ?? 'Khác',
      description: pick(['Description', 'description']),
      logoUrl:     pick(['LogoUrl', 'logoUrl']),
      advisorId:   pick(['AdvisorId', 'advisorId']),
      advisorName: pick(['AdvisorName', 'advisorName']),
      memberCount: pick(['MemberCount', 'memberCount']) ?? 0,
      maxMembers:  pick(['MaxMembers', 'maxMembers']),
      memberStatus: pick(['MemberStatus', 'memberStatus']) ?? 'none',
      myRole:      pick(['MyRole', 'myRole']),
      isLeader:    pick(['IsLeader', 'isLeader']) ?? false,
      regStatus:   pick(['RegStatus', 'regStatus']) ?? 'not_open',
      regOpenAt:   pick(['RegOpenAt', 'regOpenAt']),
      regCloseAt:  pick(['RegCloseAt', 'regCloseAt']),
      members: j['Members'] != null
          ? (j['Members'] as List).map((e) => ClubMemberModel.fromJson(Map<String, dynamic>.from(e))).toList()
          : [],
      sessions: j['Sessions'] != null
          ? (j['Sessions'] as List).map((e) => ClubSessionModel.fromJson(Map<String, dynamic>.from(e))).toList()
          : [],
      nextSession: j['NextSession'] != null ? Map<String, dynamic>.from(j['NextSession']) : null,
    );
  }

  bool get canJoin => memberStatus == 'none' && regStatus == 'open';
  bool get isMember => memberStatus == 'approved';
  bool get isPending => memberStatus == 'pending';
}
