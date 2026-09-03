using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class Event
{
    public int Id { get; set; }

    public string Title { get; set; } = null!;

    public string? Description { get; set; }

    public string? EventType { get; set; }

    public string? Location { get; set; }

    public string? BannerUrl { get; set; }

    public DateTime StartAt { get; set; }

    public DateTime EndAt { get; set; }

    public int? MaxCapacity { get; set; }

    public int CurrentRegistrations { get; set; }

    public int CreatedBy { get; set; }

    public bool IsActive { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual User CreatedByNavigation { get; set; } = null!;

    public virtual ICollection<EventRegistration> EventRegistrations { get; set; } = new List<EventRegistration>();
}
