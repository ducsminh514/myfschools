using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace myfschool_be.Services
{
    public class EmailService
    {
        private readonly IConfiguration _config;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration config, ILogger<EmailService> logger)
        {
            _config = config;
            _logger = logger;
        }

        /// <summary>
        /// Gửi mã OTP đến email người dùng
        /// </summary>
        public async Task<bool> SendOtpAsync(string toEmail, string otp, string userName)
        {
            try
            {
                var emailSettings = _config.GetSection("Email");
                var senderEmail   = emailSettings["SenderEmail"]!;
                var senderName    = emailSettings["SenderName"] ?? "FPT School";
                var smtpHost      = emailSettings["SmtpHost"] ?? "smtp.gmail.com";
                var smtpPort      = int.Parse(emailSettings["SmtpPort"] ?? "587");
                var smtpUser      = emailSettings["SmtpUser"] ?? senderEmail;
                var smtpPassword  = emailSettings["SmtpPassword"]!;

                var message = new MimeMessage();
                message.From.Add(new MailboxAddress(senderName, senderEmail));
                message.To.Add(new MailboxAddress(userName, toEmail));
                message.Subject = $"[FPT School] Mã OTP xác thực: {otp}";

                // Body HTML đẹp
                message.Body = new TextPart("html")
                {
                    Text = $@"
<div style='font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px; background: #f8f9fa; border-radius: 12px;'>
  <div style='text-align: center; margin-bottom: 24px;'>
    <h2 style='color: #1a237e; margin: 0;'>🎓 FPT School</h2>
    <p style='color: #666; font-size: 14px;'>Xác thực mật khẩu</p>
  </div>
  <div style='background: white; padding: 24px; border-radius: 8px; text-align: center;'>
    <p style='color: #333; margin-bottom: 16px;'>Xin chào <b>{userName}</b>,</p>
    <p style='color: #666; margin-bottom: 24px;'>Mã OTP để đặt lại mật khẩu của bạn là:</p>
    <div style='background: #e8eaf6; padding: 16px 32px; border-radius: 8px; display: inline-block; margin-bottom: 24px;'>
      <span style='font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1a237e;'>{otp}</span>
    </div>
    <p style='color: #ef6c00; font-size: 13px; margin-bottom: 8px;'>⏰ Mã có hiệu lực trong <b>5 phút</b></p>
    <p style='color: #999; font-size: 12px;'>Nếu bạn không yêu cầu đổi mật khẩu, vui lòng bỏ qua email này.</p>
  </div>
  <p style='text-align: center; color: #bbb; font-size: 11px; margin-top: 16px;'>© FPT School - Hệ thống quản lý trường học</p>
</div>"
                };

                using var client = new SmtpClient();
                await client.ConnectAsync(smtpHost, smtpPort, SecureSocketOptions.StartTls);
                await client.AuthenticateAsync(smtpUser, smtpPassword);
                await client.SendAsync(message);
                await client.DisconnectAsync(true);

                _logger.LogInformation("OTP email sent to {Email}", toEmail);
                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to send OTP email to {Email}", toEmail);
                return false;
            }
        }
    }
}
