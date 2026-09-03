using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class Attendance
{
    public int Id { get; set; }

    public int ScheduleId { get; set; }

    public int StudentId { get; set; }

    public DateOnly AttendDate { get; set; }

    public string Status { get; set; } = null!;

    public string? Note { get; set; }

    public int? RecordedBy { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual User? RecordedByNavigation { get; set; }

    public virtual Schedule Schedule { get; set; } = null!;

    public virtual User Student { get; set; } = null!;
}
