using Microsoft.AspNetCore.Http;
using System.ComponentModel.DataAnnotations;

namespace myfschool_be.DTOs
{
    // DTO Nhận Request (Multipart/form-data)
    public class CreateFormRequestDto
    {
        [Required]
        public string FormType { get; set; } = null!;

        [Required]
        public string Title { get; set; } = null!;

        [Required]
        public string Content { get; set; } = null!;

        public DateOnly? AbsentDate { get; set; }

        /// NULL = gửi cho GVCN (mặc định), có giá trị = gửi cho GVBM cụ thể
        public int? AssignedTo { get; set; }

        public IFormFile? Attachment { get; set; } // Hứng file mã nhị phân ảnh được tải lên
    }

    // DTO Trả Response (JSON)
    public class FormResponseDto
    {
        public int Id { get; set; }
        public string FormType { get; set; } = null!;
        public string Title { get; set; } = null!;
        public string Content { get; set; } = null!;
        public DateOnly? AbsentDate { get; set; }
        public string? AttachmentUrl { get; set; }
        public string Status { get; set; } = null!;
        public string? RejectReason { get; set; }
        public DateTime CreatedAt { get; set; }
    }

    // DTO Giáo viên Duyệt đơn
    public class ReviewFormRequestDto
    {
        [Required]
        public string Status { get; set; } = null!; // Approved hoặc Rejected

        public string? RejectReason { get; set; }
    }
}
