using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class Club
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public string? ClubType { get; set; }

    public string? Description { get; set; }

    public string? LogoUrl { get; set; }

    public int? AdvisorId { get; set; }

    public int? MaxMembers { get; set; }

    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; }

    // Thời gian mở/đóng đăng ký thành viên
    public DateTime? RegOpenAt { get; set; }

    public DateTime? RegCloseAt { get; set; }

    public virtual User? Advisor { get; set; }

    public virtual ICollection<ClubMember> ClubMembers { get; set; } = new List<ClubMember>();

    public virtual ICollection<ClubSession> ClubSessions { get; set; } = new List<ClubSession>();
}
