# MyF School Management System

MyF School Management System is a personal full-stack project for digitizing core school operations. It combines a Flutter client for students and teachers with an ASP.NET Core backend, SQL Server database, and browser-based administration portal.

The application supports role-specific workflows for learning operations, communication, clubs, and school events.

## Features

### Student experience

- View a personalized dashboard, weekly timetable, attendance history, and grades.
- Submit absence and administrative requests with an optional image attachment, then track review status.
- Message teachers, receive notifications, manage profile information, and update an avatar.
- Browse clubs, request membership, view club activities, and register or cancel registration for events.

### Teacher experience

- View assigned schedules, class rosters, and individual student details.
- Record and update attendance for a scheduled class.
- Enter grades for a class subject and finalize grade records.
- Review student requests and communicate with students.
- Manage club members and club sessions when assigned as a club leader.

### Administration portal

- Manage users and view school statistics through Razor Pages.
- Import schedules from Excel files.
- Access a separate session-protected administration area at `/Admin`.

## Technology Stack

| Area | Technologies |
| --- | --- |
| Mobile client | Flutter, Dart, GetX, Dio, SharedPreferences, Image Picker |
| Backend | C#, ASP.NET Core 8, RESTful API, Razor Pages |
| Data | SQL Server, Entity Framework Core |
| Authentication | JWT Bearer authentication, BCrypt password hashing, role-based authorization |
| Supporting services | MailKit for OTP emails, EPPlus for Excel import, Swagger/OpenAPI |

## Architecture

```text
Flutter Client (GetX)
        |
        | HTTP requests through Dio with JWT bearer token
        v
ASP.NET Core 8 Web API
Controllers -> DTOs -> Entity Framework Core
        |
        v
SQL Server

Browser -> Razor Pages Admin Portal -> ASP.NET Core / SQL Server
```

The Flutter client stores the authenticated session and role information with SharedPreferences. Its centralized Dio client adds the JWT bearer token to API requests and returns the user to the login screen when an expired session produces an unauthorized response.

## Authentication and Data Integrity

- JWTs include role claims for student and teacher authorization.
- Passwords are verified and stored with BCrypt.
- Password reset uses one-time passwords sent by email.
- Changing a password increments a token version, invalidating previously issued JWTs.
- Database constraints prevent duplicate attendance records, club memberships, event registrations, schedules, grades, and student profiles where applicable.
- Form attachments are validated for size and image signature before storage.

## Project Structure

```text
myfschools/
├── myfschools_frontend/                     # Flutter application
│   └── lib/
│       ├── controllers/                     # GetX state and API workflows
│       ├── models/                          # Client-side DTO models
│       ├── screens/                         # Student and teacher screens
│       └── services/api_client.dart         # Shared Dio client and JWT interceptor
└── myfschools_backend/
    └── myfschool_be/
        └── myfschool_be/                    # ASP.NET Core API and admin portal
            ├── Controllers/                 # REST endpoints
            ├── DTOs/                        # API request and response contracts
            ├── Models/                      # EF Core entities and DbContext
            ├── Pages/Admin/                 # Razor Pages administration portal
            └── Services/                    # Email service
```

## Prerequisites

- Flutter SDK and a compatible Dart SDK
- .NET 8 SDK
- SQL Server
- An Android emulator, physical device, or another supported Flutter target

## Configuration

Before running the project, configure the backend settings in `myfschools_backend/myfschool_be/myfschool_be/appsettings.Development.json`:

- `ConnectionStrings:DefaultConnection` for SQL Server
- `Jwt:Key`, `Jwt:Issuer`, and `Jwt:Audience`
- `Email` SMTP settings for OTP password recovery

> **Database prerequisite:** the repository currently does not include Entity Framework migrations, seed data, or a SQL creation script. Point the connection string to a SQL Server database whose schema matches `FptschoolContext` before starting the API.

## Run Locally

### 1. Start the backend

```bash
cd myfschools_backend/myfschool_be/myfschool_be
dotnet restore
dotnet run --launch-profile http
```

The development profile runs the backend at `http://localhost:5005`.

### 2. Start the Flutter application

```bash
cd myfschools_frontend
flutter pub get
flutter run
```

The Flutter client is configured for an Android emulator at `http://10.0.2.2:5005`. For a physical device, iOS simulator, web browser, or desktop target, update `baseUrl` in `myfschools_frontend/lib/constants/app_constants.dart` to an address reachable from that target.

## Development Endpoints

When the backend runs in the Development environment:

- Swagger UI: `http://localhost:5005/swagger`
- Administration portal: `http://localhost:5005/Admin/Login`

## Author

Developed independently as a personal full-stack project.
