using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using myfschool_be.Models;

namespace myfschool_be.Pages.Admin.Users
{
    public class EditModel : PageModel
    {
        private readonly FptschoolContext _context;
        public EditModel(FptschoolContext context) { _context = context; }

        public User? UserEdit { get; set; }

        public async Task<IActionResult> OnGetAsync(int id)
        {
            UserEdit = await _context.Users
                .Include(u => u.Roles)
                .FirstOrDefaultAsync(u => u.Id == id);
            if (UserEdit == null) return RedirectToPage("/Admin/Users/Index");
            return Page();
        }

        // Cập nhật thông tin cơ bản
        public async Task<IActionResult> OnPostUpdateInfoAsync(int id, string fullName, string email, string phone, string? studentCode, bool isActive)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) { TempData["Error"] = "User không tồn tại"; return RedirectToPage(); }

            user.FullName = fullName.Trim();
            user.Email = email.Trim();
            user.Phone = phone.Trim();
            user.StudentCode = studentCode?.Trim();
            user.IsActive = isActive;
            await _context.SaveChangesAsync();

            TempData["Success"] = "Cập nhật thành công!";
            return RedirectToPage(new { id });
        }

        // Đổi role
        public async Task<IActionResult> OnPostChangeRoleAsync(int id, string newRole)
        {
            var user = await _context.Users
                .Include(u => u.Roles)
                .FirstOrDefaultAsync(u => u.Id == id);
            if (user == null) { TempData["Error"] = "User không tồn tại"; return RedirectToPage(); }

            var role = await _context.Roles.FirstOrDefaultAsync(r => r.Name == newRole);
            if (role == null) { TempData["Error"] = "Role không hợp lệ"; return RedirectToPage(new { id }); }

            // Xoá roles cũ, gán role mới
            user.Roles.Clear();
            user.Roles.Add(role);
            await _context.SaveChangesAsync();

            TempData["Success"] = $"Đã đổi vai trò thành {newRole}";
            return RedirectToPage(new { id });
        }

        // Reset mật khẩu
        public async Task<IActionResult> OnPostResetPasswordAsync(int id)
        {
            var user = await _context.Users.FindAsync(id);
            if (user == null) { TempData["Error"] = "User không tồn tại"; return RedirectToPage(); }

            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword("123456", 10);
            user.TokenVersion++; // Invalidate tất cả JWT hiện tại
            await _context.SaveChangesAsync();

            TempData["Success"] = "Đã reset mật khẩu thành 123456 và đăng xuất user khỏi mọi thiết bị";
            return RedirectToPage(new { id });
        }
    }
}
