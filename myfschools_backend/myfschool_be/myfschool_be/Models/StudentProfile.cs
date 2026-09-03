using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class StudentProfile
{
    public int Id { get; set; }

    public int UserId { get; set; }

    public int ClassId { get; set; }

    public DateOnly? BirthDate { get; set; }

    public string? Gender { get; set; }

    public string? Address { get; set; }

    public string? ParentName { get; set; }

    public string? ParentPhone { get; set; }

    public string? ParentEmail { get; set; }

    public DateOnly? EnrollmentDate { get; set; }

    public DateTime UpdatedAt { get; set; }

    public virtual Class Class { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
