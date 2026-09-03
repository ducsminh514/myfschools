using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using myfschool_be.Models;
using myfschool_be.Middleware;

var builder = WebApplication.CreateBuilder(args);

// 1. Thêm DbContext
builder.Services.AddDbContext<FptschoolContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

// 2. Cấu hình JWT Authentication
var jwtSettings = builder.Configuration.GetSection("Jwt");
var key = Encoding.UTF8.GetBytes(jwtSettings["Key"] ?? "SecretKey");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidAudience = jwtSettings["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(key)
    };

    options.Events = new JwtBearerEvents
    {
        OnTokenValidated = async context =>
        {
            var dbContext = context.HttpContext.RequestServices.GetRequiredService<FptschoolContext>();
            var userIdStr = context.Principal?.FindFirstValue(ClaimTypes.NameIdentifier);
            var tokenVersionStr = context.Principal?.FindFirstValue("TokenVersion");

            if (int.TryParse(userIdStr, out int userId) && int.TryParse(tokenVersionStr, out int tokenVersion))
            {
                var user = await dbContext.Users.FindAsync(userId);
                if (user == null || user.TokenVersion != tokenVersion)
                {
                    context.Fail("Mật khẩu đã thay đổi, phiên đăng nhập không còn hợp lệ.");
                }
            }
            else
            {
                context.Fail("Token thiếu thông tin quan trọng.");
            }
        }
    };
});

// 3. Cấu hình CORS cho Flutter Emulator (Tạm thời AllowAll)
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll",
        policy => policy.AllowAnyOrigin()
                        .AllowAnyMethod()
                        .AllowAnyHeader());
});

// 3.5 Đăng ký EmailService
builder.Services.AddSingleton<myfschool_be.Services.EmailService>();

// 3.6 Session cho Admin Panel (in-memory, 30 phút timeout)
builder.Services.AddDistributedMemoryCache();
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
    options.Cookie.Name = "FPTSchool.Admin";
});

builder.Services.AddControllers()
    .AddJsonOptions(opts =>
    {
        // Trả camelCase cho tất cả JSON responses (phù hợp với Dart/Flutter convention)
        opts.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        opts.JsonSerializerOptions.DictionaryKeyPolicy  = System.Text.Json.JsonNamingPolicy.CamelCase;
    });
// 4. Configure Swagger with JWT Support
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "MyFSchool API", Version = "v1" });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Authorization header using the Bearer scheme. Example: \"Authorization: Bearer {token}\"",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.Http,
        Scheme = "bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// 4.5 Razor Pages cho Admin Panel
builder.Services.AddRazorPages();

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// Mở cổng Static Files cho mục đích lấy file Ảnh từ thư mục wwwroot
app.UseStaticFiles();

app.UseCors("AllowAll");
// app.UseHttpsRedirection(); // Bỏ Redirection để Android Emulator vào bằng HTTP trong lúc Dev

// 5. Thêm UseAuthentication trước UseAuthorization();
app.UseSession();           // Session phải trước middleware
app.UseMiddleware<AdminAuthMiddleware>(); // Check admin session
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapRazorPages();        // Razor Pages routes

// Root URL → redirect Admin Login
app.MapGet("/", context =>
{
    context.Response.Redirect("/Admin/Login");
    return Task.CompletedTask;
});

app.Run();
