using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class TeacherChatSetting
{
    public int TeacherId { get; set; }

    public bool AllowMessagesFromStudents { get; set; }

    public TimeOnly? AllowedHoursStart { get; set; }

    public TimeOnly? AllowedHoursEnd { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual User Teacher { get; set; } = null!;
}
