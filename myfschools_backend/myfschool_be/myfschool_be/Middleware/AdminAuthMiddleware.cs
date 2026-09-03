namespace myfschool_be.Middleware
{
    /// <summary>
    /// Middleware kiểm tra session admin cho tất cả request /Admin/* (trừ Login/Logout).
    /// Nếu chưa login → redirect /Admin/Login.
    /// </summary>
    public class AdminAuthMiddleware
    {
        private readonly RequestDelegate _next;

        public AdminAuthMiddleware(RequestDelegate next)
        {
            _next = next;
        }

        public async Task InvokeAsync(HttpContext context)
        {
            var path = context.Request.Path.Value?.ToLower() ?? "";

            // Chỉ check các route /admin/*
            if (path.StartsWith("/admin"))
            {
                // Cho phép static files (css, js, images) đi qua
                if (Path.HasExtension(path))
                {
                    await _next(context);
                    return;
                }

                // Cho phép truy cập Login/Logout mà không cần session
                if (path == "/admin/login" || path == "/admin/logout")
                {
                    await _next(context);
                    return;
                }

                // Check session
                var adminId = context.Session.GetInt32("AdminUserId");
                if (adminId == null)
                {
                    context.Response.Redirect("/Admin/Login");
                    return;
                }
            }

            await _next(context);
        }
    }
}
