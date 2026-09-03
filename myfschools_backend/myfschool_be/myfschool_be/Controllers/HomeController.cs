using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;
using myfschool_be.DTOs;
using myfschool_be.Models;

namespace myfschool_be.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize] // Yêu cầu gắn JWT Token mới được vào API này
    public class HomeController : ControllerBase
    {
        private readonly FptschoolContext _context;

        public HomeController(FptschoolContext context)
        {
            _context = context;
        }

        [HttpGet("dashboard")]
        public async Task<IActionResult> GetDashboardData()
        {
            // 1. Trích xuất ID người dùng từ Claims trong JWT Token
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out int userId))
            {
                return Unauthorized(new { message = "Token không hợp lệ." });
            }

            // 2. Fetch User Summary & Class Info
            var user = await _context.Users
                .Include(u => u.Roles)
                .Include(u => u.Classes) // Lớp chủ nhiệm (nếu có, tuỳ role)
                .Include(u => u.StudentProfile)
                    .ThenInclude(p => p.Class)
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null)
            {
                return NotFound(new { message = "Không tìm thấy người dùng." });
            }

            bool isStudent = user.Roles.Any(r => r.Name == "student");
            bool isTeacher = user.Roles.Any(r => r.Name == "teacher");

            // ── GVCN / GVBM ──────────────────────────────────────────
            bool isHomeroom = false;
            string? homeroomClassName = null;
            List<object>? teachingSubjects = null;

            if (isTeacher)
            {
                // Kiểm tra có phải GVCN không
                var homeroomClass = user.Classes.FirstOrDefault();
                if (homeroomClass != null)
                {
                    isHomeroom = true;
                    homeroomClassName = homeroomClass.Name;
                }

                // DS môn/lớp đang dạy
                teachingSubjects = await _context.ClassSubjects
                    .Include(cs => cs.Subject)
                    .Include(cs => cs.Class)
                    .Where(cs => cs.TeacherId == userId)
                    .Select(cs => (object)new {
                        cs.Id,
                        SubjectName = cs.Subject.Name,
                        ClassName = cs.Class.Name
                    })
                    .ToListAsync();
            }

            // Đếm số đơn từ chờ xử lý — phân quyền theo GVCN/GVBM
            int pendingFormsCount = 0;
            if (isTeacher)
            {
                if (isHomeroom)
                {
                    // GVCN: đơn KHÔNG gán cho ai (mặc định gửi GVCN) của HS lớp mình
                    //      + đơn gán trực tiếp cho mình
                    var homeroomClassId = user.Classes.First().Id;
                    var homeroomStudentIds = await _context.StudentProfiles
                        .Where(sp => sp.ClassId == homeroomClassId)
                        .Select(sp => sp.UserId)
                        .ToListAsync();

                    pendingFormsCount = await _context.Forms.CountAsync(f =>
                        f.Status == "pending" &&
                        ((f.AssignedTo == null && homeroomStudentIds.Contains(f.StudentId))
                         || f.AssignedTo == userId));
                }
                else
                {
                    // GVBM: chỉ thấy đơn gán cho mình
                    pendingFormsCount = await _context.Forms.CountAsync(f =>
                        f.Status == "pending" && f.AssignedTo == userId);
                }
            }
            else if (isStudent)
            {
                pendingFormsCount = await _context.Forms.CountAsync(f => f.StudentId == userId && f.Status == "pending");
            }

            // Đoán Class Name
            string className = "Chưa xếp lớp";
            if (user.StudentProfile?.Class != null)
            {
                className = user.StudentProfile.Class.Name;
            }

            // ─── GPA: Tính từ SemesterResults thực tế (chỉ dành cho Student) ───
            double realGpa = 0;
            int realAttendance = 0;
            if (isStudent)
            {
                var semesterResult = await _context.SemesterResults
                    .Where(sr => sr.StudentId == userId)
                    .OrderByDescending(sr => sr.SchoolYear)
                    .ThenByDescending(sr => sr.Semester)
                    .FirstOrDefaultAsync();
                realGpa = (double)(semesterResult?.Gpa ?? 0);

                // Chuyên cần: Đếm số buổi có mặt / tổng số buổi * 100
                var totalSessions = await _context.Attendances.CountAsync(a => a.StudentId == userId);
                var presentSessions = await _context.Attendances.CountAsync(a => a.StudentId == userId && a.Status == "present");
                realAttendance = totalSessions > 0 ? (int)Math.Round((double)presentSessions / totalSessions * 100) : 0;
            }

            var userInfoDto = new UserSummaryDto
            {
                Id = user.Id,
                FullName = user.FullName,
                StudentCode = user.StudentCode,
                ClassName = isTeacher ? (homeroomClassName ?? "Giáo viên") : className,
                Gpa = realGpa,
                AttendanceScore = realAttendance,
                PendingForms = pendingFormsCount,
                Roles = user.Roles.Select(r => r.Name).ToList()
            };

            // ─── Lịch học hôm nay: Lọc đúng theo Lớp của Student ───
            // Map DayOfWeek (C# enum: 0=Sunday) → DayOfWeek số trong DB (1=CN, 2=T2...7=T7)
            var today = DateTime.Now.DayOfWeek;
            int todayDbValue = today == DayOfWeek.Sunday ? 1 : (int)today + 1; // Sunday=1, Mon=2...Sat=7

            List<ScheduleItemDto> scheduleList = new();
            if (isStudent && user.StudentProfile != null)
            {
                var classId = user.StudentProfile.ClassId;
                var schedules = await _context.Schedules
                    .Include(s => s.ClassSubject)
                        .ThenInclude(cs => cs.Subject)
                    .Include(s => s.ClassSubject)
                        .ThenInclude(cs => cs.Teacher)
                    .Include(s => s.PeriodNoNavigation)
                    .Where(s => s.ClassSubject.ClassId == classId && s.DayOfWeek == todayDbValue)
                    .OrderBy(s => s.PeriodNo)
                    .Take(5)
                    .ToListAsync();

                scheduleList = schedules.Select(s => new ScheduleItemDto
                {
                    Id = s.Id,
                    PeriodNo = s.PeriodNo,
                    SubjectName = s.ClassSubject?.Subject?.Name ?? "N/A",
                    TeacherName = s.ClassSubject?.Teacher?.FullName ?? "N/A",
                    Room = s.Room,
                    StartTime = s.PeriodNoNavigation?.StartTime.ToString(@"hh\:mm") ?? "00:00",
                    EndTime = s.PeriodNoNavigation?.EndTime.ToString(@"hh\:mm") ?? "00:00",
                    Status = "upcoming"
                }).ToList();
            }
            else if (isTeacher)
            {
                // Lịch dạy hôm nay của GV
                var teacherSchedules = await _context.Schedules
                    .Include(s => s.ClassSubject)
                        .ThenInclude(cs => cs.Subject)
                    .Include(s => s.ClassSubject)
                        .ThenInclude(cs => cs.Class)
                    .Include(s => s.PeriodNoNavigation)
                    .Where(s => s.ClassSubject.TeacherId == userId && s.DayOfWeek == todayDbValue)
                    .OrderBy(s => s.PeriodNo)
                    .Take(8)
                    .ToListAsync();

                scheduleList = teacherSchedules.Select(s => new ScheduleItemDto
                {
                    Id = s.Id,
                    PeriodNo = s.PeriodNo,
                    SubjectName = s.ClassSubject?.Subject?.Name ?? "N/A",
                    TeacherName = s.ClassSubject?.Class?.Name ?? "N/A", // GV: hiện tên lớp thay vì tên GV
                    Room = s.Room,
                    StartTime = s.PeriodNoNavigation?.StartTime.ToString(@"hh\:mm") ?? "00:00",
                    EndTime = s.PeriodNoNavigation?.EndTime.ToString(@"hh\:mm") ?? "00:00",
                    Status = "upcoming"
                }).ToList();
            }

            // 4. Fetch 3 thông báo mới nhất
            var notices = await _context.Notifications
                .Where(n => n.UserId == userId)
                .OrderByDescending(n => n.CreatedAt)
                .Take(3)
                .Select(n => new NoticeDto
                {
                    Id = n.Id,
                    Title = n.Title,
                    NotiType = n.NotiType,
                    CreatedAt = n.CreatedAt
                })
                .ToListAsync();

            return Ok(new
            {
                UserInfo = userInfoDto,
                TodaySchedule = scheduleList,
                Notices = notices,
                // Chỉ trả cho GV
                IsHomeroom = isTeacher ? isHomeroom : (bool?)null,
                HomeroomClassName = homeroomClassName,
                TeachingSubjects = teachingSubjects
            });
        }
    }
}
