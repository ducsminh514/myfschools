using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using myfschool_be.Models;
using OfficeOpenXml;

namespace myfschool_be.Pages.Admin.Schedules
{
    public class ImportRow
    {
        public int RowNumber { get; set; }
        public string ClassName { get; set; } = "";
        public int DayOfWeek { get; set; }
        public int PeriodNo { get; set; }
        public string SubjectName { get; set; } = "";
        public string TeacherName { get; set; } = "";
        public string Room { get; set; } = "";
        public bool IsValid { get; set; } = true;
        public string Error { get; set; } = "";
    }

    public class ImportModel : PageModel
    {
        private readonly FptschoolContext _context;
        private readonly IWebHostEnvironment _env;

        public ImportModel(FptschoolContext context, IWebHostEnvironment env)
        {
            _context = context;
            _env = env;
        }

        public List<ImportRow>? PreviewRows { get; set; }
        public int ValidCount { get; set; }
        public int ErrorCount { get; set; }
        public string? TempFileName { get; set; }

        public void OnGet() { }

        // Step 1: Upload + Parse + Validate → Preview
        public async Task<IActionResult> OnPostUploadAsync(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                TempData["Error"] = "Vui lòng chọn file";
                return Page();
            }
            if (!file.FileName.EndsWith(".xlsx", StringComparison.OrdinalIgnoreCase))
            {
                TempData["Error"] = "Chỉ chấp nhận file .xlsx";
                return Page();
            }
            if (file.Length > 5 * 1024 * 1024) // 5MB
            {
                TempData["Error"] = "File quá lớn (tối đa 5MB)";
                return Page();
            }

            // Lưu file tạm (ngoài wwwroot để không bị truy cập từ URL)
            var tempDir = Path.Combine(Path.GetTempPath(), "fptschool_import");
            Directory.CreateDirectory(tempDir);
            TempFileName = $"import_{Guid.NewGuid():N}.xlsx";
            var filePath = Path.Combine(tempDir, TempFileName);
            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream);
            }

            // Parse & Validate
            PreviewRows = await ParseAndValidate(filePath);
            ValidCount = PreviewRows.Count(r => r.IsValid);
            ErrorCount = PreviewRows.Count(r => !r.IsValid);

            return Page();
        }

        // Step 2: Confirm Import
        public async Task<IActionResult> OnPostConfirmAsync(string fileName)
        {
            var filePath = Path.Combine(Path.GetTempPath(), "fptschool_import", fileName);
            if (!System.IO.File.Exists(filePath))
            {
                TempData["Error"] = "File không tồn tại. Vui lòng upload lại.";
                return RedirectToPage();
            }

            var rows = await ParseAndValidate(filePath);
            var validRows = rows.Where(r => r.IsValid).ToList();

            if (!validRows.Any())
            {
                TempData["Error"] = "Không có dòng hợp lệ để import";
                return RedirectToPage();
            }

            // Load lookup data
            var classes = await _context.Classes.ToListAsync();
            var subjects = await _context.Subjects.ToListAsync();
            var teachers = await _context.Users
                .Include(u => u.Roles)
                .Where(u => u.Roles.Any(r => r.Name == "teacher"))
                .ToListAsync();

            int imported = 0;
            foreach (var row in validRows)
            {
                var cls = classes.FirstOrDefault(c => c.Name.Equals(row.ClassName, StringComparison.OrdinalIgnoreCase));
                var sub = subjects.FirstOrDefault(s => s.Name.Equals(row.SubjectName, StringComparison.OrdinalIgnoreCase));
                var teacher = teachers.FirstOrDefault(t => t.FullName.Equals(row.TeacherName, StringComparison.OrdinalIgnoreCase));

                if (cls == null || sub == null || teacher == null) continue;

                // Tìm hoặc tạo class_subject
                var classSubject = await _context.ClassSubjects
                    .FirstOrDefaultAsync(cs => cs.ClassId == cls.Id && cs.SubjectId == sub.Id && cs.TeacherId == teacher.Id);

                if (classSubject == null)
                {
                    classSubject = new ClassSubject
                    {
                        ClassId = cls.Id,
                        SubjectId = sub.Id,
                        TeacherId = teacher.Id,
                        SchoolYear = $"{DateTime.Now.Year}-{DateTime.Now.Year + 1}",
                        Semester = DateTime.Now.Month >= 8 ? 1 : 2
                    };
                    _context.ClassSubjects.Add(classSubject);
                    await _context.SaveChangesAsync(); // Cần ID
                }

                // Check trùng: cùng lớp + cùng thứ + cùng tiết (bất kể môn nào)
                bool exists = await _context.Schedules.AnyAsync(s =>
                    s.ClassSubject.ClassId == cls.Id &&
                    s.DayOfWeek == row.DayOfWeek &&
                    s.PeriodNo == row.PeriodNo);

                if (!exists)
                {
                    _context.Schedules.Add(new Schedule
                    {
                        ClassSubjectId = classSubject.Id,
                        DayOfWeek = row.DayOfWeek,
                        PeriodNo = row.PeriodNo,
                        Room = row.Room
                    });
                    imported++;
                }
            }

            await _context.SaveChangesAsync();

            // Xoá file tạm
            try { System.IO.File.Delete(filePath); } catch { }

            TempData["Success"] = $"Import thành công {imported} lịch học! ({validRows.Count - imported} bị bỏ qua do trùng)";
            return RedirectToPage("/Admin/Schedules/Index");
        }

        private async Task<List<ImportRow>> ParseAndValidate(string filePath)
        {
            ExcelPackage.License.SetNonCommercialOrganization("FPT School");

            var rows = new List<ImportRow>();

            // Load lookup data 1 lần để validate nhanh
            var classNames = await _context.Classes.Select(c => c.Name.ToLower()).ToListAsync();
            var subjectNames = await _context.Subjects.Select(s => s.Name.ToLower()).ToListAsync();
            var teacherNames = await _context.Users
                .Where(u => u.Roles.Any(r => r.Name == "teacher"))
                .Select(u => u.FullName.ToLower())
                .ToListAsync();

            using var package = new ExcelPackage(new FileInfo(filePath));
            var ws = package.Workbook.Worksheets.FirstOrDefault();
            if (ws == null) return rows;

            for (int r = 2; r <= ws.Dimension?.End.Row; r++) // Bỏ header row 1
            {
                var row = new ImportRow
                {
                    RowNumber = r,
                    ClassName = ws.Cells[r, 1].Text?.Trim() ?? "",
                    Room = ws.Cells[r, 6].Text?.Trim() ?? ""
                };

                // Parse Day
                if (int.TryParse(ws.Cells[r, 2].Text, out int day) && day >= 2 && day <= 7)
                    row.DayOfWeek = day;
                else { row.IsValid = false; row.Error = "Thứ phải 2-7"; }

                // Parse Period
                if (int.TryParse(ws.Cells[r, 3].Text, out int period) && period >= 1 && period <= 10)
                    row.PeriodNo = period;
                else { row.IsValid = false; row.Error += " | Tiết phải 1-10"; }

                row.SubjectName = ws.Cells[r, 4].Text?.Trim() ?? "";
                row.TeacherName = ws.Cells[r, 5].Text?.Trim() ?? "";

                // Validate tồn tại
                if (!classNames.Contains(row.ClassName.ToLower()))
                { row.IsValid = false; row.Error += $" | Lớp '{row.ClassName}' không tồn tại"; }

                if (!subjectNames.Contains(row.SubjectName.ToLower()))
                { row.IsValid = false; row.Error += $" | Môn '{row.SubjectName}' không tồn tại"; }

                if (!teacherNames.Contains(row.TeacherName.ToLower()))
                { row.IsValid = false; row.Error += $" | GV '{row.TeacherName}' không tồn tại"; }

                if (string.IsNullOrWhiteSpace(row.ClassName)) { row.IsValid = false; row.Error += " | Thiếu lớp"; }
                if (string.IsNullOrWhiteSpace(row.Room)) { row.IsValid = false; row.Error += " | Thiếu phòng"; }
                if (row.Room.Length > 20) { row.IsValid = false; row.Error += " | Phòng quá dài (tối đa 20 ký tự)"; }

                row.Error = row.Error.TrimStart(' ', '|');
                rows.Add(row);
            }

            return rows;
        }
    }
}
