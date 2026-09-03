using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class Grade
{
    public int Id { get; set; }

    public int StudentId { get; set; }

    public int ClassSubjectId { get; set; }

    public double? ScoreOral { get; set; }

    public double? Score15m1 { get; set; }

    public double? Score15m2 { get; set; }

    public double? Score15m3 { get; set; }

    public double? Score1h1 { get; set; }

    public double? Score1h2 { get; set; }

    public double? Score1h3 { get; set; }

    public double? ScoreFinal { get; set; }

    public double? Avg15m { get; set; }

    public double? Avg1h { get; set; }

    public double? GpaSubject { get; set; }

    public string? GradeLabel { get; set; }

    public bool IsFinalized { get; set; }

    public int? UpdatedBy { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual ClassSubject ClassSubject { get; set; } = null!;

    public virtual User Student { get; set; } = null!;

    public virtual User? UpdatedByNavigation { get; set; }
}
