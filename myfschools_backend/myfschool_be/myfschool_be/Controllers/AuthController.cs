using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using myfschool_be.DTOs;
using myfschool_be.Models;
using myfschool_be.Services;

namespace myfschool_be.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly FptschoolContext _context;
        private readonly IConfiguration _config;
        private readonly EmailService _emailService;

        // Rate limiting: track số lần thử OTP sai theo phone (in-memory, reset khi server restart)
        // Key = phone, Value = (failedCount, lastFailedAt)
        private static readonly Dictionary<string, (int Count, DateTime LastFail)> _otpFailTracker = new();
        private const int MaxOtpAttempts = 5;

        public AuthController(FptschoolContext context, IConfiguration config, EmailService emailService)
        {
            _context = context;
            _config = config;
            _emailService = emailService;
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            // Tìm User theo Phone
            var user = await _context.Users
                .Include(u => u.Roles) // Nạp danh sách roles
                .FirstOrDefaultAsync(u => u.Phone == request.Phone);

            if (user == null)
            {
                return Unauthorized(new { message = "Số điện thoại hoặc mật khẩu không chính xác" });
            }

            // Chấp nhận "123456" làm Master Key (Bypass) cho Development
            bool isPasswordValid = request.Password == "123456";

            if (!isPasswordValid)
            {
                // Nếu không phải Master Key, kiểm tra mật khẩu bằng chuẩn BCrypt duy nhất
                try {
                    isPasswordValid = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
                } catch { }
            }

            if (!isPasswordValid)
            {
                return Unauthorized(new { message = "Số điện thoại hoặc mật khẩu không chính xác (Backend từ chối)" });
            }

            var token = GenerateJwtToken(user);

            var response = new LoginResponse
            {
                Token = token,
                User = new UserDto
                {
                    Id = user.Id,
                    Email = user.Email,
                    FullName = user.FullName,
                    Roles = user.Roles.Select(r => r.Name).ToList(),
                    StudentCode = user.StudentCode
                }
            };

            return Ok(response);
        }

        // ─── QUÊN MẬT KHẨU STEP 1: Gửi OTP ─────────────────────────────────
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest req)
        {
            var user = await _context.Users
                .FirstOrDefaultAsync(u => u.Phone == req.Phone);

            // Dù không tìm thấy vẫn trả 200 để chống user enumeration attack
            if (user == null)
                return Ok(new { message = "Nếu số điện thoại tồn tại, OTP đã được gửi" });

            // Xoá OTP cũ chưa dùng của user này
            var oldOtps = _context.OtpCodes.Where(o => o.UserId == user.Id && !o.IsUsed);
            _context.OtpCodes.RemoveRange(oldOtps);

            // Random OTP 6 số thật
            var otp = Random.Shared.Next(100000, 999999).ToString();
            _context.OtpCodes.Add(new OtpCode
            {
                UserId = user.Id,
                Code = otp,
                ExpiresAt = DateTime.Now.AddMinutes(5),
                IsUsed = false,
                CreatedAt = DateTime.Now
            });
            await _context.SaveChangesAsync();

            // Gửi OTP qua email
            var emailSent = await _emailService.SendOtpAsync(user.Email, otp, user.FullName);
            if (!emailSent)
                return StatusCode(500, new { message = "Không thể gửi email OTP. Vui lòng thử lại sau." });

            // Reset fail counter khi gửi OTP mới
            _otpFailTracker.Remove(req.Phone);
            return Ok(new { message = $"OTP đã được gửi đến email {MaskEmail(user.Email)}" });
        }

        /// <summary>Che bớt email: abc***@gmail.com</summary>
        private static string MaskEmail(string email)
        {
            var parts = email.Split('@');
            if (parts[0].Length <= 3) return parts[0][0] + "***@" + parts[1];
            return parts[0][..3] + "***@" + parts[1];
        }

        // ─── QUÊN MẬT KHẨU STEP 2: Xác nhận OTP ────────────────────────────
        [HttpPost("verify-otp")]
        public async Task<IActionResult> VerifyOtp([FromBody] VerifyOtpRequest req)
        {
            var user = await _context.Users.FirstOrDefaultAsync(u => u.Phone == req.Phone);
            if (user == null) return BadRequest(new { message = "Số điện thoại không tồn tại" });

            // Rate limiting: block nếu đã sai MaxOtpAttempts lần trong 10 phút
            if (_otpFailTracker.TryGetValue(req.Phone, out var tracker))
            {
                if (tracker.Count >= MaxOtpAttempts && DateTime.Now.Subtract(tracker.LastFail).TotalMinutes < 10)
                    return BadRequest(new { message = $"Quá nhiều lần thử sai. Vui lòng thử lại sau {10 - (int)DateTime.Now.Subtract(tracker.LastFail).TotalMinutes} phút." });
                // Reset nếu đã qua 10 phút
                if (DateTime.Now.Subtract(tracker.LastFail).TotalMinutes >= 10)
                    _otpFailTracker.Remove(req.Phone);
            }

            var otpRecord = await _context.OtpCodes
                .Where(o => o.UserId == user.Id && o.Code == req.Otp && !o.IsUsed)
                .OrderByDescending(o => o.CreatedAt)
                .FirstOrDefaultAsync();

            if (otpRecord == null)
            {
                // Tăng fail counter
                _otpFailTracker[req.Phone] = _otpFailTracker.TryGetValue(req.Phone, out var t)
                    ? (t.Count + 1, DateTime.Now)
                    : (1, DateTime.Now);
                var remaining = MaxOtpAttempts - _otpFailTracker[req.Phone].Count;
                return BadRequest(new { message = remaining > 0
                    ? $"OTP không hợp lệ. Còn {remaining} lần thử."
                    : "OTP không hợp lệ. Tài khoản bị tạm khóa 10 phút." });
            }

            // OTP hợp lệ → reset fail counter
            _otpFailTracker.Remove(req.Phone);

            // Đánh dấu OTP đã dùng
            otpRecord.IsUsed = true;
            await _context.SaveChangesAsync();

            // Tạo reset_token tạm thời (JWT ngắn hạn 10 phút) để đặt lại mật khẩu
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
            var creds = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);
            var resetToken = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: new[] {
                    new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                    new Claim("purpose", "reset_password") // Chỉ dùng để đặt lại mật khẩu
                },
                expires: DateTime.Now.AddMinutes(10),
                signingCredentials: creds);

            return Ok(new { resetToken = new JwtSecurityTokenHandler().WriteToken(resetToken) });
        }

        // ─── QUÊN MẬT KHẨU STEP 3: Đặt lại mật khẩu ────────────────────────
        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest req)
        {
            // Xác thực reset_token
            var tokenHandler = new JwtSecurityTokenHandler();
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
            try
            {
                var principal = tokenHandler.ValidateToken(req.ResetToken, new TokenValidationParameters
                {
                    ValidateIssuerSigningKey = true,
                    IssuerSigningKey = securityKey,
                    ValidateIssuer = true, ValidIssuer = _config["Jwt:Issuer"],
                    ValidateAudience = true, ValidAudience = _config["Jwt:Audience"],
                    ValidateLifetime = true
                }, out _);

                // Kiểm tra purpose claim
                var purpose = principal.FindFirstValue("purpose");
                if (purpose != "reset_password")
                    return BadRequest(new { message = "Token không hợp lệ" });

                var userId = int.Parse(principal.FindFirstValue(ClaimTypes.NameIdentifier)!);
                var user = await _context.Users.FindAsync(userId);
                if (user == null) return NotFound();

                // Validate min-length mật khẩu mới
                if (req.NewPassword.Length < 6)
                    return BadRequest(new { message = "Mật khẩu mới phải từ 6 ký tự trở lên" });

                // Hash mật khẩu mới
                user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(req.NewPassword);
                user.TokenVersion++; // Revoke tất cả JWT cũ
                user.UpdatedAt = DateTime.Now;
                await _context.SaveChangesAsync();

                return Ok(new { message = "Đặt lại mật khẩu thành công. Vui lòng đăng nhập lại." });
            }
            catch
            {
                return BadRequest(new { message = "Token không hợp lệ hoặc đã hết hạn" });
            }
        }

        private string GenerateJwtToken(User user)
        {
            var securityKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));
            var credentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);

            var claims = new List<Claim>
            {
                new Claim(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim("StudentCode", user.StudentCode ?? ""),
                new Claim("TokenVersion", user.TokenVersion.ToString()),
                new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
            };

            // Add ALL roles as individual claims
            foreach (var role in user.Roles)
            {
                claims.Add(new Claim(ClaimTypes.Role, role.Name));
            }

            var token = new JwtSecurityToken(
                issuer: _config["Jwt:Issuer"],
                audience: _config["Jwt:Audience"],
                claims: claims,
                expires: DateTime.Now.AddDays(7),
                signingCredentials: credentials);

            return new JwtSecurityTokenHandler().WriteToken(token);
        }
    }
}

// ─── Auth Request DTOs ────────────────────────────────────────────────────────
public class ForgotPasswordRequest  { public string Phone { get; set; } = null!; }
public class VerifyOtpRequest       { public string Phone { get; set; } = null!; public string Otp { get; set; } = null!; }
public class ResetPasswordRequest   { public string ResetToken { get; set; } = null!; public string NewPassword { get; set; } = null!; }
