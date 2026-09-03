using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using myfschool_be.DTOs;
using myfschool_be.Models;

namespace myfschool_be.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class FormsController : ControllerBase
    {
        private readonly FptschoolContext _context;
        private readonly IWebHostEnvironment _environment;

        // IWebHostEnvironment giúp lấy ra đường dẫn ổ đĩa vật lý của Server (VD: C:/app/wwwroot)
        public FormsController(FptschoolContext context, IWebHostEnvironment environment)
        {
            _context = context;
            _environment = environment;
        }

        [HttpGet("my-forms")]
        public async Task<IActionResult> GetMyForms()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out int userId)) return Unauthorized();

            var forms = await _context.Forms
                .Where(f => f.StudentId == userId)
                .OrderByDescending(f => f.CreatedAt)
                .Select(f => new FormResponseDto
                {
                    Id = f.Id,
                    FormType = f.FormType,
                    Title = f.Title,
                    Content = f.Content,
                    AbsentDate = f.AbsentDate,
                    AttachmentUrl = f.AttachmentUrl,
                    Status = f.Status,
                    RejectReason = f.RejectReason,
                    CreatedAt = f.CreatedAt
                })
                .ToListAsync();

            return Ok(forms);
        }

        [HttpPost("create")]
        public async Task<IActionResult> CreateForm([FromForm] CreateFormRequestDto request)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out int userId)) return Unauthorized();

            // Kiểm tra Validation dữ liệu FormType để tránh vi phạm SQL CHECK Constraint
            var validFormTypes = new[] { "nghi_hoc", "phep_ra_ngoai", "mien_hoan_thi", "khieu_nai_diem", "xac_nhan_hoc_sinh", "khac" };
            if (!validFormTypes.Contains(request.FormType))
            {
                return BadRequest(new { message = $"Mã loại đơn '{request.FormType}' không hợp lệ. Vui lòng cập nhật Ứng dụng." });
            }

            string? attachmentDbUrl = null;

            // Xử lý File Tải lên (Nếu có)
            if (request.Attachment != null && request.Attachment.Length > 0)
            {
                // Kiểm tra Validation (Bảo vệ Server)
                var allowedImageTypes = new[] { "image/jpeg", "image/png", "image/jpg" };
                if (!allowedImageTypes.Contains(request.Attachment.ContentType.ToLower()))
                {
                    return BadRequest(new { message = "Lỗi bảo mật! Chỉ cho phép tải lên đuôi .jpg, .png" });
                }

                if (request.Attachment.Length > 5 * 1024 * 1024) // 5 MB
                {
                    return BadRequest(new { message = "Kích thước ảnh quá lớn (Tối đa 5MB)" });
                }

                // Kiểm tra Ruột File (Magic Bytes) chống Malware giả mạo đuôi
                if (!IsValidImageSignature(request.Attachment))
                {
                    return BadRequest(new { message = "Lỗi bảo mật! Cấu trúc File bị làm giả mạo (Không phài hình ảnh thật)." });
                }

                // 1. Tạo thư mục wwwroot/uploads/forms nếu chưa tồn tại
                var uploadPath = Path.Combine(_environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"), "uploads", "forms");
                if (!Directory.Exists(uploadPath))
                {
                    Directory.CreateDirectory(uploadPath);
                }

                // 2. Mã hoá tên file để chống trùng lặp (dùng Guid)
                var fileName = Guid.NewGuid().ToString() + Path.GetExtension(request.Attachment.FileName);
                var fullFilePath = Path.Combine(uploadPath, fileName);

                // 3. Mở luồng Byte stream sao chép ghi dữ liệu xuống đĩa cứng
                using (var stream = new FileStream(fullFilePath, FileMode.Create))
                {
                    await request.Attachment.CopyToAsync(stream);
                }

                // 4. Tạo URL ảo dạng text để Client (Flutter) lấy về render Image.network()
                // Giao thức tạm thời dùng đường dẫn tĩnh tương đối
                attachmentDbUrl = $"/uploads/forms/{fileName}";
            }

            // Validate AssignedTo: nếu có thì phải là GV dạy lớp HS này
            if (request.AssignedTo.HasValue)
            {
                var studentProfile = await _context.StudentProfiles
                    .FirstOrDefaultAsync(sp => sp.UserId == userId);
                if (studentProfile == null)
                    return BadRequest(new { message = "Không tìm thấy hồ sơ học sinh" });

                // Kiểm tra GV này có dạy lớp HS không (GVBM) hoặc là GVCN lớp HS
                var isValidTeacher = await _context.ClassSubjects
                    .AnyAsync(cs => cs.ClassId == studentProfile.ClassId && cs.TeacherId == request.AssignedTo.Value)
                    || await _context.Classes
                    .AnyAsync(c => c.Id == studentProfile.ClassId && c.HomeroomTeacherId == request.AssignedTo.Value);

                if (!isValidTeacher)
                    return BadRequest(new { message = "Giáo viên được chọn không hợp lệ (không thuộc lớp bạn)" });
            }

            var newForm = new Form
            {
                StudentId = userId,
                FormType = request.FormType,
                Title = request.Title,
                Content = request.Content,
                AbsentDate = request.AbsentDate,
                AssignedTo = request.AssignedTo, // NULL = GVCN, có giá trị = GVBM cụ thể
                AttachmentUrl = attachmentDbUrl,
                Status = "pending", // Chữ thường đồng bộ với DB default + HomeController
                CreatedAt = DateTime.Now,
                UpdatedAt = DateTime.Now
            };

            _context.Forms.Add(newForm);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã gửi đơn thành công!", formId = newForm.Id });
        }

        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteForm(int id)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out int userId)) return Unauthorized();

            var form = await _context.Forms.FirstOrDefaultAsync(f => f.Id == id && f.StudentId == userId);
            if (form == null) return NotFound(new { message = "Không tìm thấy Đơn này" });

            if (form.Status != "pending")
            {
                return BadRequest(new { message = "Chỉ có thể thu hồi đơn đang chờ duyệt" });
            }

            // Xoá rác ổ cứng (Xoá ảnh)
            if (!string.IsNullOrEmpty(form.AttachmentUrl))
            {
                // form.AttachmentUrl có dạng "/uploads/forms/xyz.jpg", cần ánh xạ thành đường dẫn vật lý
                var filePath = Path.Combine(_environment.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot"), form.AttachmentUrl.TrimStart('/'));
                filePath = filePath.Replace('/', Path.DirectorySeparatorChar); // Đảm bảo đúng chuẩn Windows/Linux

                if (System.IO.File.Exists(filePath))
                {
                    System.IO.File.Delete(filePath);
                }
            }

            _context.Forms.Remove(form);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã thu hồi đơn và dọn dẹp ảnh thành công" });
        }

        [HttpGet("teacher/all-forms")]
        [Authorize(Roles = "teacher")]
        public async Task<IActionResult> GetTeacherForms()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out int userId)) return Unauthorized();

            // Lấy lớp mà GV này là GVCN
            var homeroomClassId = await _context.Classes
                .Where(c => c.HomeroomTeacherId == userId)
                .Select(c => c.Id)
                .FirstOrDefaultAsync();

            bool isHomeroom = homeroomClassId > 0;

            IQueryable<Form> query;

            if (isHomeroom)
            {
                // GVCN: thấy đơn KHÔNG gán cho ai (mặc định gửi GVCN) của HS lớp mình
                //      + đơn gán trực tiếp cho mình
                var homeroomStudentIds = await _context.StudentProfiles
                    .Where(sp => sp.ClassId == homeroomClassId)
                    .Select(sp => sp.UserId)
                    .ToListAsync();

                query = _context.Forms
                    .Include(f => f.Student)
                    .Where(f =>
                        (f.AssignedTo == null && homeroomStudentIds.Contains(f.StudentId))
                        || f.AssignedTo == userId);
            }
            else
            {
                // GVBM: chỉ thấy đơn gán cho mình
                query = _context.Forms
                    .Include(f => f.Student)
                    .Where(f => f.AssignedTo == userId);
            }

            var forms = await query
                .OrderByDescending(f => f.CreatedAt)
                .Take(100)
                .Select(f => new 
                {
                    f.Id,
                    f.FormType,
                    f.Title,
                    f.Content,
                    f.AbsentDate,
                    f.AttachmentUrl,
                    f.Status,
                    f.RejectReason,
                    f.CreatedAt,
                    StudentName = f.Student.FullName
                })
                .ToListAsync();

            return Ok(forms);
        }

        [HttpPatch("teacher/review/{id}")]
        [Authorize(Roles = "teacher")]
        public async Task<IActionResult> ReviewForm(int id, [FromBody] ReviewFormRequestDto request)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (!int.TryParse(userIdStr, out int userId)) return Unauthorized();

            var form = await _context.Forms
                .Include(f => f.Student)
                .FirstOrDefaultAsync(f => f.Id == id);
            
            if (form == null) return NotFound(new { message = "Không tìm thấy đơn này" });

            // FIX SECURITY: Chặn việc duyệt đè lên đơn đã xử lý rồi
            if (form.Status != "pending")
            {
                return BadRequest(new { message = "Đơn này đã được xử lý từ trước, không thể duyệt lại." });
            }

            // Kiểm tra quyền: GVCN có thể duyệt đơn không gán cho ai của HS lớp mình
            //                 Bất kỳ GV nào cƩng duyệt đơn được gán cho mình
            bool canReview = false;

            if (form.AssignedTo == userId)
            {
                // Đơn gán trực tiếp cho GV này
                canReview = true;
            }
            else if (form.AssignedTo == null)
            {
                // Đơn không gán cho ai → chỉ GVCN của lớp HS đó được duyệt
                var studentClassId = await _context.StudentProfiles
                    .Where(s => s.UserId == form.StudentId)
                    .Select(s => s.ClassId)
                    .FirstOrDefaultAsync();

                canReview = await _context.Classes
                    .AnyAsync(c => c.Id == studentClassId && c.HomeroomTeacherId == userId);
            }

            if (!canReview) return Forbid();

            // Dùng Transaction để đảm bảo tính nhất quán (Cẩn thận theo yêu cầu User)
            using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                // Thống nhất status về lowercase (BE lưu 'pending', FE gửi 'Approved')
                var normalizedStatus = request.Status.ToLower();
                form.Status = normalizedStatus;
                form.RejectReason = request.RejectReason;
                form.ReviewedBy = userId; // FIX: Lưu vết người duyệt (Audit Trail)
                form.ReviewedAt = DateTime.Now; // FIX: Lưu thời điểm duyệt
                form.UpdatedAt = DateTime.Now;

                // Tạo thông báo cho học sinh
                string statusVietnamese = normalizedStatus == "approved" ? "Đã được Duyệt" : "Bị Từ chối";
                var notification = new Notification
                {
                    UserId = form.StudentId,
                    Title = "Cập nhật trạng thái Đơn từ",
                    Body = $"Đơn '{form.Title}' của bạn đã {statusVietnamese}.",
                    NotiType = "hoc_vu", // Valid CHECK constraint values: tin_nhan, he_thong, tai_chinh, su_kien, hoc_vu
                    RefId = form.Id,
                    RefType = "Form",
                    IsRead = false,
                    CreatedAt = DateTime.Now
                };

                _context.Notifications.Add(notification);
                await _context.SaveChangesAsync();
                await transaction.CommitAsync();

                return Ok(new { message = $"Đã {statusVietnamese} đơn thành công" });
            }
            catch (Exception)
            {
                await transaction.RollbackAsync();
                return StatusCode(500, new { message = "Lỗi hệ thống khi duyệt đơn" });
            }
        }

        // --- Helper Methods --- 
        // Bóc tách 8 Byte đầu tiên để kiểm tra File thay vì tin vào Extention
        private bool IsValidImageSignature(IFormFile file)
        {
            using (var stream = file.OpenReadStream())
            {
                if (stream.Length < 8) return false;
                
                var buffer = new byte[8];
                stream.Read(buffer, 0, 8);
                
                // Chuẩn JPEG bắt đầu bằng FF D8 FF
                bool isJpeg = buffer[0] == 0xFF && buffer[1] == 0xD8 && buffer[2] == 0xFF;
                
                // Chuẩn PNG bắt đầu bằng 89 50 4E 47 0D 0A 1A 0A
                bool isPng = buffer[0] == 0x89 && buffer[1] == 0x50 && buffer[2] == 0x4E && buffer[3] == 0x47 && 
                             buffer[4] == 0x0D && buffer[5] == 0x0A && buffer[6] == 0x1A && buffer[7] == 0x0A;
                             
                return isJpeg || isPng;
            }
        }
    }
}

