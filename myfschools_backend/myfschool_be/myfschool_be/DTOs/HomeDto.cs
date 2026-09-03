namespace myfschool_be.DTOs
{
    public class UserSummaryDto
    {
        public int Id { get; set; }
        public string FullName { get; set; } = null!;
        public string? StudentCode { get; set; }
        public string? ClassName { get; set; }
        public double Gpa { get; set; }
        public int AttendanceScore { get; set; } // Số điểm chuyên cần hoặc lượt vắng
        public int PendingForms { get; set; } // Số đơn từ chờ duyệt
        public List<string> Roles { get; set; } = new List<string>();
    }

    public class ScheduleItemDto
    {
        public int Id { get; set; }
        public int PeriodNo { get; set; }       // Số tiết (1-8) để hiển thị "Tiết 1", "Tiết 2"
        public string SubjectName { get; set; } = null!;
        public string TeacherName { get; set; } = "N/A"; // Tên giáo viên dạy môn đó
        public string Room { get; set; } = null!;
        public string StartTime { get; set; } = null!;
        public string EndTime { get; set; } = null!;
        public string Status { get; set; } = null!; // "ongoing", "upcoming", "finished"
    }

    public class NoticeDto
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public string NotiType { get; set; } = null!; // 'hoc_vu', 'su_kien', etc.
        public DateTime CreatedAt { get; set; }
    }

    public class HomeDataResponse
    {
        public UserSummaryDto UserInfo { get; set; } = null!;
        public List<ScheduleItemDto> TodaySchedule { get; set; } = new List<ScheduleItemDto>();
        public List<NoticeDto> Notices { get; set; } = new List<NoticeDto>();
    }
}
