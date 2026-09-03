using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class Form
{
    public int Id { get; set; }

    public int StudentId { get; set; }

    public string FormType { get; set; } = null!;

    public string Title { get; set; } = null!;

    public string Content { get; set; } = null!;

    public DateOnly? AbsentDate { get; set; }

    public string? AttachmentUrl { get; set; }

    public string Status { get; set; } = null!;

    public int? ReviewedBy { get; set; }

    public DateTime? ReviewedAt { get; set; }

    public string? RejectReason { get; set; }

    /// Đơn gửi cho ai? NULL = GVCN lớp (mặc định), có giá trị = GVBM cụ thể
    public int? AssignedTo { get; set; }

    public DateTime CreatedAt { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual User? AssignedToNavigation { get; set; }

    public virtual User? ReviewedByNavigation { get; set; }

    public virtual User Student { get; set; } = null!;
}
