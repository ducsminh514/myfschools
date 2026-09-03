using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using myfschool_be.Models;

namespace myfschool_be.Pages.Admin.Users
{
    public class IndexModel : PageModel
    {
        private readonly FptschoolContext _context;
        private const int PageSize = 20;

        public IndexModel(FptschoolContext context) { _context = context; }

        public List<User> Users { get; set; } = new();
        public string? Search { get; set; }
        public string? RoleFilter { get; set; }
        public int CurrentPage { get; set; } = 1;
        public int TotalPages { get; set; }
        public int TotalCount { get; set; }

        public async Task OnGetAsync(string? search, string? role, int page = 1)
        {
            Search = search;
            RoleFilter = role;
            CurrentPage = page < 1 ? 1 : page;

            IQueryable<User> query = _context.Users.Include(u => u.Roles);

            // Search
            if (!string.IsNullOrWhiteSpace(search))
            {
                var s = search.Trim().ToLower();
                query = query.Where(u =>
                    u.FullName.ToLower().Contains(s) ||
                    u.Email.ToLower().Contains(s) ||
                    u.Phone.Contains(s));
            }

            // Filter role
            if (!string.IsNullOrWhiteSpace(role))
            {
                query = query.Where(u => u.Roles.Any(r => r.Name == role));
            }

            TotalCount = await query.CountAsync();
            TotalPages = (int)Math.Ceiling((double)TotalCount / PageSize);

            Users = await query
                .OrderBy(u => u.Id)
                .Skip((CurrentPage - 1) * PageSize)
                .Take(PageSize)
                .ToListAsync();
        }
    }
}
