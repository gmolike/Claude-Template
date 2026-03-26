using FluentValidation;
using MediatR;
using Microsoft.EntityFrameworkCore;
using {{PROJECT_NAME}}.Application.Behaviors;
using {{PROJECT_NAME}}.Domain.Interfaces;
using {{PROJECT_NAME}}.Infrastructure.Persistence;
using {{PROJECT_NAME}}.Infrastructure.Persistence.Repositories;

var builder = WebApplication.CreateBuilder(args);

// Database
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));

// MediatR + Validation Pipeline
builder.Services.AddMediatR(cfg =>
    cfg.RegisterServicesFromAssembly(typeof({{PROJECT_NAME}}.Application.Commands.CreateUserCommand).Assembly));
builder.Services.AddValidatorsFromAssembly(typeof({{PROJECT_NAME}}.Application.Commands.CreateUserCommand).Assembly);
builder.Services.AddTransient(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));

// Repositories
builder.Services.AddScoped<IUserRepository, UserRepository>();

// Swagger
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();
builder.Services.AddControllers();

// CORS
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
        policy.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod());
});

var app = builder.Build();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseCors();
app.MapControllers();
app.Run();
