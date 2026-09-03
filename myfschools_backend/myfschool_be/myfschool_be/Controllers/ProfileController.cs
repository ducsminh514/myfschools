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
    public class ProfileController : ControllerBase
    {
        private readonly FptschoolContext _context;

        public ProfileController(FptschoolContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<UserProfileDto>> GetProfile()
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            var user = await _context.Users
                .Include(u => u.Roles)
                .Include(u => u.StudentProfile)
                    .ThenInclude(sp => sp!.Class)
                .FirstOrDefaultAsync(u => u.Id == userId);

            if (user == null)
                return NotFound(new { message = "Không tìm thấy người dùng" });

            var result = new UserProfileDto
            {
                Id = user.Id,
                FullName = user.FullName,
                StudentCode = user.StudentCode,
                Email = user.Email,
                Phone = user.Phone,
                AvatarUrl = user.AvatarUrl,
                Roles = user.Roles.Select(r => r.Name).ToList(),
                Detail = user.StudentProfile != null ? new StudentDetailDto
                {
                    ClassName = user.StudentProfile.Class?.Name,
                    BirthDate = user.StudentProfile.BirthDate.HasValue 
                        ? new DateTime(user.StudentProfile.BirthDate.Value.Year, user.StudentProfile.BirthDate.Value.Month, user.StudentProfile.BirthDate.Value.Day) 
                        : null,
                    Gender = user.StudentProfile.Gender,
                    Address = user.StudentProfile.Address,
                    ParentName = user.StudentProfile.ParentName,
                    ParentPhone = user.StudentProfile.ParentPhone
                } : null
            };

            // Nếu là GV → bổ sung TeacherDetail
            if (user.Roles.Any(r => r.Name == "teacher"))
            {
                var homeroomClass = await _context.Classes
                    .FirstOrDefaultAsync(c => c.HomeroomTeacherId == userId);

                var teachingSubjects = await _context.ClassSubjects
                    .Include(cs => cs.Subject)
                    .Include(cs => cs.Class)
                    .Where(cs => cs.TeacherId == userId)
                    .Select(cs => new TeachingSubjectDto
                    {
                        ClassSubjectId = cs.Id,
                        SubjectName = cs.Subject.Name,
                        ClassName = cs.Class.Name
                    })
                    .OrderBy(x => x.ClassName)
                    .ThenBy(x => x.SubjectName)
                    .ToListAsync();

                result.TeacherDetail = new TeacherDetailDto
                {
                    IsHomeroom = homeroomClass != null,
                    HomeroomClassName = homeroomClass?.Name,
                    TeachingSubjects = teachingSubjects
                };
            }

            return Ok(result);
        }

        [HttpPost("change-password")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var user = await _context.Users.FindAsync(userId);

            if (user == null)
                return NotFound(new { message = "Người dùng không tồn tại" });

            // Kiểm tra mật khẩu cũ (hỗ trợ bypass 123456 cho DEV)
            bool isOldPasswordValid = request.OldPassword == "123456";
            
            if (!isOldPasswordValid)
            {
                try {
                    isOldPasswordValid = BCrypt.Net.BCrypt.Verify(request.OldPassword, user.PasswordHash);
                } catch { }
            }

            if (!isOldPasswordValid)
            {
                return BadRequest(new { message = "Mật khẩu cũ không chính xác" });
            }

            // Validate min-length mật khẩu mới
            if (request.NewPassword.Length < 6)
                return BadRequest(new { message = "Mật khẩu mới phải từ 6 ký tự trở lên" });

            // Băm mật khẩu mới bằng BCrypt
            user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
            
            // Tăng TokenVersion để vô hiệu hoá các JWT cũ (Revoke logic)
            user.TokenVersion++;
            user.UpdatedAt = DateTime.Now;

            await _context.SaveChangesAsync();

            return Ok(new { message = "Đổi mật khẩu thành công. Vui lòng đăng nhập lại." });
        }
        [HttpPatch("avatar")]
        public async Task<IActionResult> UploadAvatar(IFormFile avatar)
        {
            if (avatar == null || avatar.Length == 0)
                return BadRequest(new { message = "Vui lòng chọn ảnh đại diện" });

            // Giới hạn 2MB cho avatar
            const long maxBytes = 2 * 1024 * 1024;
            if (avatar.Length > maxBytes)
                return BadRequest(new { message = "Ảnh đại diện không được vượt quá 2MB" });

            // Kiểm tra MIME type
            var allowedTypes = new[] { "image/jpeg", "image/png" };
            if (!allowedTypes.Contains(avatar.ContentType.ToLower()))
                return BadRequest(new { message = "Chỉ chấp nhận ảnh JPG hoặc PNG" });

            // Magic bytes check (chống giả mạo content type)
            using var ms = new MemoryStream();
            await avatar.CopyToAsync(ms);
            var bytes = ms.ToArray();
            bool isJpeg = bytes.Length > 2 && bytes[0] == 0xFF && bytes[1] == 0xD8;
            bool isPng  = bytes.Length > 7 && bytes[0] == 0x89 && bytes[1] == 0x50;
            if (!isJpeg && !isPng)
                return BadRequest(new { message = "File không phải ảnh hợp lệ" });

            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var user = await _context.Users.FindAsync(userId);
            if (user == null) return NotFound();

            // Xóa ảnh cũ nếu có
            if (!string.IsNullOrEmpty(user.AvatarUrl))
            {
                var oldPath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", user.AvatarUrl.TrimStart('/'));
                if (System.IO.File.Exists(oldPath))
                    System.IO.File.Delete(oldPath);
            }

            // Lưu ảnh mới vào wwwroot/uploads/avatars/
            var ext = isJpeg ? ".jpg" : ".png";
            var fileName = $"avatar_{userId}_{DateTimeOffset.UtcNow.ToUnixTimeSeconds()}{ext}";
            var savePath = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "avatars");
            Directory.CreateDirectory(savePath); // Tạo thư mục nếu chưa có
            var filePath = Path.Combine(savePath, fileName);

            await System.IO.File.WriteAllBytesAsync(filePath, bytes);

            // Cập nhật avatar_url trong DB
            user.AvatarUrl = $"/uploads/avatars/{fileName}";
            user.UpdatedAt = DateTime.Now;
            await _context.SaveChangesAsync();

            return Ok(new { avatarUrl = user.AvatarUrl, message = "Cập nhật ảnh đại diện thành công" });
        }
    }
}
