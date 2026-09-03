using System;

namespace myfschool_be.DTOs
{
    public class NotificationResponseDto
    {
        public int Id { get; set; }
        public string Title { get; set; } = null!;
        public string Body { get; set; } = null!;
        public string NotiType { get; set; } = null!;
        public int? RefId { get; set; }
        public string? RefType { get; set; }
        public bool IsRead { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
