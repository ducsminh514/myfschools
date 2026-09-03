using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using myfschool_be.Models;

namespace myfschool_be.Pages.Admin.Schedules
{
    public class ScheduleEntry
    {
        public string SubjectName { get; set; } = "";
        public string TeacherName { get; set; } = "";
        public string Room { get; set; } = "";
    }

    public class IndexModel : PageModel
    {
        private readonly FptschoolContext _context;
        public IndexModel(FptschoolContext context) { _context = context; }

        public List<Class> ClassList { get; set; } = new();
        public int SelectedClassId { get; set; }
        public string SelectedClassName { get; set; } = "";
        public Dictionary<string, ScheduleEntry>? ScheduleGrid { get; set; }

        public async Task OnGetAsync(int classId = 0)
        {
            ClassList = await _context.Classes.OrderBy(c => c.Name).ToListAsync();
            SelectedClassId = classId;

            if (classId > 0)
            {
                var cls = ClassList.FirstOrDefault(c => c.Id == classId);
                SelectedClassName = cls?.Name ?? "";

                // Lấy TKB của lớp, join lên subject + teacher
                var schedules = await _context.Schedules
                    .Include(s => s.ClassSubject)
                        .ThenInclude(cs => cs.Subject)
                    .Include(s => s.ClassSubject)
                        .ThenInclude(cs => cs.Teacher)
                    .Where(s => s.ClassSubject.ClassId == classId)
                    .ToListAsync();

                ScheduleGrid = new Dictionary<string, ScheduleEntry>();
                foreach (var s in schedules)
                {
                    var key = $"{s.DayOfWeek}-{s.PeriodNo}";
                    ScheduleGrid[key] = new ScheduleEntry
                    {
                        SubjectName = s.ClassSubject?.Subject?.Name ?? "?",
                        TeacherName = s.ClassSubject?.Teacher?.FullName ?? "?",
                        Room = s.Room ?? ""
                    };
                }
            }
        }
    }
}
