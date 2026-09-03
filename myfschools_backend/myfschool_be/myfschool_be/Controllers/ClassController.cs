using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using myfschool_be.Models;
using myfschool_be.DTOs;
using System.Security.Claims;

namespace myfschool_be.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class ClassController : ControllerBase
    {
        private readonly FptschoolContext _context;

        public ClassController(FptschoolContext context)
        {
            _context = context;
        }

        /// <summary>
        /// Lấy classId mà GV đang chủ nhiệm. Trả null nếu không phải GVCN.
        /// </summary>
        private async Task<(int classId, string className)?> GetHomeroomClass(int teacherId)
        {
            var cls = await _context.Classes
                .FirstOrDefaultAsync(c => c.HomeroomTeacherId == teacherId);
            if (cls == null) return null;
            return (cls.Id, cls.Name);
        }

        // ━━━━━ 1. DASHBOARD LỚP ━━━━━
        [HttpGet("my-class")]
        public async Task<IActionResult> GetMyClass()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out int userId))
                return Unauthorized(new { message = "Token không hợp lệ." });

            // Chỉ GVCN mới access được
            var homeroomInfo = await GetHomeroomClass(userId);
            if (homeroomInfo == null)
                return StatusCode(403, new { message = "Bạn không phải giáo viên chủ nhiệm." });

            var (classId, className) = homeroomInfo.Value;

            // Sĩ số + giới tính — dùng SQL GROUP BY, không load toàn bộ
            var stats = await _context.StudentProfiles
                .Where(sp => sp.ClassId == classId)
                .GroupBy(sp => 1) // group tất cả thành 1 nhóm
                .Select(g => new
                {
                    Total = g.Count(),
                    Male = g.Count(sp => sp.Gender == "male"),
                    Female = g.Count(sp => sp.Gender == "female")
                })
                .FirstOrDefaultAsync();

            // GPA trung bình lớp — aggregate ở DB
            var avgGpa = await _context.SemesterResults
                .Where(sr => _context.StudentProfiles
                    .Where(sp => sp.ClassId == classId)
                    .Select(sp => sp.UserId)
                    .Contains(sr.StudentId))
                .AverageAsync(sr => (double?)sr.Gpa) ?? 0;

            // Tỉ lệ chuyên cần lớp
            var studentIds = await _context.StudentProfiles
                .Where(sp => sp.ClassId == classId)
                .Select(sp => sp.UserId)
                .ToListAsync();

            int totalAttendance = await _context.Attendances
                .CountAsync(a => studentIds.Contains(a.StudentId));
            int presentAttendance = await _context.Attendances
                .CountAsync(a => studentIds.Contains(a.StudentId) && a.Status == "present");
            int attendanceRate = totalAttendance > 0
                ? (int)Math.Round((double)presentAttendance / totalAttendance * 100)
                : 0;

            // Đơn chờ duyệt: từ HS lớp mình, chưa duyệt
            // AssignedTo == null → mặc định gửi cho GVCN
            int pendingForms = await _context.Forms
                .CountAsync(f => studentIds.Contains(f.StudentId)
                    && f.Status == "pending"
                    && (f.AssignedTo == null || f.AssignedTo == userId));

            return Ok(new ClassDashboardDto
            {
                ClassId = classId,
                ClassName = className,
                TotalStudents = stats?.Total ?? 0,
                MaleCount = stats?.Male ?? 0,
                FemaleCount = stats?.Female ?? 0,
                AverageGpa = Math.Round(avgGpa, 2),
                AttendanceRate = attendanceRate,
                PendingForms = pendingForms
            });
        }

        // ━━━━━ 2. DANH SÁCH HỌC SINH ━━━━━
        [HttpGet("students")]
        public async Task<IActionResult> GetStudents()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out int userId))
                return Unauthorized();

            var homeroomInfo = await GetHomeroomClass(userId);
            if (homeroomInfo == null)
                return StatusCode(403, new { message = "Bạn không phải giáo viên chủ nhiệm." });

            var classId = homeroomInfo.Value.classId;

            // Bước 1: Lấy DS studentId trong lớp
            var studentIds = await _context.StudentProfiles
                .Where(sp => sp.ClassId == classId)
                .Select(sp => sp.UserId)
                .ToListAsync();

            // Bước 2: Batch query attendance — 1 SQL duy nhất thay vì 3*N
            // Performance: O(1) query thay vì O(N) correlated subqueries
            var attendanceStats = await _context.Attendances
                .Where(a => studentIds.Contains(a.StudentId))
                .GroupBy(a => a.StudentId)
                .Select(g => new
                {
                    StudentId = g.Key,
                    Total = g.Count(),
                    Present = g.Count(a => a.Status == "present")
                })
                .ToDictionaryAsync(x => x.StudentId);

            // Bước 3: Batch query GPA mới nhất — 1 SQL
            var latestGpa = await _context.SemesterResults
                .Where(sr => studentIds.Contains(sr.StudentId))
                .GroupBy(sr => sr.StudentId)
                .Select(g => new
                {
                    StudentId = g.Key,
                    Gpa = g.OrderByDescending(sr => sr.SchoolYear)
                            .ThenByDescending(sr => sr.Semester)
                            .Select(sr => sr.Gpa)
                            .FirstOrDefault() ?? 0
                })
                .ToDictionaryAsync(x => x.StudentId);

            // Bước 4: Lấy thông tin HS + map kết quả aggregate
            var students = await _context.StudentProfiles
                .Where(sp => sp.ClassId == classId)
                .OrderBy(sp => sp.User.FullName)
                .Select(sp => new ClassStudentDto
                {
                    StudentId = sp.UserId,
                    FullName = sp.User.FullName,
                    StudentCode = sp.User.StudentCode,
                    Gender = sp.Gender,
                    BirthDate = sp.BirthDate,
                    AvatarUrl = sp.User.AvatarUrl,
                    // Gpa + AttendanceRate sẽ map sau (không dùng correlated subquery)
                    Gpa = 0,
                    AttendanceRate = 0
                })
                .ToListAsync();

            // Map GPA + attendance từ batch results
            foreach (var s in students)
            {
                if (latestGpa.TryGetValue(s.StudentId, out var gpaInfo))
                    s.Gpa = (double)gpaInfo.Gpa;

                if (attendanceStats.TryGetValue(s.StudentId, out var att))
                    s.AttendanceRate = att.Total > 0
                        ? (int)Math.Round((double)att.Present / att.Total * 100)
                        : 0;
            }

            return Ok(students);
        }

        // ━━━━━ 3. CHI TIẾT 1 HỌC SINH ━━━━━
        [HttpGet("student/{studentId}")]
        public async Task<IActionResult> GetStudentDetail(int studentId)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out int userId))
                return Unauthorized();

            var homeroomInfo = await GetHomeroomClass(userId);
            if (homeroomInfo == null)
                return StatusCode(403, new { message = "Bạn không phải giáo viên chủ nhiệm." });

            var classId = homeroomInfo.Value.classId;

            // Bảo mật: chỉ xem HS trong lớp mình chủ nhiệm
            var profile = await _context.StudentProfiles
                .Include(sp => sp.User)
                .FirstOrDefaultAsync(sp => sp.UserId == studentId && sp.ClassId == classId);

            if (profile == null)
                return NotFound(new { message = "Học sinh không thuộc lớp của bạn." });

            // Lấy class_subject_ids thuộc lớp này (filter theo lớp, tránh lẫn data lớp khác)
            var classSubjectIds = await _context.ClassSubjects
                .Where(cs => cs.ClassId == classId)
                .Select(cs => cs.Id)
                .ToListAsync();

            // Điểm — chỉ lấy grades thuộc class_subjects của lớp hiện tại
            // Tránh trùng tên môn khi HS có data từ nhiều HK/lớp khác
            var subjectGrades = await _context.Grades
                .Where(g => g.StudentId == studentId && classSubjectIds.Contains(g.ClassSubjectId))
                .Select(g => new SubjectGradeDto
                {
                    SubjectName = g.ClassSubject.Subject.Name,
                    ScoreOral = g.ScoreOral,
                    Score15m1 = g.Score15m1,
                    Score15m2 = g.Score15m2,
                    Score15m3 = g.Score15m3,
                    Score1h1 = g.Score1h1,
                    Score1h2 = g.Score1h2,
                    Score1h3 = g.Score1h3,
                    ScoreFinal = g.ScoreFinal,
                    GpaSubject = g.GpaSubject
                })
                .ToListAsync();

            // Chuyên cần — gộp 1 query thay vì 2 query COUNT
            var attendanceData = await _context.Attendances
                .Where(a => a.StudentId == studentId)
                .GroupBy(a => 1)
                .Select(g => new
                {
                    Total = g.Count(),
                    Present = g.Count(a => a.Status == "present")
                })
                .FirstOrDefaultAsync();

            int totalSessions = attendanceData?.Total ?? 0;
            int presentSessions = attendanceData?.Present ?? 0;
            int absentSessions = totalSessions - presentSessions;
            int attendanceRate = totalSessions > 0
                ? (int)Math.Round((double)presentSessions / totalSessions * 100)
                : 0;

            // GPA
            var latestSemester = await _context.SemesterResults
                .Where(sr => sr.StudentId == studentId)
                .OrderByDescending(sr => sr.SchoolYear)
                .ThenByDescending(sr => sr.Semester)
                .FirstOrDefaultAsync();

            return Ok(new StudentFullDetailDto
            {
                StudentId = profile.UserId,
                FullName = profile.User.FullName,
                StudentCode = profile.User.StudentCode,
                Gender = profile.Gender,
                BirthDate = profile.BirthDate,
                Address = profile.Address,
                AvatarUrl = profile.User.AvatarUrl,
                Phone = profile.User.Phone,
                ParentName = profile.ParentName,
                ParentPhone = profile.ParentPhone,
                ParentEmail = profile.ParentEmail,
                Gpa = (double)(latestSemester?.Gpa ?? 0),
                SubjectGrades = subjectGrades,
                TotalSessions = totalSessions,
                PresentSessions = presentSessions,
                AbsentSessions = absentSessions,
                AttendanceRate = attendanceRate
            });
        }
    }
}
