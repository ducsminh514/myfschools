using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class PeriodTime
{
    public int PeriodNo { get; set; }

    public string Session { get; set; } = null!;

    public TimeOnly StartTime { get; set; }

    public TimeOnly EndTime { get; set; }

    public virtual ICollection<Schedule> Schedules { get; set; } = new List<Schedule>();
}
