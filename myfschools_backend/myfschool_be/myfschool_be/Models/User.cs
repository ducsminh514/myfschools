using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class User
{
    public int Id { get; set; }

    public string? StudentCode { get; set; }

    public string FullName { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string PasswordHash { get; set; } = null!;

    public virtual ICollection<Role> Roles { get; set; } = new List<Role>();

    public string? AvatarUrl { get; set; }

    public string? Phone { get; set; }

    public bool IsActive { get; set; }

    public int TokenVersion { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual ICollection<Attendance> AttendanceRecordedByNavigations { get; set; } = new List<Attendance>();

    public virtual ICollection<Attendance> AttendanceStudents { get; set; } = new List<Attendance>();

    public virtual ICollection<ClassSubject> ClassSubjects { get; set; } = new List<ClassSubject>();

    public virtual ICollection<Class> Classes { get; set; } = new List<Class>();

    public virtual ICollection<ClubMember> ClubMembers { get; set; } = new List<ClubMember>();

    public virtual ICollection<Club> Clubs { get; set; } = new List<Club>();

    public virtual ICollection<Conversation> ConversationStudents { get; set; } = new List<Conversation>();

    public virtual ICollection<Conversation> ConversationTeachers { get; set; } = new List<Conversation>();

    public virtual ICollection<EventRegistration> EventRegistrations { get; set; } = new List<EventRegistration>();

    public virtual ICollection<Event> Events { get; set; } = new List<Event>();

    public virtual ICollection<Form> FormReviewedByNavigations { get; set; } = new List<Form>();

    public virtual ICollection<Form> FormAssignedToNavigations { get; set; } = new List<Form>();

    public virtual ICollection<Form> FormStudents { get; set; } = new List<Form>();

    public virtual ICollection<Grade> GradeStudents { get; set; } = new List<Grade>();

    public virtual ICollection<Grade> GradeUpdatedByNavigations { get; set; } = new List<Grade>();

    public virtual ICollection<Message> Messages { get; set; } = new List<Message>();

    public virtual ICollection<Notification> Notifications { get; set; } = new List<Notification>();

    public virtual ICollection<OtpCode> OtpCodes { get; set; } = new List<OtpCode>();

    public virtual ICollection<RefreshToken> RefreshTokens { get; set; } = new List<RefreshToken>();

    public virtual ICollection<SemesterResult> SemesterResults { get; set; } = new List<SemesterResult>();

    public virtual StudentProfile? StudentProfile { get; set; }

    public virtual TeacherChatSetting? TeacherChatSetting { get; set; }
}
