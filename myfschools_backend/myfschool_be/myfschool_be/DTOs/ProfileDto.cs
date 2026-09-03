namespace myfschool_be.DTOs
{
    public class UserProfileDto
    {
        public int Id { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string? StudentCode { get; set; }
        public string Email { get; set; } = string.Empty;
        public string? Phone { get; set; }
        public string? AvatarUrl { get; set; }
        public List<string> Roles { get; set; } = new List<string>();
        
        // Chi tiết họsbơ học sinh
        public StudentDetailDto? Detail { get; set; }
        // Chi tiết hồ sơ giáo viên
        public TeacherDetailDto? TeacherDetail { get; set; }
    }

    public class StudentDetailDto
    {
        public string? ClassName { get; set; }
        public DateTime? BirthDate { get; set; }
        public string? Gender { get; set; }
        public string? Address { get; set; }
        public string? ParentName { get; set; }
        public string? ParentPhone { get; set; }
    }

    public class TeacherDetailDto
    {
        public bool IsHomeroom { get; set; }
        public string? HomeroomClassName { get; set; }
        public List<TeachingSubjectDto> TeachingSubjects { get; set; } = new();
    }

    public class TeachingSubjectDto
    {
        public int ClassSubjectId { get; set; }
        public string SubjectName { get; set; } = string.Empty;
        public string ClassName { get; set; } = string.Empty;
    }

    public class ChangePasswordRequest
    {
        public string OldPassword { get; set; } = string.Empty;
        public string NewPassword { get; set; } = string.Empty;
    }
}
