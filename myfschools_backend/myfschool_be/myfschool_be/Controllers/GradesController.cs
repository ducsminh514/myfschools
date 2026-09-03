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
    public class GradesController : ControllerBase
    {
        private readonly FptschoolContext _context;

        public GradesController(FptschoolContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<SemesterGradesResponse>> GetMyGrades()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr)) return Unauthorized();

            var userId = int.Parse(userIdStr);

            // Kiểm tra xem User có vai trò student hay không
            // Nếu không có, trả về 1 Response rỗng hoặc báo lỗi sạch sẽ thay vì 404 Profile
            var isStudent = User.IsInRole("student");
            if (!isStudent)
            {
                return Ok(new SemesterGradesResponse { 
                    StudentName = User.FindFirstValue(ClaimTypes.Name) ?? "User",
                    Grades = new List<GradeDto>() 
                });
            }

            // 1. Lấy thông tin User & Profile
            var user = await _context.Users
                .Include(u => u.StudentProfile)
                    .ThenInclude(sp => sp!.Class)
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null) return NotFound(new { message = "Không tìm thấy người dùng" });

            // 2. Lấy danh sách điểm
            var grades = await _context.Grades
                .Include(g => g.ClassSubject)
                    .ThenInclude(cs => cs.Subject)
                .Where(g => g.StudentId == userId)
                .ToListAsync();

            // 3. Lấy kết quả học kỳ (nếu có)
            var semesterResult = await _context.SemesterResults
                .Where(sr => sr.StudentId == userId)
                .OrderByDescending(sr => sr.SchoolYear)
                .ThenByDescending(sr => sr.Semester)
                .FirstOrDefaultAsync();

            // 4. Map DTO
            var response = new SemesterGradesResponse
            {
                StudentName = user.FullName,
                ClassName = user.StudentProfile?.Class?.Name ?? "---",
                OverallGpa = semesterResult?.Gpa,
                Grades = grades.Select(g => new GradeDto
                {
                    SubjectName = g.ClassSubject.Subject.Name,
                    SubjectShortName = g.ClassSubject.Subject.ShortName,
                    ScoreOral = g.ScoreOral,
                    ScoreFinal = g.ScoreFinal,
                    GpaSubject = g.GpaSubject,
                    GradeLabel = g.GradeLabel,
                    Scores15m = new List<double> { g.Score15m1 ?? 0, g.Score15m2 ?? 0, g.Score15m3 ?? 0 }
                        .Where(v => v > 0).ToList(),
                    Scores1h = new List<double> { g.Score1h1 ?? 0, g.Score1h2 ?? 0, g.Score1h3 ?? 0 }
                        .Where(v => v > 0).ToList()
                }).ToList()
            };

            return Ok(response);
        }

        // ─── TEACHER: Xem bảng điểm của tất cả HS trong lớp mình dạy ─────────
        [HttpGet("class")]
        [Authorize(Roles = "teacher")]
        public async Task<IActionResult> GetClassGrades([FromQuery] int classSubjectId)
        {
            var teacherId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            // Kiểm tra GV có dạy môn này không
            var classSubject = await _context.ClassSubjects
                .Include(cs => cs.Subject)
                .Include(cs => cs.Class)
                .FirstOrDefaultAsync(cs => cs.Id == classSubjectId && cs.TeacherId == teacherId);

            if (classSubject == null)
                return Forbid();

            // Lấy danh sách học sinh trong lớp + điểm của họ
            var students = await _context.StudentProfiles
                .Include(sp => sp.User)
                .Where(sp => sp.ClassId == classSubject.ClassId)
                .OrderBy(sp => sp.User.FullName)
                .ToListAsync();

            var grades = await _context.Grades
                .Where(g => g.ClassSubjectId == classSubjectId)
                .ToDictionaryAsync(g => g.StudentId);

            var result = students.Select(sp => {
                var g = grades.ContainsKey(sp.UserId) ? grades[sp.UserId] : null;
                return new {
                    StudentId = sp.UserId,
                    StudentName = sp.User.FullName,
                    StudentCode = sp.User.StudentCode,
                    GradeId = g?.Id,
                    ScoreOral = g?.ScoreOral,
                    Score15m1 = g?.Score15m1, Score15m2 = g?.Score15m2, Score15m3 = g?.Score15m3,
                    Score1h1 = g?.Score1h1, Score1h2 = g?.Score1h2, Score1h3 = g?.Score1h3,
                    ScoreFinal = g?.ScoreFinal,
                    Avg15m = g?.Avg15m, Avg1h = g?.Avg1h,
                    GpaSubject = g?.GpaSubject,
                    GradeLabel = g?.GradeLabel,
                    IsFinalized = g?.IsFinalized ?? false
                };
            });

            return Ok(new {
                Subject = classSubject.Subject.Name,
                ClassName = classSubject.Class.Name,
                Students = result
            });
        }

        // ─── TEACHER: Nhập/cập nhật điểm 1 học sinh ────────────────────────
        [HttpPut("{id}")]
        [Authorize(Roles = "teacher")]
        public async Task<IActionResult> UpdateGrade(int id, [FromBody] UpdateGradeRequest req)
        {
            var teacherId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            var grade = await _context.Grades
                .Include(g => g.ClassSubject)
                .FirstOrDefaultAsync(g => g.Id == id && g.ClassSubject.TeacherId == teacherId);

            // Nếu chưa có bản ghi điểm, tạo mới
            Grade target;
            if (grade == null)
            {
                // Kiểm tra classSubject thuộc GV
                var cs = await _context.ClassSubjects
                    .FirstOrDefaultAsync(c => c.Id == req.ClassSubjectId && c.TeacherId == teacherId);
                if (cs == null) return Forbid();

                target = new Grade { StudentId = req.StudentId, ClassSubjectId = req.ClassSubjectId };
                _context.Grades.Add(target);
            }
            else
            {
                if (grade.IsFinalized)
                    return BadRequest(new { message = "Điểm đã được chốt, không thể sửa" });
                target = grade;
            }

            // Cập nhật điểm thành phần
            target.ScoreOral = req.ScoreOral;
            target.Score15m1 = req.Score15m1; target.Score15m2 = req.Score15m2; target.Score15m3 = req.Score15m3;
            target.Score1h1 = req.Score1h1; target.Score1h2 = req.Score1h2; target.Score1h3 = req.Score1h3;
            target.ScoreFinal = req.ScoreFinal;
            target.UpdatedBy = teacherId;
            target.UpdatedAt = DateTime.Now;

            // Tính TB server-side (không tin client)
            var scores15m = new[] { req.Score15m1, req.Score15m2, req.Score15m3 }.Where(v => v.HasValue).Select(v => v!.Value).ToList();
            var scores1h  = new[] { req.Score1h1, req.Score1h2, req.Score1h3 }.Where(v => v.HasValue).Select(v => v!.Value).ToList();
            target.Avg15m = scores15m.Any() ? Math.Round(scores15m.Average(), 2) : null;
            target.Avg1h  = scores1h.Any()  ? Math.Round(scores1h.Average(), 2)  : null;

            // GPA theo công thức THPT: (miệng*1 + tb15m*1 + tb1h*2 + cuoiky*3) / 7
            var hasOral = req.ScoreOral.HasValue;
            if (target.Avg15m.HasValue && target.Avg1h.HasValue && req.ScoreFinal.HasValue)
            {
                double oralPart = hasOral ? req.ScoreOral!.Value * 1 : 0;
                double divisor = hasOral ? 7 : 6;
                target.GpaSubject = Math.Round(
                    (oralPart + target.Avg15m.Value * 1 + target.Avg1h.Value * 2 + req.ScoreFinal.Value * 3) / divisor, 2);
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã cập nhật điểm", GpaSubject = target.GpaSubject });
        }

        // ─── TEACHER: Chốt điểm học kỳ (lock) ────────────────────────────────
        [HttpPost("finalize/{classSubjectId}")]
        [Authorize(Roles = "teacher")]
        public async Task<IActionResult> FinalizeGrades(int classSubjectId)
        {
            var teacherId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var cs = await _context.ClassSubjects
                .FirstOrDefaultAsync(c => c.Id == classSubjectId && c.TeacherId == teacherId);
            if (cs == null) return Forbid();

            await _context.Grades
                .Where(g => g.ClassSubjectId == classSubjectId)
                .ExecuteUpdateAsync(s => s.SetProperty(g => g.IsFinalized, true));

            return Ok(new { message = "Đã chốt điểm học kỳ" });
        }

        // ─── TEACHER: Lấy danh sách môn/lớp mình đang dạy ────────────────────
        [HttpGet("my-subjects")]
        [Authorize(Roles = "teacher")]
        public async Task<IActionResult> GetMySubjects()
        {
            var teacherId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            var subjects = await _context.ClassSubjects
                .Include(cs => cs.Subject)
                .Include(cs => cs.Class)
                .Where(cs => cs.TeacherId == teacherId)
                .Select(cs => new
                {
                    ClassSubjectId = cs.Id,
                    SubjectName = cs.Subject.Name,
                    ClassName = cs.Class.Name,
                    cs.Semester,
                    cs.SchoolYear
                })
                .OrderBy(x => x.ClassName)
                .ThenBy(x => x.SubjectName)
                .ToListAsync();

            return Ok(subjects);
        }
    }
}

// ─── Request DTOs ─────────────────────────────────────────────────────────────
public class UpdateGradeRequest
{
    public int StudentId { get; set; }
    public int ClassSubjectId { get; set; }
    public double? ScoreOral { get; set; }
    public double? Score15m1 { get; set; }
    public double? Score15m2 { get; set; }
    public double? Score15m3 { get; set; }
    public double? Score1h1 { get; set; }
    public double? Score1h2 { get; set; }
    public double? Score1h3 { get; set; }
    public double? ScoreFinal { get; set; }
}
