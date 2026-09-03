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
    public class MessagesController : ControllerBase
    {
        private readonly FptschoolContext _context;

        public MessagesController(FptschoolContext context)
        {
            _context = context;
        }

        [HttpGet("conversations")]
        public async Task<ActionResult<List<ConversationDto>>> GetConversations()
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr)) return Unauthorized();

            var userId = int.Parse(userIdStr);

            // Lấy tất cả hội thoại mà người dùng tham gia (dù là HS hay GV)
            var conversations = await _context.Conversations
                .Include(c => c.Teacher)
                .Include(c => c.Student)
                .Include(c => c.Messages)
                .Where(c => c.StudentId == userId || c.TeacherId == userId)
                .OrderByDescending(c => c.LastMsgAt)
                .ToListAsync();

            var result = conversations.Select(c =>
            {
                var lastMsg = c.Messages.OrderByDescending(m => m.CreatedAt).FirstOrDefault();
                
                // Xác định đối phương (Target) là ai
                bool isUserStudent = c.StudentId == userId;
                var targetUser = isUserStudent ? c.Teacher : c.Student;
                var targetRoleName = isUserStudent ? "Giáo viên" : "Học sinh";

                return new ConversationDto
                {
                    Id = c.Id,
                    TargetName = targetUser.FullName,
                    TargetRole = targetRoleName,
                    TargetAvatarUrl = targetUser.AvatarUrl ?? "",
                    LastMessage = lastMsg?.Content ?? "Chưa có tin nhắn nào",
                    Time = lastMsg != null ? FormatTime(lastMsg.CreatedAt) : "",
                    UnreadCount = c.Messages.Count(m => m.SenderId != userId && !m.IsRead),
                    IsOnline = true,
                    Type = isUserStudent ? "teacher" : "student"
                };
            }).ToList();

            return Ok(result);
        }

        [HttpGet("{conversationId}")]
        public async Task<ActionResult<ConversationDetailResponse>> GetConversationDetail(int conversationId)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr)) return Unauthorized();

            var userId = int.Parse(userIdStr);

            // Kiểm tra quyền truy cập (Người dùng phải là 1 trong 2 bên tham gia chat)
            var conversation = await _context.Conversations
                .Include(c => c.Teacher)
                .Include(c => c.Student)
                .FirstOrDefaultAsync(c => c.Id == conversationId && (c.StudentId == userId || c.TeacherId == userId));

            if (conversation == null) return NotFound(new { message = "Không tìm thấy cuộc hội thoại hoặc bạn không có quyền truy cập" });

            var isUserStudent = conversation.StudentId == userId;
            var targetUser = isUserStudent ? conversation.Teacher : conversation.Student;
            var targetRoleName = isUserStudent ? "Giáo viên" : "Học sinh";

            // Lấy danh sách tin nhắn
            var messages = await _context.Messages
                .Where(m => m.ConversationId == conversationId)
                .OrderBy(m => m.CreatedAt) // Cũ xếp trước, mới xếp sau để cuộn xuống
                .ToListAsync();

            // Đánh dấu đã đọc các tin nhắn của người kia gửi cho mình
            var unreadMsgs = messages.Where(m => m.SenderId != userId && !m.IsRead).ToList();
            if (unreadMsgs.Any())
            {
                foreach(var msg in unreadMsgs) {
                    msg.IsRead = true;
                    msg.ReadAt = DateTime.Now;
                }
                await _context.SaveChangesAsync();
            }

            var result = new ConversationDetailResponse
            {
                ConversationId = conversation.Id,
                TargetName = targetUser.FullName,
                TargetRole = targetRoleName,
                Messages = messages.Select(m => new MessageDto
                {
                    Id = m.Id,
                    ConversationId = m.ConversationId,
                    SenderId = m.SenderId,
                    IsMe = m.SenderId == userId,
                    Content = m.Content,
                    Time = m.CreatedAt.ToString("HH:mm"),
                    Date = m.CreatedAt.Date == DateTime.Today ? "Hôm nay" : m.CreatedAt.ToString("dd/MM"),
                    IsRead = m.IsRead
                }).ToList()
            };

            return Ok(result);
        }

        public class SendMessageRequest
        {
            public string Content { get; set; } = string.Empty;
        }

        [HttpPost("{conversationId}/send")]
        public async Task<ActionResult<MessageDto>> SendMessage(int conversationId, [FromBody] SendMessageRequest req)
        {
            var userIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdStr)) return Unauthorized();

            var userId = int.Parse(userIdStr);

            // Kiểm tra uỷ quyền
            var conversation = await _context.Conversations
                .FirstOrDefaultAsync(c => c.Id == conversationId && (c.StudentId == userId || c.TeacherId == userId));

            if (conversation == null) return NotFound(new { message = "Không tìm thấy cuộc hội thoại hoặc không có quyền gửi" });

            var newMsg = new Message
            {
                ConversationId = conversationId,
                SenderId = userId,
                Content = req.Content,
                IsRead = false,
                CreatedAt = DateTime.Now
            };

            // Triggers "trg_messages_update_conversation" sẽ tự update LastMsgAt
            _context.Messages.Add(newMsg);
            await _context.SaveChangesAsync();

            var dto = new MessageDto
            {
                Id = newMsg.Id,
                ConversationId = newMsg.ConversationId,
                SenderId = newMsg.SenderId,
                IsMe = true,
                Content = newMsg.Content,
                Time = newMsg.CreatedAt.ToString("HH:mm"),
                Date = "Hôm nay",
                IsRead = false
            };

            return Ok(dto);
        }

        // Hàm tiện ích format thời gian giống UI
        private string FormatTime(DateTime dt)
        {
            if (dt.Date == DateTime.Today) return dt.ToString("HH:mm");
            if (dt.Date == DateTime.Today.AddDays(-1)) return "Hôm qua";
            return dt.ToString("dd/MM");
        }

        public class StartConversationRequest
        {
            public int TargetUserId { get; set; }
        }

        /// Tạo hoặc tìm conversation (HS↔GV)
        /// HS gửi targetUserId = GV, GV gửi targetUserId = HS
        [HttpPost("start")]
        public async Task<IActionResult> StartConversation([FromBody] StartConversationRequest req)
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            bool isStudent = User.IsInRole("student");
            bool isTeacher = User.IsInRole("teacher");

            if (!isStudent && !isTeacher)
                return Forbid();

            var targetUser = await _context.Users
                .Include(u => u.Roles)
                .FirstOrDefaultAsync(u => u.Id == req.TargetUserId);
            if (targetUser == null)
                return BadRequest(new { message = "Người nhận không tồn tại" });

            int studentId, teacherId;

            if (isStudent)
            {
                // HS nhắn GV: target phải là teacher
                if (!targetUser.Roles.Any(r => r.Name == "teacher"))
                    return BadRequest(new { message = "Người nhận không phải giáo viên" });
                studentId = userId;
                teacherId = req.TargetUserId;
            }
            else
            {
                // GV nhắn HS: target phải là student
                if (!targetUser.Roles.Any(r => r.Name == "student"))
                    return BadRequest(new { message = "Người nhận không phải học sinh" });
                studentId = req.TargetUserId;
                teacherId = userId;
            }

            // Tìm conversation đã có
            var existing = await _context.Conversations
                .FirstOrDefaultAsync(c => c.StudentId == studentId && c.TeacherId == teacherId);

            if (existing != null)
                return Ok(new { conversationId = existing.Id });

            // Tạo mới
            var conv = new Conversation
            {
                StudentId = studentId,
                TeacherId = teacherId,
                CreatedAt = DateTime.Now
            };
            _context.Conversations.Add(conv);
            await _context.SaveChangesAsync();

            return Ok(new { conversationId = conv.Id });
        }

        /// HS: lấy danh sách GV các môn + GVCN để chọn nhắn tin
        [HttpGet("my-teachers")]
        [Authorize(Roles = "student")]
        public async Task<IActionResult> GetMyTeachers()
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            // Lấy lớp của HS
            var studentProfile = await _context.StudentProfiles
                .FirstOrDefaultAsync(sp => sp.UserId == userId);

            if (studentProfile == null)
                return NotFound(new { message = "Không tìm thấy hồ sơ học sinh" });

            var classId = studentProfile.ClassId;
            var result = new List<object>();

            // 1. GVCN
            var homeroomTeacher = await _context.Classes
                .Include(c => c.HomeroomTeacher)
                .Where(c => c.Id == classId && c.HomeroomTeacherId != null)
                .Select(c => new {
                    TeacherId = c.HomeroomTeacher!.Id,
                    Name = c.HomeroomTeacher.FullName,
                    Type = "GVCN",
                    SubjectName = (string?)null,
                    AvatarUrl = c.HomeroomTeacher.AvatarUrl
                })
                .FirstOrDefaultAsync();

            if (homeroomTeacher != null)
                result.Add(homeroomTeacher);

            // 2. Tất cả GVBM (loại trừ GVCN để không hiện 2 lần)
            var subjectTeachers = await _context.ClassSubjects
                .Include(cs => cs.Teacher)
                .Include(cs => cs.Subject)
                .Where(cs => cs.ClassId == classId && cs.TeacherId != (homeroomTeacher != null ? homeroomTeacher.TeacherId : -1))
                .Select(cs => new {
                    TeacherId = cs.Teacher.Id,
                    Name = cs.Teacher.FullName,
                    Type = "GVBM",
                    SubjectName = (string?)cs.Subject.Name,
                    AvatarUrl = cs.Teacher.AvatarUrl
                })
                .Distinct()
                .ToListAsync();

            result.AddRange(subjectTeachers);

            return Ok(result);
        }

        /// GV: lấy danh sách HS trong các lớp mình dạy/chủ nhiệm
        [HttpGet("my-students")]
        [Authorize(Roles = "teacher")]
        public async Task<IActionResult> GetMyStudents()
        {
            var teacherId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

            // Lấy tất cả classId mà GV dạy
            var teachingClassIds = await _context.ClassSubjects
                .Where(cs => cs.TeacherId == teacherId)
                .Select(cs => cs.ClassId)
                .Distinct()
                .ToListAsync();

            // Thêm lớp chủ nhiệm (nếu có)
            var homeroomClassId = await _context.Classes
                .Where(c => c.HomeroomTeacherId == teacherId)
                .Select(c => c.Id)
                .FirstOrDefaultAsync();

            if (homeroomClassId > 0 && !teachingClassIds.Contains(homeroomClassId))
                teachingClassIds.Add(homeroomClassId);

            // Lấy DS HS trong các lớp đó
            var students = await _context.StudentProfiles
                .Include(sp => sp.User)
                .Include(sp => sp.Class)
                .Where(sp => teachingClassIds.Contains(sp.ClassId))
                .Select(sp => new
                {
                    StudentId = sp.UserId,
                    Name = sp.User.FullName,
                    ClassName = sp.Class.Name,
                    StudentCode = sp.User.StudentCode,
                    AvatarUrl = sp.User.AvatarUrl
                })
                .OrderBy(s => s.ClassName)
                .ThenBy(s => s.Name)
                .ToListAsync();

            return Ok(students);
        }
    }
}
