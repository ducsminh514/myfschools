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
    public class EventsController : ControllerBase
    {
        private readonly FptschoolContext _context;

        public EventsController(FptschoolContext context)
        {
            _context = context;
        }

        // ─── Danh sách sự kiện ────────────────────────────────────────────────
        // GET /api/events?filter=upcoming|past|all
        [HttpGet]
        public async Task<IActionResult> GetEvents([FromQuery] string filter = "upcoming")
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var now = DateTime.Now;

            // Lấy danh sách event_id mà user đã đăng ký
            var registeredIds = (await _context.EventRegistrations
                .Where(r => r.StudentId == userId)
                .Select(r => r.EventId)
                .ToListAsync()).ToHashSet();

            var query = _context.Events.Where(e => e.IsActive);

            query = filter switch
            {
                "past"       => query.Where(e => e.EndAt < now),
                "registered" => query.Where(e => registeredIds.Contains(e.Id)),
                _            => query.Where(e => e.EndAt >= now) // upcoming (default)
            };

            var events = await query
                .OrderBy(e => e.StartAt)
                .Select(e => new
                {
                    e.Id,
                    e.Title,
                    e.EventType,
                    e.Location,
                    e.BannerUrl,
                    StartAt = e.StartAt.ToString("dd/MM/yyyy HH:mm"),
                    EndAt   = e.EndAt.ToString("dd/MM/yyyy HH:mm"),
                    e.MaxCapacity,
                    e.CurrentRegistrations,
                    SlotsLeft     = e.MaxCapacity.HasValue ? e.MaxCapacity - e.CurrentRegistrations : (int?)null,
                    IsRegistered  = registeredIds.Contains(e.Id),
                    IsFull        = e.MaxCapacity.HasValue && e.CurrentRegistrations >= e.MaxCapacity,
                    IsUpcoming    = e.StartAt > now,
                    IsOngoing     = e.StartAt <= now && e.EndAt >= now,
                    IsPast        = e.EndAt < now,
                })
                .ToListAsync();

            return Ok(events);
        }

        // ─── Chi tiết sự kiện ─────────────────────────────────────────────────
        // GET /api/events/{id}
        [HttpGet("{id}")]
        public async Task<IActionResult> GetEvent(int id)
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var now = DateTime.Now;

            var e = await _context.Events.FindAsync(id);
            if (e == null || !e.IsActive)
                return NotFound(new { message = "Không tìm thấy sự kiện" });

            var isRegistered = await _context.EventRegistrations
                .AnyAsync(r => r.EventId == id && r.StudentId == userId);

            return Ok(new
            {
                e.Id,
                e.Title,
                e.Description,
                e.EventType,
                e.Location,
                e.BannerUrl,
                StartAt       = e.StartAt.ToString("dd/MM/yyyy HH:mm"),
                EndAt         = e.EndAt.ToString("dd/MM/yyyy HH:mm"),
                StartAtRaw    = e.StartAt,  // Để FE tính countdown
                e.MaxCapacity,
                e.CurrentRegistrations,
                SlotsLeft     = e.MaxCapacity.HasValue ? e.MaxCapacity - e.CurrentRegistrations : (int?)null,
                IsRegistered  = isRegistered,
                IsFull        = e.MaxCapacity.HasValue && e.CurrentRegistrations >= e.MaxCapacity,
                IsUpcoming    = e.StartAt > now,
                IsOngoing     = e.StartAt <= now && e.EndAt >= now,
                IsPast        = e.EndAt < now,
            });
        }

        // ─── Đăng ký sự kiện (Optimistic Concurrency — không dùng lock) ───────
        // POST /api/events/{id}/register
        [HttpPost("{id}/register")]
        [Authorize(Roles = "student")]
        public async Task<IActionResult> Register(int id)
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var now = DateTime.Now;

            var ev = await _context.Events.FindAsync(id);
            if (ev == null || !ev.IsActive)
                return NotFound(new { message = "Không tìm thấy sự kiện" });

            if (ev.EndAt < now)
                return BadRequest(new { message = "Sự kiện đã kết thúc" });

            // Kiểm tra đã đăng ký chưa
            var alreadyRegistered = await _context.EventRegistrations
                .AnyAsync(r => r.EventId == id && r.StudentId == userId);
            if (alreadyRegistered)
                return Conflict(new { message = "Bạn đã đăng ký sự kiện này rồi" });

            // Optimistic Concurrency: tăng current_registrations chỉ khi còn chỗ
            // Tránh race condition khi nhiều HS đăng ký cùng lúc
            if (ev.MaxCapacity.HasValue)
            {
                var rowsUpdated = await _context.Database.ExecuteSqlInterpolatedAsync(
                    $@"UPDATE events
                       SET current_registrations = current_registrations + 1
                       WHERE id = {id}
                         AND current_registrations < max_capacity");

                if (rowsUpdated == 0)
                    return Conflict(new { message = "Rất tiếc, sự kiện đã hết chỗ!" });
            }

            _context.EventRegistrations.Add(new EventRegistration
            {
                EventId      = id,
                StudentId    = userId,
                RegisteredAt = now,
            });

            // Gửi thông báo xác nhận đăng ký cho học sinh
            _context.Notifications.Add(new Notification
            {
                UserId    = userId,
                Title     = "Đăng ký sự kiện thành công",
                Body      = $"Bạn đã đăng ký sự kiện '{ev.Title}'. Hãy nhớ thời gian: {ev.StartAt:dd/MM/yyyy HH:mm}.",
                NotiType  = "su_kien",
                RefId     = id,
                RefType   = "Event",
                IsRead    = false,
                CreatedAt = now,
            });

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đăng ký thành công!" });
        }

        // ─── Huỷ đăng ký ──────────────────────────────────────────────────────
        // DELETE /api/events/{id}/unregister
        [HttpDelete("{id}/unregister")]
        [Authorize(Roles = "student")]
        public async Task<IActionResult> Unregister(int id)
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var now = DateTime.Now;

            var ev = await _context.Events.FindAsync(id);
            if (ev == null)
                return NotFound(new { message = "Không tìm thấy sự kiện" });

            if (ev.StartAt <= now)
                return BadRequest(new { message = "Không thể huỷ khi sự kiện đã bắt đầu" });

            var reg = await _context.EventRegistrations
                .FirstOrDefaultAsync(r => r.EventId == id && r.StudentId == userId);

            if (reg == null)
                return NotFound(new { message = "Bạn chưa đăng ký sự kiện này" });

            _context.EventRegistrations.Remove(reg);

            // Giảm lại current_registrations nếu có max_capacity
            if (ev.MaxCapacity.HasValue)
                await _context.Database.ExecuteSqlInterpolatedAsync(
                    $"UPDATE events SET current_registrations = current_registrations - 1 WHERE id = {id} AND current_registrations > 0");

            // Thông báo xác nhận huỷ
            _context.Notifications.Add(new Notification
            {
                UserId    = userId,
                Title     = "Đã huỷ đăng ký sự kiện",
                Body      = $"Bạn đã huỷ đăng ký sự kiện '{ev.Title}'.",
                NotiType  = "su_kien",
                RefId     = id,
                RefType   = "Event",
                IsRead    = false,
                CreatedAt = now,
            });

            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã huỷ đăng ký" });
        }

        // ─── Sự kiện đã đăng ký ───────────────────────────────────────────────
        // GET /api/events/my-registrations
        [HttpGet("my-registrations")]
        [Authorize(Roles = "student")]
        public async Task<IActionResult> GetMyRegistrations()
        {
            var userId = int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var now = DateTime.Now;

            var regs = await _context.EventRegistrations
                .Include(r => r.Event)
                .Where(r => r.StudentId == userId && r.Event.IsActive)
                .OrderBy(r => r.Event.StartAt)
                .Select(r => new
                {
                    r.Event.Id,
                    r.Event.Title,
                    r.Event.EventType,
                    r.Event.Location,
                    r.Event.BannerUrl,
                    StartAt      = r.Event.StartAt.ToString("dd/MM/yyyy HH:mm"),
                    EndAt        = r.Event.EndAt.ToString("dd/MM/yyyy HH:mm"),
                    RegisteredAt = r.RegisteredAt.ToString("dd/MM/yyyy"),
                    IsPast       = r.Event.EndAt < now,
                })
                .ToListAsync();

            return Ok(regs);
        }
    }
}
