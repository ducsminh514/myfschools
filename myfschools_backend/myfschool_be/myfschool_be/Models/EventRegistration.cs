using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class EventRegistration
{
    public int Id { get; set; }

    public int EventId { get; set; }

    public int StudentId { get; set; }

    public DateTime RegisteredAt { get; set; }

    public virtual Event Event { get; set; } = null!;

    public virtual User Student { get; set; } = null!;
}
