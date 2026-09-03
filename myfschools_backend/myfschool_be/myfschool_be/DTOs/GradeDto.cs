namespace myfschool_be.DTOs
{
    public class GradeDto
    {
        public string SubjectName { get; set; } = string.Empty;
        public string SubjectShortName { get; set; } = string.Empty;
        
        // Điểm miệng / Phát biểu
        public double? ScoreOral { get; set; }
        
        // Danh sách điểm 15 phút
        public List<double> Scores15m { get; set; } = new();
        
        // Danh sách điểm 1 tiết (hệ số 2)
        public List<double> Scores1h { get; set; } = new();
        
        // Điểm thi cuối kỳ
        public double? ScoreFinal { get; set; }
        
        // Trung bình môn
        public double? GpaSubject { get; set; }
        
        // Xếp loại (Gioi, Kha, ...)
        public string? GradeLabel { get; set; }
    }

    public class SemesterGradesResponse
    {
        public string StudentName { get; set; } = string.Empty;
        public string ClassName { get; set; } = string.Empty;
        public List<GradeDto> Grades { get; set; } = new();
        public double? OverallGpa { get; set; }
    }
}
