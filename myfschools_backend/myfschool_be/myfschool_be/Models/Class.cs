using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class Class
{
    public int Id { get; set; }

    public string Name { get; set; } = null!;

    public int Grade { get; set; }

    public string SchoolYear { get; set; } = null!;

    public int? HomeroomTeacherId { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual ICollection<ClassSubject> ClassSubjects { get; set; } = new List<ClassSubject>();

    public virtual User? HomeroomTeacher { get; set; }

    public virtual ICollection<SemesterResult> SemesterResults { get; set; } = new List<SemesterResult>();

    public virtual ICollection<StudentProfile> StudentProfiles { get; set; } = new List<StudentProfile>();
}
