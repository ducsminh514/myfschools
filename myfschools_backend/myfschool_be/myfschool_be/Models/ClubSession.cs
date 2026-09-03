using System;

namespace myfschool_be.Models;

public partial class ClubSession
{
    public int Id { get; set; }

    public int ClubId { get; set; }

    public string Title { get; set; } = null!;

    public string? Location { get; set; }

    public DateTime SessionAt { get; set; }

    public int CreatedBy { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual Club Club { get; set; } = null!;

    public virtual User CreatedByNavigation { get; set; } = null!;
}
