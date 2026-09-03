namespace myfschool_be.DTOs
{
    public class WeeklyScheduleItemDto
    {
        public int DayOfWeek { get; set; } // 2=Monday...7=Saturday
        public int PeriodNo { get; set; }
        public string SubjectName { get; set; } = string.Empty;
        public string SubjectShortName { get; set; } = string.Empty;
        public string Room { get; set; } = string.Empty;
        public string StartTime { get; set; } = string.Empty;
        public string EndTime { get; set; } = string.Empty;
        public string TeacherName { get; set; } = string.Empty;
    }

    public class WeeklyScheduleResponse
    {
        public string ClassName { get; set; } = string.Empty;
        public List<WeeklyScheduleItemDto> Schedules { get; set; } = new();
    }
}
