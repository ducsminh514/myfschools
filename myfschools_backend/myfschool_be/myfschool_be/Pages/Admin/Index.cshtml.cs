using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using myfschool_be.Models;

namespace myfschool_be.Pages.Admin
{
    public class IndexModel : PageModel
    {
        private readonly FptschoolContext _context;

        public IndexModel(FptschoolContext context) { _context = context; }

        public int StudentCount { get; set; }
        public int TeacherCount { get; set; }
        public int ClassCount { get; set; }
        public int ScheduleCount { get; set; }
        public int ClubCount { get; set; }
        public int EventCount { get; set; }
        public List<User> RecentUsers { get; set; } = new();
        public List<Event> UpcomingEvents { get; set; } = new();

        public async Task OnGetAsync()
        {
            // Đếm stats — mỗi cái 1 query nhẹ (COUNT)
            StudentCount = await _context.Users
                .CountAsync(u => u.Roles.Any(r => r.Name == "student"));
            TeacherCount = await _context.Users
                .CountAsync(u => u.Roles.Any(r => r.Name == "teacher"));
            ClassCount = await _context.Classes.CountAsync();
            ScheduleCount = await _context.Schedules.CountAsync();
            ClubCount = await _context.Clubs.CountAsync();
            EventCount = await _context.Events.CountAsync();

            // 5 users mới nhất
            RecentUsers = await _context.Users
                .Include(u => u.Roles)
                .OrderByDescending(u => u.Id)
                .Take(5)
                .ToListAsync();

            // 5 sự kiện sắp tới
            UpcomingEvents = await _context.Events
                .Where(e => e.StartAt >= DateTime.Now)
                .OrderBy(e => e.StartAt)
                .Take(5)
                .ToListAsync();
        }
    }
}
