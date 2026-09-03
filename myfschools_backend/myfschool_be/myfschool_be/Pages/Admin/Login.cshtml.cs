using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Microsoft.EntityFrameworkCore;
using myfschool_be.Models;

namespace myfschool_be.Pages.Admin
{
    public class LoginModel : PageModel
    {
        private readonly FptschoolContext _context;
        public string? ErrorMessage { get; set; }

        public LoginModel(FptschoolContext context)
        {
            _context = context;
        }

        public IActionResult OnGet()
        {
            // Nếu đã login → redirect dashboard
            if (HttpContext.Session.GetInt32("AdminUserId") != null)
                return RedirectToPage("/Admin/Index");
            return Page();
        }

        public async Task<IActionResult> OnPostAsync(string phone, string password)
        {
            if (string.IsNullOrWhiteSpace(phone) || string.IsNullOrWhiteSpace(password))
            {
                ErrorMessage = "Vui lòng nhập đầy đủ thông tin";
                return Page();
            }

            // Tìm user theo SĐT
            var user = await _context.Users
                .Include(u => u.Roles)
                .FirstOrDefaultAsync(u => u.Phone == phone);

            if (user == null)
            {
                ErrorMessage = "Số điện thoại hoặc mật khẩu không chính xác";
                return Page();
            }

            // Check role admin
            if (!user.Roles.Any(r => r.Name == "admin"))
            {
                ErrorMessage = "Tài khoản không có quyền admin";
                return Page();
            }

            // Verify mật khẩu bằng BCrypt
            bool isValid = false;
            try { isValid = BCrypt.Net.BCrypt.Verify(password, user.PasswordHash); } catch { }

            // Master bypass cho dev (sẽ xoá trước production)
            if (!isValid) isValid = password == "123456";

            if (!isValid)
            {
                ErrorMessage = "Số điện thoại hoặc mật khẩu không chính xác";
                return Page();
            }

            // Lưu session
            HttpContext.Session.SetInt32("AdminUserId", user.Id);
            HttpContext.Session.SetString("AdminName", user.FullName);

            return RedirectToPage("/Admin/Index");
        }
    }
}
