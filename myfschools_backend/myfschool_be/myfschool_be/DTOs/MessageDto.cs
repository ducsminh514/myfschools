using System;
using System.Collections.Generic;

namespace myfschool_be.DTOs
{
    public class ConversationDto
    {
        public int Id { get; set; }
        public string TargetName { get; set; } = string.Empty;
        public string TargetRole { get; set; } = string.Empty; // Giáo viên Toán, Hành chính...
        public string TargetAvatarUrl { get; set; } = string.Empty;
        public string LastMessage { get; set; } = string.Empty;
        public string Time { get; set; } = string.Empty; // Chuẩn hoá chuỗi thời gian hiển thị (vd: 8:42, Hôm qua)
        public int UnreadCount { get; set; }
        public bool IsOnline { get; set; } // Giả lập trạng thái Online
        public string Type { get; set; } = string.Empty; // "teacher", "admin", "system"
    }

    public class MessageDto
    {
        public int Id { get; set; }
        public int ConversationId { get; set; }
        public int SenderId { get; set; } // Để Frontend phân biệt tin của mình (isMe)
        public bool IsMe { get; set; }    // Backend tự phân định 
        public string Content { get; set; } = string.Empty;
        public string Time { get; set; } = string.Empty; // "14:30"
        public string Date { get; set; } = string.Empty; // "Hôm nay", "24 Tháng 2"
        public bool IsRead { get; set; }
    }

    public class ConversationDetailResponse
    {
        public int ConversationId { get; set; }
        public string TargetName { get; set; } = string.Empty;
        public string TargetRole { get; set; } = string.Empty;
        public List<MessageDto> Messages { get; set; } = new();
    }
}
