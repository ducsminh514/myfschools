using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class SemesterResult
{
    public int Id { get; set; }

    public int StudentId { get; set; }

    public int ClassId { get; set; }

    public int Semester { get; set; }

    public string SchoolYear { get; set; } = null!;

    public double? Gpa { get; set; }

    public string? AcademicRank { get; set; }

    public string? ConductRank { get; set; }

    public double? AttendancePct { get; set; }

    public bool IsFinalized { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual Class Class { get; set; } = null!;

    public virtual User Student { get; set; } = null!;
}
