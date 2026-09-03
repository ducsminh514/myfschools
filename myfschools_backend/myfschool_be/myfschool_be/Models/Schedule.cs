using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class Schedule
{
    public int Id { get; set; }

    public int ClassSubjectId { get; set; }

    public int DayOfWeek { get; set; }

    public int PeriodNo { get; set; }

    public string Room { get; set; } = null!;

    public virtual ICollection<Attendance> Attendances { get; set; } = new List<Attendance>();

    public virtual ClassSubject ClassSubject { get; set; } = null!;

    public virtual PeriodTime PeriodNoNavigation { get; set; } = null!;
}
