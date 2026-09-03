using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using myfschool_be.Models;
using myfschool_be.DTOs;
using System.Security.Claims;

namespace myfschool_be.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class ScheduleController : ControllerBase
    {
        private readonly FptschoolContext _context;

        public ScheduleController(FptschoolContext context)
        {
            _context = context;
        }

        [HttpGet("weekly")]
        public async Task<ActionResult<WeeklyScheduleResponse>> GetWeeklySchedule()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr)) return Unauthorized();
            
            var userId = int.Parse(userIdStr);

            bool isStudent = User.IsInRole("student");
            bool isTeacher = User.IsInRole("teacher");

            if (!isStudent && !isTeacher)
            {
                return Ok(new WeeklyScheduleResponse { 
                    ClassName = "N/A",
                    Schedules = new List<WeeklyScheduleItemDto>() 
                });
            }

            // Lấy bảng tra cứu giờ (PeriodTimes)
            var periodTimes = await _context.PeriodTimes.ToDictionaryAsync(p => p.PeriodNo);

            if (isStudent)
            {
                // ── STUDENT: Lịch học theo lớp ──
                var studentProfile = await _context.StudentProfiles
                    .Include(sp => sp.Class)
                    .FirstOrDefaultAsync(sp => sp.UserId == userId);

                if (studentProfile == null)
                    return NotFound(new { message = "Không tìm thấy thông tin lớp học của học sinh" });

                var classId = studentProfile.ClassId;
                var className = studentProfile.Class.Name;

                var schedules = await _context.Schedules
                    .Include(s => s.ClassSubject)
                        .ThenInclude(cs => cs.Subject)
                    .Include(s => s.ClassSubject)
                        .ThenInclude(cs => cs.Teacher)
                    .Where(s => s.ClassSubject.ClassId == classId)
                    .OrderBy(s => s.DayOfWeek)
                    .ThenBy(s => s.PeriodNo)
                    .ToListAsync();

                return Ok(new WeeklyScheduleResponse
                {
                    ClassName = className,
                    Schedules = schedules.Select(s => new WeeklyScheduleItemDto
                    {
                        DayOfWeek = s.DayOfWeek,
                        PeriodNo = s.PeriodNo,
                        SubjectName = s.ClassSubject.Subject.Name,
                        SubjectShortName = s.ClassSubject.Subject.ShortName,
                        Room = s.Room,
                        StartTime = periodTimes.ContainsKey(s.PeriodNo) ? periodTimes[s.PeriodNo].StartTime.ToString(@"hh\:mm") : "",
                        EndTime = periodTimes.ContainsKey(s.PeriodNo) ? periodTimes[s.PeriodNo].EndTime.ToString(@"hh\:mm") : "",
                        TeacherName = s.ClassSubject.Teacher.FullName
                    }).ToList()
                });
            }
            else
            {
                // ── TEACHER: Lịch dạy tất cả lớp ──
                var teacherSchedules = await _context.Schedules
                    .Include(s => s.ClassSubject)
                        .ThenInclude(cs => cs.Subject)
                    .Include(s => s.ClassSubject)
                        .ThenInclude(cs => cs.Class)
                    .Where(s => s.ClassSubject.TeacherId == userId)
                    .OrderBy(s => s.DayOfWeek)
                    .ThenBy(s => s.PeriodNo)
                    .ToListAsync();

                // Lấy tên GV
                var teacher = await _context.Users.FindAsync(userId);

                return Ok(new WeeklyScheduleResponse
                {
                    ClassName = teacher?.FullName ?? "Giáo viên",
                    Schedules = teacherSchedules.Select(s => new WeeklyScheduleItemDto
                    {
                        DayOfWeek = s.DayOfWeek,
                        PeriodNo = s.PeriodNo,
                        SubjectName = s.ClassSubject.Subject.Name,
                        SubjectShortName = s.ClassSubject.Subject.ShortName,
                        Room = s.Room,
                        StartTime = periodTimes.ContainsKey(s.PeriodNo) ? periodTimes[s.PeriodNo].StartTime.ToString(@"hh\:mm") : "",
                        EndTime = periodTimes.ContainsKey(s.PeriodNo) ? periodTimes[s.PeriodNo].EndTime.ToString(@"hh\:mm") : "",
                        TeacherName = s.ClassSubject.Class.Name // GV: hiện tên lớp thay vì tên GV
                    }).ToList()
                });
            }
        }
    }
}
