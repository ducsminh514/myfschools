using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace myfschool_be.Models;

public partial class FptschoolContext : DbContext
{
    public FptschoolContext()
    {
    }

    public FptschoolContext(DbContextOptions<FptschoolContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Attendance> Attendances { get; set; }

    public virtual DbSet<Class> Classes { get; set; }

    public virtual DbSet<ClassSubject> ClassSubjects { get; set; }

    public virtual DbSet<Club> Clubs { get; set; }

    public virtual DbSet<ClubMember> ClubMembers { get; set; }

    public virtual DbSet<ClubSession> ClubSessions { get; set; }

    public virtual DbSet<Conversation> Conversations { get; set; }

    public virtual DbSet<Event> Events { get; set; }

    public virtual DbSet<EventRegistration> EventRegistrations { get; set; }

    public virtual DbSet<Form> Forms { get; set; }

    public virtual DbSet<Grade> Grades { get; set; }

    public virtual DbSet<Message> Messages { get; set; }

    public virtual DbSet<Notification> Notifications { get; set; }

    public virtual DbSet<OtpCode> OtpCodes { get; set; }

    public virtual DbSet<PeriodTime> PeriodTimes { get; set; }

    public virtual DbSet<RefreshToken> RefreshTokens { get; set; }

    public virtual DbSet<Schedule> Schedules { get; set; }

    public virtual DbSet<SemesterResult> SemesterResults { get; set; }

    public virtual DbSet<StudentProfile> StudentProfiles { get; set; }

    public virtual DbSet<Subject> Subjects { get; set; }

    public virtual DbSet<TeacherChatSetting> TeacherChatSettings { get; set; }

    public virtual DbSet<Role> Roles { get; set; }

    public virtual DbSet<User> Users { get; set; }

    
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.UseCollation("Vietnamese_CI_AS");

        // ClubSession mapping
        modelBuilder.Entity<ClubSession>(entity =>
        {
            entity.ToTable("club_sessions");
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ClubId).HasColumnName("club_id");
            entity.Property(e => e.Title).HasMaxLength(200).HasColumnName("title");
            entity.Property(e => e.Location).HasMaxLength(200).HasColumnName("location");
            entity.Property(e => e.SessionAt).HasColumnType("datetime").HasColumnName("session_at");
            entity.Property(e => e.CreatedBy).HasColumnName("created_by");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(getdate())").HasColumnType("datetime").HasColumnName("created_at");
            entity.HasOne(d => d.Club).WithMany(p => p.ClubSessions)
                .HasForeignKey(d => d.ClubId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(d => d.CreatedByNavigation).WithMany()
                .HasForeignKey(d => d.CreatedBy).OnDelete(DeleteBehavior.ClientSetNull);
        });

        // Club: thêm reg_open_at, reg_close_at
        modelBuilder.Entity<Club>(entity =>
        {
            entity.Property(e => e.RegOpenAt).HasColumnType("datetime").HasColumnName("reg_open_at");
            entity.Property(e => e.RegCloseAt).HasColumnType("datetime").HasColumnName("reg_close_at");
        });

        modelBuilder.Entity<Attendance>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__attendan__3213E83F38C496D8");

            entity.ToTable("attendances");

            entity.HasIndex(e => new { e.ScheduleId, e.StudentId, e.AttendDate }, "UQ__attendan__254C7D59DF41853F").IsUnique();

            entity.HasIndex(e => new { e.StudentId, e.AttendDate }, "idx_attendances_student");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AttendDate).HasColumnName("attend_date");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.Note)
                .HasMaxLength(200)
                .HasColumnName("note");
            entity.Property(e => e.RecordedBy).HasColumnName("recorded_by");
            entity.Property(e => e.ScheduleId).HasColumnName("schedule_id");
            entity.Property(e => e.Status)
                .HasMaxLength(10)
                .IsUnicode(false)
                .HasColumnName("status");
            entity.Property(e => e.StudentId).HasColumnName("student_id");

            entity.HasOne(d => d.RecordedByNavigation).WithMany(p => p.AttendanceRecordedByNavigations)
                .HasForeignKey(d => d.RecordedBy)
                .HasConstraintName("FK__attendanc__recor__6C190EBB");

            entity.HasOne(d => d.Schedule).WithMany(p => p.Attendances)
                .HasForeignKey(d => d.ScheduleId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__attendanc__sched__693CA210");

            entity.HasOne(d => d.Student).WithMany(p => p.AttendanceStudents)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__attendanc__stude__6A30C649");
        });

        modelBuilder.Entity<Class>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__classes__3213E83FCC10A3AC");

            entity.ToTable("classes");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.Grade).HasColumnName("grade");
            entity.Property(e => e.HomeroomTeacherId).HasColumnName("homeroom_teacher_id");
            entity.Property(e => e.Name)
                .HasMaxLength(10)
                .HasColumnName("name");
            entity.Property(e => e.SchoolYear)
                .HasMaxLength(10)
                .HasColumnName("school_year");

            entity.HasOne(d => d.HomeroomTeacher).WithMany(p => p.Classes)
                .HasForeignKey(d => d.HomeroomTeacherId)
                .HasConstraintName("FK__classes__homeroo__4CA06362");
        });

        modelBuilder.Entity<ClassSubject>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__class_su__3213E83F26393269");

            entity.ToTable("class_subjects");

            entity.HasIndex(e => new { e.ClassId, e.SubjectId, e.Semester, e.SchoolYear }, "UQ__class_su__0D210A2F3D00502B").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ClassId).HasColumnName("class_id");
            entity.Property(e => e.SchoolYear)
                .HasMaxLength(10)
                .HasColumnName("school_year");
            entity.Property(e => e.Semester).HasColumnName("semester");
            entity.Property(e => e.SubjectId).HasColumnName("subject_id");
            entity.Property(e => e.TeacherId).HasColumnName("teacher_id");

            entity.HasOne(d => d.Class).WithMany(p => p.ClassSubjects)
                .HasForeignKey(d => d.ClassId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__class_sub__class__5BE2A6F2");

            entity.HasOne(d => d.Subject).WithMany(p => p.ClassSubjects)
                .HasForeignKey(d => d.SubjectId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__class_sub__subje__5CD6CB2B");

            entity.HasOne(d => d.Teacher).WithMany(p => p.ClassSubjects)
                .HasForeignKey(d => d.TeacherId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__class_sub__teach__5DCAEF64");
        });

        modelBuilder.Entity<Club>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__clubs__3213E83F406CD801");

            entity.ToTable("clubs");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AdvisorId).HasColumnName("advisor_id");
            entity.Property(e => e.ClubType)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("club_type");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.IsActive)
                .HasDefaultValue(true)
                .HasColumnName("is_active");
            entity.Property(e => e.LogoUrl)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("logo_url");
            entity.Property(e => e.MaxMembers).HasColumnName("max_members");
            entity.Property(e => e.Name)
                .HasMaxLength(100)
                .HasColumnName("name");

            entity.HasOne(d => d.Advisor).WithMany(p => p.Clubs)
                .HasForeignKey(d => d.AdvisorId)
                .HasConstraintName("FK__clubs__advisor_i__208CD6FA");
        });

        modelBuilder.Entity<ClubMember>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__club_mem__3213E83FB770DB14");

            entity.ToTable("club_members");

            entity.HasIndex(e => new { e.ClubId, e.StudentId }, "UQ__club_mem__0E0E0DB160DD087E").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ClubId).HasColumnName("club_id");
            entity.Property(e => e.JoinedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("joined_at");
            entity.Property(e => e.Role)
                .HasMaxLength(10)
                .IsUnicode(false)
                .HasDefaultValue("member")
                .HasColumnName("role");
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasDefaultValue("pending")
                .HasColumnName("status");
            entity.Property(e => e.StudentId).HasColumnName("student_id");

            entity.HasOne(d => d.Club).WithMany(p => p.ClubMembers)
                .HasForeignKey(d => d.ClubId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__club_memb__club___2645B050");

            entity.HasOne(d => d.Student).WithMany(p => p.ClubMembers)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__club_memb__stude__2739D489");
        });

        modelBuilder.Entity<Conversation>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__conversa__3213E83F0049DE21");

            entity.ToTable("conversations");

            entity.HasIndex(e => new { e.StudentId, e.TeacherId }, "UQ__conversa__DA09E1EC0666452C").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.LastMsgAt)
                .HasColumnType("datetime")
                .HasColumnName("last_msg_at");
            entity.Property(e => e.StudentId).HasColumnName("student_id");
            entity.Property(e => e.TeacherId).HasColumnName("teacher_id");

            entity.HasOne(d => d.Student).WithMany(p => p.ConversationStudents)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__conversat__stude__3587F3E0");

            entity.HasOne(d => d.Teacher).WithMany(p => p.ConversationTeachers)
                .HasForeignKey(d => d.TeacherId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__conversat__teach__367C1819");
        });

        modelBuilder.Entity<Event>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__events__3213E83F85D432A8");

            entity.ToTable("events");

            entity.HasIndex(e => e.StartAt, "idx_events_start");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.BannerUrl)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("banner_url");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.CreatedBy).HasColumnName("created_by");
            entity.Property(e => e.CurrentRegistrations).HasColumnName("current_registrations");
            entity.Property(e => e.Description).HasColumnName("description");
            entity.Property(e => e.EndAt)
                .HasColumnType("datetime")
                .HasColumnName("end_at");
            entity.Property(e => e.EventType)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("event_type");
            entity.Property(e => e.IsActive)
                .HasDefaultValue(true)
                .HasColumnName("is_active");
            entity.Property(e => e.Location)
                .HasMaxLength(200)
                .HasColumnName("location");
            entity.Property(e => e.MaxCapacity).HasColumnName("max_capacity");
            entity.Property(e => e.StartAt)
                .HasColumnType("datetime")
                .HasColumnName("start_at");
            entity.Property(e => e.Title)
                .HasMaxLength(200)
                .HasColumnName("title");

            entity.HasOne(d => d.CreatedByNavigation).WithMany(p => p.Events)
                .HasForeignKey(d => d.CreatedBy)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__events__created___14270015");
        });

        modelBuilder.Entity<EventRegistration>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__event_re__3213E83F3F0DB8F6");

            entity.ToTable("event_registrations");

            entity.HasIndex(e => new { e.EventId, e.StudentId }, "UQ__event_re__91D3C74FBFE4411E").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.EventId).HasColumnName("event_id");
            entity.Property(e => e.RegisteredAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("registered_at");
            entity.Property(e => e.StudentId).HasColumnName("student_id");

            entity.HasOne(d => d.Event).WithMany(p => p.EventRegistrations)
                .HasForeignKey(d => d.EventId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__event_reg__event__1AD3FDA4");

            entity.HasOne(d => d.Student).WithMany(p => p.EventRegistrations)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__event_reg__stude__1BC821DD");
        });

        modelBuilder.Entity<Form>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__forms__3213E83F482A10B7");

            entity.ToTable("forms");

            entity.HasIndex(e => new { e.StudentId, e.Status }, "idx_forms_student_status");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AbsentDate).HasColumnName("absent_date");
            entity.Property(e => e.AttachmentUrl)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("attachment_url");
            entity.Property(e => e.Content).HasColumnName("content");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.FormType)
                .HasMaxLength(30)
                .IsUnicode(false)
                .HasColumnName("form_type");
            entity.Property(e => e.RejectReason)
                .HasMaxLength(500)
                .HasColumnName("reject_reason");
            entity.Property(e => e.ReviewedAt)
                .HasColumnType("datetime")
                .HasColumnName("reviewed_at");
            entity.Property(e => e.ReviewedBy).HasColumnName("reviewed_by");
            entity.Property(e => e.Status)
                .HasMaxLength(10)
                .IsUnicode(false)
                .HasDefaultValue("pending")
                .HasColumnName("status");
            entity.Property(e => e.StudentId).HasColumnName("student_id");
            entity.Property(e => e.Title)
                .HasMaxLength(200)
                .HasColumnName("title");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("updated_at");
            entity.Property(e => e.AssignedTo).HasColumnName("assigned_to");

            entity.HasOne(d => d.AssignedToNavigation).WithMany(p => p.FormAssignedToNavigations)
                .HasForeignKey(d => d.AssignedTo)
                .HasConstraintName("FK_forms_assigned_to");

            entity.HasOne(d => d.ReviewedByNavigation).WithMany(p => p.FormReviewedByNavigations)
                .HasForeignKey(d => d.ReviewedBy)
                .HasConstraintName("FK__forms__reviewed___0D7A0286");

            entity.HasOne(d => d.Student).WithMany(p => p.FormStudents)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__forms__student_i__09A971A2");
        });

        modelBuilder.Entity<Grade>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__grades__3213E83F327ABA61");

            entity.ToTable("grades", tb => tb.HasTrigger("trg_grades_compute"));

            entity.HasIndex(e => new { e.StudentId, e.ClassSubjectId }, "UQ__grades__A31DAC880F4D2E88").IsUnique();

            entity.HasIndex(e => e.StudentId, "idx_grades_student");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Avg15m).HasColumnName("avg_15m");
            entity.Property(e => e.Avg1h).HasColumnName("avg_1h");
            entity.Property(e => e.ClassSubjectId).HasColumnName("class_subject_id");
            entity.Property(e => e.GpaSubject).HasColumnName("gpa_subject");
            entity.Property(e => e.GradeLabel)
                .HasMaxLength(6)
                .IsUnicode(false)
                .HasColumnName("grade_label");
            entity.Property(e => e.IsFinalized).HasColumnName("is_finalized");
            entity.Property(e => e.Score15m1).HasColumnName("score_15m_1");
            entity.Property(e => e.Score15m2).HasColumnName("score_15m_2");
            entity.Property(e => e.Score15m3).HasColumnName("score_15m_3");
            entity.Property(e => e.Score1h1).HasColumnName("score_1h_1");
            entity.Property(e => e.Score1h2).HasColumnName("score_1h_2");
            entity.Property(e => e.Score1h3).HasColumnName("score_1h_3");
            entity.Property(e => e.ScoreFinal).HasColumnName("score_final");
            entity.Property(e => e.ScoreOral).HasColumnName("score_oral");
            entity.Property(e => e.StudentId).HasColumnName("student_id");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("updated_at");
            entity.Property(e => e.UpdatedBy).HasColumnName("updated_by");

            entity.HasOne(d => d.ClassSubject).WithMany(p => p.Grades)
                .HasForeignKey(d => d.ClassSubjectId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__grades__class_su__71D1E811");

            entity.HasOne(d => d.Student).WithMany(p => p.GradeStudents)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__grades__student___70DDC3D8");

            entity.HasOne(d => d.UpdatedByNavigation).WithMany(p => p.GradeUpdatedByNavigations)
                .HasForeignKey(d => d.UpdatedBy)
                .HasConstraintName("FK__grades__updated___7C4F7684");
        });

        modelBuilder.Entity<Message>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__messages__3213E83FE3931142");

            entity.ToTable("messages", tb => tb.HasTrigger("trg_messages_update_conversation"));

            entity.HasIndex(e => new { e.ConversationId, e.CreatedAt }, "idx_messages_conversation");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Content).HasColumnName("content");
            entity.Property(e => e.ConversationId).HasColumnName("conversation_id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.IsRead).HasColumnName("is_read");
            entity.Property(e => e.ReadAt)
                .HasColumnType("datetime")
                .HasColumnName("read_at");
            entity.Property(e => e.SenderId).HasColumnName("sender_id");

            entity.HasOne(d => d.Conversation).WithMany(p => p.Messages)
                .HasForeignKey(d => d.ConversationId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__messages__conver__3F115E1A");

            entity.HasOne(d => d.Sender).WithMany(p => p.Messages)
                .HasForeignKey(d => d.SenderId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__messages__sender__40058253");
        });

        modelBuilder.Entity<Notification>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__notifica__3213E83F1900E6A2");

            entity.ToTable("notifications");

            entity.HasIndex(e => new { e.UserId, e.IsRead }, "idx_notifications_user");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Body).HasColumnName("body");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.IsRead).HasColumnName("is_read");
            entity.Property(e => e.NotiType)
                .HasMaxLength(15)
                .IsUnicode(false)
                .HasColumnName("noti_type");
            entity.Property(e => e.RefId).HasColumnName("ref_id");
            entity.Property(e => e.RefType)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("ref_type");
            entity.Property(e => e.Title)
                .HasMaxLength(200)
                .HasColumnName("title");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.Notifications)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__notificat__user___2EDAF651");
        });

        modelBuilder.Entity<OtpCode>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__otp_code__3213E83F93F834A0");

            entity.ToTable("otp_codes");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Code)
                .HasMaxLength(6)
                .IsUnicode(false)
                .IsFixedLength()
                .HasColumnName("code");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.ExpiresAt)
                .HasColumnType("datetime")
                .HasColumnName("expires_at");
            entity.Property(e => e.IsUsed).HasColumnName("is_used");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.OtpCodes)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__otp_codes__user___46E78A0C");
        });

        modelBuilder.Entity<PeriodTime>(entity =>
        {
            entity.HasKey(e => e.PeriodNo).HasName("PK__period_t__2322CBAB23420D84");

            entity.ToTable("period_times");

            entity.Property(e => e.PeriodNo)
                .ValueGeneratedNever()
                .HasColumnName("period_no");
            entity.Property(e => e.EndTime).HasColumnName("end_time");
            entity.Property(e => e.Session)
                .HasMaxLength(10)
                .IsUnicode(false)
                .HasColumnName("session");
            entity.Property(e => e.StartTime).HasColumnName("start_time");
        });

        modelBuilder.Entity<RefreshToken>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__refresh___3213E83F290DBCCC");

            entity.ToTable("refresh_tokens");

            entity.HasIndex(e => e.Token, "UQ__refresh___CA90DA7A50B4EF8E").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.ExpiresAt)
                .HasColumnType("datetime")
                .HasColumnName("expires_at");
            entity.Property(e => e.Token)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("token");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.User).WithMany(p => p.RefreshTokens)
                .HasForeignKey(d => d.UserId)
                .HasConstraintName("FK__refresh_t__user___4316F928");
        });

        modelBuilder.Entity<Schedule>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__schedule__3213E83F29A2E50C");

            entity.ToTable("schedules");

            entity.HasIndex(e => new { e.ClassSubjectId, e.DayOfWeek, e.PeriodNo }, "UQ__schedule__A0A06D397255966C").IsUnique();

            entity.HasIndex(e => new { e.Room, e.DayOfWeek, e.PeriodNo }, "UQ__schedule__B47607E3F321008E").IsUnique();

            entity.HasIndex(e => e.ClassSubjectId, "idx_schedules_class");

            entity.HasIndex(e => new { e.DayOfWeek, e.PeriodNo }, "idx_schedules_day_period");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ClassSubjectId).HasColumnName("class_subject_id");
            entity.Property(e => e.DayOfWeek).HasColumnName("day_of_week");
            entity.Property(e => e.PeriodNo).HasColumnName("period_no");
            entity.Property(e => e.Room)
                .HasMaxLength(20)
                .HasColumnName("room");

            entity.HasOne(d => d.ClassSubject).WithMany(p => p.Schedules)
                .HasForeignKey(d => d.ClassSubjectId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__schedules__class__6383C8BA");

            entity.HasOne(d => d.PeriodNoNavigation).WithMany(p => p.Schedules)
                .HasForeignKey(d => d.PeriodNo)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__schedules__perio__656C112C");
        });

        modelBuilder.Entity<SemesterResult>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__semester__3213E83F19284AAC");

            entity.ToTable("semester_results");

            entity.HasIndex(e => new { e.StudentId, e.Semester, e.SchoolYear }, "UQ__semester__7760CA75131EDF3E").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AcademicRank)
                .HasMaxLength(6)
                .IsUnicode(false)
                .HasColumnName("academic_rank");
            entity.Property(e => e.AttendancePct).HasColumnName("attendance_pct");
            entity.Property(e => e.ClassId).HasColumnName("class_id");
            entity.Property(e => e.ConductRank)
                .HasMaxLength(6)
                .IsUnicode(false)
                .HasColumnName("conduct_rank");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.Gpa).HasColumnName("gpa");
            entity.Property(e => e.IsFinalized).HasColumnName("is_finalized");
            entity.Property(e => e.SchoolYear)
                .HasMaxLength(10)
                .HasColumnName("school_year");
            entity.Property(e => e.Semester).HasColumnName("semester");
            entity.Property(e => e.StudentId).HasColumnName("student_id");

            entity.HasOne(d => d.Class).WithMany(p => p.SemesterResults)
                .HasForeignKey(d => d.ClassId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__semester___class__02084FDA");

            entity.HasOne(d => d.Student).WithMany(p => p.SemesterResults)
                .HasForeignKey(d => d.StudentId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__semester___stude__01142BA1");
        });

        modelBuilder.Entity<StudentProfile>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__student___3213E83F2DB61EFE");

            entity.ToTable("student_profiles");

            entity.HasIndex(e => e.UserId, "UQ__student___B9BE370E828E954A").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Address)
                .HasMaxLength(300)
                .HasColumnName("address");
            entity.Property(e => e.BirthDate).HasColumnName("birth_date");
            entity.Property(e => e.ClassId).HasColumnName("class_id");
            entity.Property(e => e.EnrollmentDate).HasColumnName("enrollment_date");
            entity.Property(e => e.Gender)
                .HasMaxLength(6)
                .IsUnicode(false)
                .HasColumnName("gender");
            entity.Property(e => e.ParentEmail)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("parent_email");
            entity.Property(e => e.ParentName)
                .HasMaxLength(100)
                .HasColumnName("parent_name");
            entity.Property(e => e.ParentPhone)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("parent_phone");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("updated_at");
            entity.Property(e => e.UserId).HasColumnName("user_id");

            entity.HasOne(d => d.Class).WithMany(p => p.StudentProfiles)
                .HasForeignKey(d => d.ClassId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__student_p__class__52593CB8");

            entity.HasOne(d => d.User).WithOne(p => p.StudentProfile)
                .HasForeignKey<StudentProfile>(d => d.UserId)
                .HasConstraintName("FK__student_p__user___5165187F");
        });

        modelBuilder.Entity<Subject>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__subjects__3213E83F6D4E5775");

            entity.ToTable("subjects");

            entity.HasIndex(e => e.Code, "UQ__subjects__357D4CF9F23FB405").IsUnique();

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Code)
                .HasMaxLength(10)
                .IsUnicode(false)
                .HasColumnName("code");
            entity.Property(e => e.IsActive)
                .HasDefaultValue(true)
                .HasColumnName("is_active");
            entity.Property(e => e.Name)
                .HasMaxLength(50)
                .HasColumnName("name");
            entity.Property(e => e.ShortName)
                .HasMaxLength(10)
                .HasColumnName("short_name");
        });

        modelBuilder.Entity<TeacherChatSetting>(entity =>
        {
            entity.HasKey(e => e.TeacherId).HasName("PK__teacher___03AE777E52796B82");

            entity.ToTable("teacher_chat_settings");

            entity.Property(e => e.TeacherId)
                .ValueGeneratedNever()
                .HasColumnName("teacher_id");
            entity.Property(e => e.AllowMessagesFromStudents)
                .HasDefaultValue(true)
                .HasColumnName("allow_messages_from_students");
            entity.Property(e => e.AllowedHoursEnd).HasColumnName("allowed_hours_end");
            entity.Property(e => e.AllowedHoursStart).HasColumnName("allowed_hours_start");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("updated_at");

            entity.HasOne(d => d.Teacher).WithOne(p => p.TeacherChatSetting)
                .HasForeignKey<TeacherChatSetting>(d => d.TeacherId)
                .HasConstraintName("FK__teacher_c__teach__3A4CA8FD");
        });

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(e => e.Id).HasName("PK__users__3213E83F0FE934EA");

            entity.ToTable("users", tb => tb.HasTrigger("trg_users_updated"));

            entity.HasIndex(e => e.Email, "UQ__users__AB6E6164793ED0FD").IsUnique();

            entity.HasIndex(e => e.StudentCode, "idx_users_student_code_unique")
                .IsUnique()
                .HasFilter("([student_code] IS NOT NULL)");

            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.AvatarUrl)
                .HasMaxLength(500)
                .IsUnicode(false)
                .HasColumnName("avatar_url");
            entity.Property(e => e.CreatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("created_at");
            entity.Property(e => e.Email)
                .HasMaxLength(100)
                .IsUnicode(false)
                .HasColumnName("email");
            entity.Property(e => e.FullName)
                .HasMaxLength(100)
                .HasColumnName("full_name");
            entity.Property(e => e.IsActive)
                .HasDefaultValue(true)
                .HasColumnName("is_active");
            entity.Property(e => e.PasswordHash)
                .HasMaxLength(255)
                .IsUnicode(false)
                .HasColumnName("password_hash");
            entity.Property(e => e.Phone)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("phone");
            entity.Property(e => e.StudentCode)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasColumnName("student_code");
            entity.Property(e => e.TokenVersion)
                .HasDefaultValue(1)
                .HasColumnName("token_version");
            entity.Property(e => e.UpdatedAt)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime")
                .HasColumnName("updated_at");

            entity.HasMany(d => d.Roles).WithMany(p => p.Users)
                .UsingEntity<Dictionary<string, object>>(
                    "user_roles",
                    r => r.HasOne<Role>().WithMany().HasForeignKey("role_id"),
                    l => l.HasOne<User>().WithMany().HasForeignKey("user_id"),
                    je =>
                    {
                        je.HasKey("user_id", "role_id");
                        je.ToTable("user_roles");
                        je.Property<int>("user_id").HasColumnName("user_id");
                        je.Property<int>("role_id").HasColumnName("role_id");
                        je.Property<DateTime>("assigned_at").HasDefaultValueSql("(getdate())").HasColumnName("assigned_at");
                    });
        });

        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(e => e.Id);
            entity.ToTable("roles");
            entity.HasIndex(e => e.Name).IsUnique();
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.Name).HasMaxLength(50).IsUnicode(false).HasColumnName("name");
            entity.Property(e => e.Description).HasMaxLength(255).HasColumnName("description");
            entity.Property(e => e.CreatedAt).HasDefaultValueSql("(getdate())").HasColumnType("datetime").HasColumnName("created_at");
        });
        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
