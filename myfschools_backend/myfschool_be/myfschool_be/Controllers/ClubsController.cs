using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using myfschool_be.Models;
using System.Security.Claims;

namespace myfschool_be.Controllers
{
    [Authorize]
    [Route("api/[controller]")]
    [ApiController]
    public class ClubsController : ControllerBase
    {
        private readonly FptschoolContext _context;

        public ClubsController(FptschoolContext context)
        {
            _context = context;
        }

        // ─── Helper: lấy userId ──────────────────────────────────────────────
        private int UserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // ─── Xác định trạng thái đăng ký CLB ─────────────────────────────────
        // Trả về: 'none' | 'pending' | 'approved' | 'rejected'
        private static string GetMemberStatus(Club club, int userId)
        {
            var m = club.ClubMembers.FirstOrDefault(m => m.StudentId == userId);
            return m?.Status ?? "none";
        }

        // ─── Tính trạng thái đăng ký (UI state) ──────────────────────────────
        private static string GetRegStatus(Club club, DateTime now)
        {
            if (club.RegOpenAt == null) return "not_open";
            if (now < club.RegOpenAt) return "not_open";
            if (club.RegCloseAt != null && now > club.RegCloseAt) return "closed";
            var memberCount = club.ClubMembers.Count(m => m.Status == "approved");
            if (club.MaxMembers.HasValue && memberCount >= club.MaxMembers) return "full";
            return "open";
        }

        // ─── GET /api/clubs ───────────────────────────────────────────────────
        // Filter: ?type=hoc_thuat|the_thao|nghe_thuat|tinh_nguyen|khac
        [HttpGet]
        public async Task<IActionResult> GetClubs([FromQuery] string? type = null)
        {
            var userId = UserId;
            var now = DateTime.Now;

            var query = _context.Clubs
                .Include(c => c.Advisor)
                .Include(c => c.ClubMembers)
                .Where(c => c.IsActive);

            if (!string.IsNullOrEmpty(type))
                query = query.Where(c => c.ClubType == type);

            var clubs = await query.OrderBy(c => c.Name).ToListAsync();

            return Ok(clubs.Select(c => MapClubList(c, userId, now)));
        }

        // ─── GET /api/clubs/my-clubs ──────────────────────────────────────────
        [HttpGet("my-clubs")]
        [Authorize(Roles = "student")]
        public async Task<IActionResult> GetMyClubs()
        {
            var userId = UserId;
            var now = DateTime.Now;

            var clubs = await _context.Clubs
                .Include(c => c.Advisor)
                .Include(c => c.ClubMembers)
                .Include(c => c.ClubSessions.OrderBy(s => s.SessionAt))
                .Where(c => c.IsActive && c.ClubMembers.Any(m => m.StudentId == userId
                    && (m.Status == "pending" || m.Status == "approved")))
                .OrderBy(c => c.Name)
                .ToListAsync();

            return Ok(clubs.Select(c =>
            {
                var dto = MapClubList(c, userId, now);
                // Lịch sinh hoạt gần nhất
                var nextSession = c.ClubSessions
                    .Where(s => s.SessionAt >= now)
                    .OrderBy(s => s.SessionAt)
                    .FirstOrDefault();
                return new
                {
                    dto.Id, dto.Name, dto.ClubType, dto.TypeLabel, dto.LogoUrl,
                    dto.AdvisorName, dto.MemberCount, dto.MaxMembers,
                    dto.MemberStatus, dto.MyRole, dto.IsLeader, dto.RegStatus,
                    NextSession = nextSession == null ? null : new
                    {
                        nextSession.Title,
                        nextSession.Location,
                        SessionAt = nextSession.SessionAt.ToString("ddd dd/MM HH:mm"),
                    }
                };
            }));
        }

        // ─── GET /api/clubs/{id} ──────────────────────────────────────────────
        [HttpGet("{id}")]
        public async Task<IActionResult> GetClub(int id)
        {
            var userId = UserId;
            var now = DateTime.Now;

            var club = await _context.Clubs
                .Include(c => c.Advisor)
                .Include(c => c.ClubMembers).ThenInclude(m => m.Student)
                .Include(c => c.ClubSessions.OrderBy(s => s.SessionAt))
                .FirstOrDefaultAsync(c => c.Id == id && c.IsActive);

            if (club == null)
                return NotFound(new { message = "Không tìm thấy CLB" });

            var members = club.ClubMembers
                .Where(m => m.Status == "approved")
                .OrderByDescending(m => m.Role == "leader")
                .Select(m => new
                {
                    m.Id,
                    m.StudentId,
                    Name = m.Student.FullName,
                    m.Role,
                    JoinedAt = m.JoinedAt.ToString("dd/MM/yyyy"),
                })
                .ToList();

            var sessions = club.ClubSessions
                .Where(s => s.SessionAt >= now.AddDays(-1))
                .Select(s => new
                {
                    s.Id,
                    s.Title,
                    s.Location,
                    SessionAt = s.SessionAt.ToString("dddd, dd/MM/yyyy HH:mm"),
                })
                .ToList();

            var dto = MapClubList(club, userId, now);
            return Ok(new
            {
                dto.Id, dto.Name, dto.ClubType, dto.TypeLabel, dto.Description,
                dto.LogoUrl, dto.AdvisorId, dto.AdvisorName,
                dto.MemberCount, dto.MaxMembers,
                dto.MemberStatus, dto.MyRole, dto.IsLeader,
                dto.RegStatus, dto.RegOpenAt, dto.RegCloseAt,
                Members  = members,
                Sessions = sessions,
            });
        }

        // ─── POST /api/clubs/{id}/join ────────────────────────────────────────
        [HttpPost("{id}/join")]
        [Authorize(Roles = "student")]
        public async Task<IActionResult> Join(int id)
        {
            var userId = UserId;
            var now = DateTime.Now;

            var club = await _context.Clubs
                .Include(c => c.ClubMembers)
                .FirstOrDefaultAsync(c => c.Id == id && c.IsActive);

            if (club == null)
                return NotFound(new { message = "Không tìm thấy CLB" });

            // Kiểm tra đã là thành viên / chờ duyệt
            var existing = club.ClubMembers.FirstOrDefault(m => m.StudentId == userId);
            if (existing != null)
                return Conflict(new
                {
                    message = existing.Status == "approved"
                        ? "Bạn đã là thành viên của CLB này"
                        : "Đơn của bạn đang chờ duyệt"
                });

            // Kiểm tra thời gian đăng ký
            var regStatus = GetRegStatus(club, now);
            if (regStatus != "open")
            {
                var msg = regStatus switch
                {
                    "not_open" => "CLB chưa mở đăng ký",
                    "closed"   => "Đã hết thời gian đăng ký",
                    "full"     => "CLB đã đủ thành viên",
                    _          => "Không thể đăng ký lúc này"
                };
                return BadRequest(new { message = msg });
            }

            _context.ClubMembers.Add(new ClubMember
            {
                ClubId    = id,
                StudentId = userId,
                Role      = "member",
                Status    = "pending",
                JoinedAt  = now,
            });

            // Thông báo cho Trưởng CLB (leader) biết có đơn mới
            var leaderMember = club.ClubMembers
                .FirstOrDefault(m => m.Role == "leader" && m.Status == "approved");
            if (leaderMember != null)
            {
                _context.Notifications.Add(new Notification
                {
                    UserId    = leaderMember.StudentId,
                    Title     = "Đơn xin vào CLB mới",
                    Body      = $"Có học sinh mới đã gửi đơn xin gia nhập CLB '{club.Name}'. Hãy vào quản lý CLB để duyệt.",
                    NotiType  = "hoc_vu",
                    RefId     = id,
                    RefType   = "Club",
                    IsRead    = false,
                    CreatedAt = now,
                });
            }
            // Nếu không có leader, gửi cho GV cố vấn
            else if (club.AdvisorId.HasValue)
            {
                _context.Notifications.Add(new Notification
                {
                    UserId    = club.AdvisorId.Value,
                    Title     = "Đơn xin vào CLB mới",
                    Body      = $"Có học sinh đã gửi đơn xin gia nhập CLB '{club.Name}' (chưa có Trưởng CLB).",
                    NotiType  = "hoc_vu",
                    RefId     = id,
                    RefType   = "Club",
                    IsRead    = false,
                    CreatedAt = now,
                });
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đơn đăng ký đã gửi, chờ trưởng CLB duyệt!" });
        }

        // ─── DELETE /api/clubs/{id}/leave ─────────────────────────────────────
        [HttpDelete("{id}/leave")]
        [Authorize(Roles = "student")]
        public async Task<IActionResult> Leave(int id)
        {
            var userId = UserId;

            var membership = await _context.ClubMembers
                .FirstOrDefaultAsync(m => m.ClubId == id && m.StudentId == userId);

            if (membership == null)
                return NotFound(new { message = "Bạn không phải thành viên CLB này" });

            if (membership.Role == "leader")
                return BadRequest(new { message = "Trưởng CLB không thể tự rời CLB. Liên hệ GV cố vấn." });

            _context.ClubMembers.Remove(membership);
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đã rời CLB" });
        }

        // ══════════════════════════════════════════════════════════════════════
        // LEADER ENDPOINTS
        // ══════════════════════════════════════════════════════════════════════

        // ─── GET /api/clubs/{id}/pending-members ──────────────────────────────
        [HttpGet("{id}/pending-members")]
        public async Task<IActionResult> GetPendingMembers(int id)
        {
            var userId = UserId;
            if (!await IsLeaderOrAdvisor(id, userId))
                return Forbid();

            var pending = await _context.ClubMembers
                .Include(m => m.Student)
                .Where(m => m.ClubId == id && m.Status == "pending")
                .OrderBy(m => m.JoinedAt)
                .Select(m => new
                {
                    m.Id,
                    m.StudentId,
                    Name     = m.Student.FullName,
                    ClassName = (string?)null, // TODO: join StudentProfile khi cần
                    JoinedAt = m.JoinedAt.ToString("dd/MM/yyyy"),
                })
                .ToListAsync();

            return Ok(pending);
        }

        // ─── PATCH /api/clubs/{id}/members/{memberId} ─────────────────────────
        // Body: { "status": "approved" | "rejected" }
        [HttpPatch("{id}/members/{memberId}")]
        public async Task<IActionResult> UpdateMemberStatus(int id, int memberId, [FromBody] UpdateMemberDto dto)
        {
            var userId = UserId;
            if (!await IsLeaderOrAdvisor(id, userId))
                return Forbid();

            if (dto.Status != "approved" && dto.Status != "rejected")
                return BadRequest(new { message = "Trạng thái không hợp lệ" });

            var m = await _context.ClubMembers.FindAsync(memberId);
            if (m == null || m.ClubId != id)
                return NotFound();

            m.Status = dto.Status;
            await _context.SaveChangesAsync();

            // Thông báo kết quả cho học sinh
            var clubInfo = await _context.Clubs.FindAsync(id);
            var bodyMsg = dto.Status == "approved"
                ? $"Đơn xin vào CLB '{clubInfo?.Name ?? string.Empty}' của bạn đã được DUYỆT. Chúc mừng bạn!"
                : $"Đơn xin vào CLB '{clubInfo?.Name ?? string.Empty}' của bạn đã bị TỪ CHỐI.";

            _context.Notifications.Add(new Notification
            {
                UserId    = m.StudentId,
                Title     = dto.Status == "approved" ? "Đơn CLB được duyệt" : "Đơn CLB bị từ chối",
                Body      = bodyMsg,
                NotiType  = "hoc_vu",
                RefId     = id,
                RefType   = "Club",
                IsRead    = false,
                CreatedAt = DateTime.Now,
            });
            await _context.SaveChangesAsync();

            var msg = dto.Status == "approved" ? "Đã duyệt thành viên" : "Đã từ chối";
            return Ok(new { message = msg });
        }

        // ─── DELETE /api/clubs/{id}/members/{memberId} ────────────────────────
        [HttpDelete("{id}/members/{memberId}")]
        public async Task<IActionResult> RemoveMember(int id, int memberId)
        {
            var userId = UserId;
            if (!await IsLeaderOrAdvisor(id, userId))
                return Forbid();

            var m = await _context.ClubMembers.FindAsync(memberId);
            if (m == null || m.ClubId != id)
                return NotFound();

            if (m.Role == "leader")
                return BadRequest(new { message = "Không thể xoá Trưởng CLB" });

            _context.ClubMembers.Remove(m);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã xoá thành viên" });
        }

        // ─── POST /api/clubs/{id}/sessions ────────────────────────────────────
        [HttpPost("{id}/sessions")]
        public async Task<IActionResult> AddSession(int id, [FromBody] AddSessionDto dto)
        {
            var userId = UserId;
            if (!await IsLeaderOrAdvisor(id, userId))
                return Forbid();

            // Validate bắt buộc
            if (string.IsNullOrWhiteSpace(dto.Title))
                return BadRequest(new { message = "Tiêu đề lịch sinh hoạt không được để trống" });
            if (dto.SessionAt < DateTime.Now)
                return BadRequest(new { message = "Thời gian sinh hoạt phải ở tương lai" });

            _context.ClubSessions.Add(new ClubSession
            {
                ClubId    = id,
                Title     = dto.Title.Trim(),
                Location  = dto.Location?.Trim(),
                SessionAt = dto.SessionAt,
                CreatedBy = userId,
                CreatedAt = DateTime.Now,
            });

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã thêm lịch sinh hoạt" });
        }

        // ─── DELETE /api/clubs/{id}/sessions/{sessionId} ──────────────────────
        [HttpDelete("{id}/sessions/{sessionId}")]
        public async Task<IActionResult> DeleteSession(int id, int sessionId)
        {
            var userId = UserId;
            if (!await IsLeaderOrAdvisor(id, userId))
                return Forbid();

            var s = await _context.ClubSessions.FindAsync(sessionId);
            if (s == null || s.ClubId != id) return NotFound();

            _context.ClubSessions.Remove(s);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã xoá lịch sinh hoạt" });
        }

        // ──────────────────────────────────────────────────────────────────────
        // Private helpers
        // ──────────────────────────────────────────────────────────────────────

        private async Task<bool> IsLeaderOrAdvisor(int clubId, int userId)
        {
            var club = await _context.Clubs
                .Include(c => c.ClubMembers)
                .FirstOrDefaultAsync(c => c.Id == clubId);
            if (club == null) return false;
            if (club.AdvisorId == userId) return true;
            return club.ClubMembers.Any(m => m.StudentId == userId && m.Role == "leader" && m.Status == "approved");
        }

        private static dynamic MapClubList(Club c, int userId, DateTime now)
        {
            var memberStatus = GetMemberStatus(c, userId);
            var regStatus    = GetRegStatus(c, now);
            var memberCount  = c.ClubMembers.Count(m => m.Status == "approved");
            var myMembership = c.ClubMembers.FirstOrDefault(m => m.StudentId == userId);
            // Fix: tránh NullRef khi myMembership == null
            var isLeader = myMembership != null
                && myMembership.Role == "leader"
                && myMembership.Status == "approved";

            return new
            {
                c.Id,
                c.Name,
                c.ClubType,
                TypeLabel   = GetTypeLabel(c.ClubType),
                c.Description,
                c.LogoUrl,
                c.AdvisorId,
                AdvisorName = c.Advisor?.FullName,
                MemberCount = memberCount,
                c.MaxMembers,
                MemberStatus = memberStatus,
                MyRole       = myMembership?.Role,
                IsLeader     = isLeader,
                RegStatus    = regStatus,
                RegOpenAt    = c.RegOpenAt?.ToString("dd/MM/yyyy"),
                RegCloseAt   = c.RegCloseAt?.ToString("dd/MM/yyyy"),
            };
        }

        private static string GetTypeLabel(string? type) => type switch
        {
            "hoc_thuat"   => "Học thuật",
            "the_thao"    => "Thể thao",
            "nghe_thuat"  => "Nghệ thuật",
            "tinh_nguyen" => "Tình nguyện",
            _             => "Khác",
        };
    }

    // ─── DTOs ─────────────────────────────────────────────────────────────────
    public class UpdateMemberDto
    {
        public string Status { get; set; } = "";
    }

    public class AddSessionDto
    {
        public string Title    { get; set; } = "";
        public string? Location { get; set; }
        public DateTime SessionAt { get; set; }
    }
}
