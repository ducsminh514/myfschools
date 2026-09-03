using System;
using System.Collections.Generic;

namespace myfschool_be.Models;

public partial class Conversation
{
    public int Id { get; set; }

    public int StudentId { get; set; }

    public int TeacherId { get; set; }

    public DateTime? LastMsgAt { get; set; }

    public DateTime CreatedAt { get; set; }

    public virtual ICollection<Message> Messages { get; set; } = new List<Message>();

    public virtual User Student { get; set; } = null!;

    public virtual User Teacher { get; set; } = null!;
}
