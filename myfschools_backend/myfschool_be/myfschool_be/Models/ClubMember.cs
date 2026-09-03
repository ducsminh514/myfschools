using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class ClubMember
{
    public int Id { get; set; }

    public int ClubId { get; set; }

    public int StudentId { get; set; }

    public string Role { get; set; } = null!;

    public string Status { get; set; } = null!;

    public DateTime JoinedAt { get; set; }

    public virtual Club Club { get; set; } = null!;

    public virtual User Student { get; set; } = null!;
}
