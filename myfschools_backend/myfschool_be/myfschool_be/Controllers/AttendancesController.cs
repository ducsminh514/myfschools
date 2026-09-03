using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using myfschool_be.Models;
using System.Security.Claims;

namespace myfschool_be.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class AttendancesController : ControllerBase
    {
        private readonly FptschoolContext _context;

        public AttendancesController(FptschoolContext context)
        {
            _context = context;
        }

        // ─── STUDENT: Xem lịch sử điểm danh của mình ───────────────────────────
        [HttpGet("my")]
        [Authorize(Roles = "student")]
        public async Task<IActionResult> GetMyAttendance()
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            var records = await _context.Attendances
                .Include(a => a.Schedule)
                    .ThenInclude(s => s.ClassSubject)
                        .ThenInclude(cs => cs.Subject)
                .Include(a => a.Schedule)
                    .ThenInclude(s => s.PeriodNoNavigation)
                .Where(a => a.StudentId == userId)
                .OrderByDescending(a => a.AttendDate)
                .Select(a => new
                {
                    a.Id,
                    Date = a.AttendDate.ToString("dd/MM/yyyy"),
                    Subject = a.Schedule.ClassSubject.Subject.Name,
                    Period = a.Schedule.PeriodNo,
                    StartTime = a.Schedule.PeriodNoNavigation != null
                        ? a.Schedule.PeriodNoNavigation.StartTime.ToString(@"hh\:mm")
                        : "N/A",
                    a.Status,       // present | absent | late | excused
                    a.Note
                })
                .ToListAsync();

            // Tính tổng kết
            var total    = records.Count;
            var present  = records.Count(r => r.Status == "present");
            var absent   = records.Count(r => r.Status == "absent");
            var late     = records.Count(r => r.Status == "late");
            var excused  = records.Count(r => r.Status == "excused"); // Có phép — không tính là vắng
            // excused được tính là có mặt cho mục đích chuyên cần
            var attendancePct = total > 0 ? Math.Round((double)(present + late + excused) / total * 100, 1) : 0;

            return Ok(new
            {
                Summary = new { Total = total, Present = present, Absent = absent, Late = late, Excused = excused, AttendancePct = attendancePct },
                Records = records
            });
        }

        // ─── GVCN: Xem danh sách học sinh cần điểm danh theo ngày ─────────
        [HttpGet("class")]
        [Authorize(Roles = "teacher")]
        public async Task<IActionResult> GetClassAttendanceSheet([FromQuery] int scheduleId, [FromQuery] string date)
        {
            var teacherId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            // Kiểm tra GV có phải GVCN của lớp này không
            var schedule = await _context.Schedules
                .Include(s => s.ClassSubject)
                    .ThenInclude(cs => cs.Subject)
                .Include(s => s.ClassSubject)
                    .ThenInclude(cs => cs.Class)
                .FirstOrDefaultAsync(s => s.Id == scheduleId);

            if (schedule == null)
                return NotFound(new { message = "Không tìm thấy lịch học" });

            // Chỉ GVCN mới được điểm danh
            var isHomeroom = await _context.Classes
                .AnyAsync(c => c.Id == schedule.ClassSubject.ClassId && c.HomeroomTeacherId == teacherId);

            if (!isHomeroom)
                return Forbid();

            if (!DateOnly.TryParse(date, out var attendDate))
                return BadRequest(new { message = "Định dạng ngày không hợp lệ (yyyy-MM-dd)" });

            // Lấy danh sách học sinh trong lớp
            var students = await _context.StudentProfiles
                .Include(sp => sp.User)
                .Where(sp => sp.ClassId == schedule.ClassSubject.ClassId)
                .OrderBy(sp => sp.User.FullName)
                .ToListAsync();

            // Lấy các bản ghi điểm danh đã có cho buổi này
            var existing = await _context.Attendances
                .Where(a => a.ScheduleId == scheduleId && a.AttendDate == attendDate)
                .ToDictionaryAsync(a => a.StudentId);

            var sheet = students.Select(sp => new
            {
                StudentId = sp.UserId,
                StudentName = sp.User.FullName,
                StudentCode = sp.User.StudentCode,
                Status = existing.ContainsKey(sp.UserId) ? existing[sp.UserId].Status : "present", // Mặc định là có mặt
                Note = existing.ContainsKey(sp.UserId) ? existing[sp.UserId].Note : null,
                AttendanceId = existing.ContainsKey(sp.UserId) ? existing[sp.UserId].Id : (int?)null
            });

            return Ok(new
            {
                ScheduleId = scheduleId,
                Date = attendDate.ToString("dd/MM/yyyy"),
                Subject = schedule.ClassSubject.Subject.Name,
                ClassName = schedule.ClassSubject.Class.Name,
                Period = schedule.PeriodNo,
                Students = sheet
            });
        }

        // ─── GVCN: Nộp bảng điểm danh hàng loạt ──────────────────────────
        [HttpPost("submit")]
        [Authorize(Roles = "teacher")]
        public async Task<IActionResult> SubmitAttendance([FromBody] SubmitAttendanceRequest req)
        {
            var teacherId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            // Kiểm tra quyền GVCN
            var schedule = await _context.Schedules
                .Include(s => s.ClassSubject)
                .FirstOrDefaultAsync(s => s.Id == req.ScheduleId);

            if (schedule == null) return NotFound(new { message = "Không tìm thấy lịch học" });

            var isHomeroom = await _context.Classes
                .AnyAsync(c => c.Id == schedule.ClassSubject.ClassId && c.HomeroomTeacherId == teacherId);

            if (!isHomeroom) return Forbid();

            if (!DateOnly.TryParse(req.Date, out var attendDate))
                return BadRequest(new { message = "Định dạng ngày không hợp lệ (yyyy-MM-dd)" });

            // Lấy TẤT CẢ existing records 1 lần duy nhất (fix N+1 query)
            var existingAll = await _context.Attendances
                .Where(a => a.ScheduleId == req.ScheduleId && a.AttendDate == attendDate)
                .ToDictionaryAsync(a => a.StudentId);

            var toAdd    = new List<Attendance>();
            var toUpdate = new List<Attendance>();

            foreach (var record in req.Records)
            {
                if (existingAll.TryGetValue(record.StudentId, out var existing))
                {
                    existing.Status     = record.Status;
                    existing.Note       = record.Note;
                    existing.RecordedBy = teacherId;
                    toUpdate.Add(existing);
                }
                else
                {
                    toAdd.Add(new Attendance
                    {
                        ScheduleId = req.ScheduleId,
                        StudentId  = record.StudentId,
                        AttendDate = attendDate,
                        Status     = record.Status,
                        Note       = record.Note,
                        RecordedBy = teacherId,
                        CreatedAt  = DateTime.Now
                    });
                }
            }

            if (toAdd.Count > 0)    _context.Attendances.AddRange(toAdd);
            // toUpdate: EF đã track nên chỉ cần SaveChanges
            await _context.SaveChangesAsync();
            return Ok(new { message = $"Đã lưu {req.Records.Count} bản ghi điểm danh" });
        }

        // ─── GVCN: Sửa 1 bản ghi điểm danh ────────────────────────────────
        [HttpPatch("{id}")]
        [Authorize(Roles = "teacher")]
        public async Task<IActionResult> UpdateAttendance(int id, [FromBody] UpdateAttendanceRequest req)
        {
            var teacherId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            var attendance = await _context.Attendances
                .Include(a => a.Schedule)
                    .ThenInclude(s => s.ClassSubject)
                .FirstOrDefaultAsync(a => a.Id == id);

            if (attendance == null)
                return NotFound(new { message = "Không tìm thấy bản ghi" });

            // Chỉ GVCN mới được sửa
            var isHomeroom = await _context.Classes
                .AnyAsync(c => c.Id == attendance.Schedule.ClassSubject.ClassId && c.HomeroomTeacherId == teacherId);

            if (!isHomeroom) return Forbid();

            attendance.Status = req.Status;
            attendance.Note = req.Note;
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã cập nhật điểm danh" });
        }
    }

    // ─── Request DTOs ─────────────────────────────────────────────────────────
    public class AttendanceRecordItem
    {
        public int StudentId { get; set; }
        public string Status { get; set; } = "present"; // present|absent|late|excused
        public string? Note { get; set; }
    }

    public class SubmitAttendanceRequest
    {
        public int ScheduleId { get; set; }
        public string Date { get; set; } = null!; // "yyyy-MM-dd"
        public List<AttendanceRecordItem> Records { get; set; } = new();
    }

    public class UpdateAttendanceRequest
    {
        public string Status { get; set; } = null!;
        public string? Note { get; set; }
    }
}
