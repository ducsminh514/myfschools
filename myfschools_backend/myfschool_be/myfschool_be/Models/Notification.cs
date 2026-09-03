using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class Notification
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public string Title { get; set; } = null!;

    public string Body { get; set; } = null!;

    public string NotiType { get; set; } = null!;

    public int? RefId { get; set; }

    public string? RefType { get; set; }

    public bool IsRead { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual User User { get; set; } = null!;
}
