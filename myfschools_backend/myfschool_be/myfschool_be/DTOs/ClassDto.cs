namespace myfschool_be.DTOs
{
    // Dashboard tổng quan lớp chủ nhiệm
    public class ClassDashboardDto
    {
        public int ClassId { get; set; }
        public string ClassName { get; set; } = string.Empty;
        public int TotalStudents { get; set; }
        public int MaleCount { get; set; }
        public int FemaleCount { get; set; }
        public double AverageGpa { get; set; }
        public int AttendanceRate { get; set; } // %
        public int PendingForms { get; set; }
    }

    // Tóm tắt HS trong danh sách lớp
    public class ClassStudentDto
    {
        public int StudentId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string? StudentCode { get; set; }
        public string? Gender { get; set; }
        public DateOnly? BirthDate { get; set; }
        public double Gpa { get; set; }
        public int AttendanceRate { get; set; } // %
        public string? AvatarUrl { get; set; }
    }

    // Chi tiết đầy đủ 1 HS
    public class StudentFullDetailDto
    {
        // Thông tin cá nhân
        public int StudentId { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string? StudentCode { get; set; }
        public string? Gender { get; set; }
        public DateOnly? BirthDate { get; set; }
        public string? Address { get; set; }
        public string? AvatarUrl { get; set; }
        public string? Phone { get; set; }

        // Phụ huynh
        public string? ParentName { get; set; }
        public string? ParentPhone { get; set; }
        public string? ParentEmail { get; set; }

        // Học lực
        public double Gpa { get; set; }
        public List<SubjectGradeDto> SubjectGrades { get; set; } = new();

        // Chuyên cần
        public int TotalSessions { get; set; }
        public int PresentSessions { get; set; }
        public int AbsentSessions { get; set; }
        public int AttendanceRate { get; set; } // %
    }

    public class SubjectGradeDto
    {
        public string SubjectName { get; set; } = string.Empty;
        public double? ScoreOral { get; set; }
        public double? Score15m1 { get; set; }
        public double? Score15m2 { get; set; }
        public double? Score15m3 { get; set; }
        public double? Score1h1 { get; set; }
        public double? Score1h2 { get; set; }
        public double? Score1h3 { get; set; }
        public double? ScoreFinal { get; set; }
        public double? GpaSubject { get; set; }
    }
}
