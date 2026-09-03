namespace myfschool_be.DTOs
{
    public class LoginRequest
    {
        public required string Phone { get; set; }
        public required string Password { get; set; }
    }

    public class LoginResponse
    {
        public required string Token { get; set; }
        public required UserDto User { get; set; }
    }

    public class UserDto
    {
        public int Id { get; set; }
        public string? Email { get; set; }
        public string? FullName { get; set; }
        public List<string> Roles { get; set; } = new List<string>();
        public string? StudentCode { get; set; }
    }
}
