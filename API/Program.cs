using Microsoft.Data.SqlClient;
using Azure.Identity;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

app.UseSwagger();
app.UseSwaggerUI();

// Health check endpoint
app.MapGet("/health", () => Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow }))
    .WithName("HealthCheck")
    .WithOpenApi();

// Diagnostic endpoint to test SQL connectivity
app.MapGet("/api/diagnose", async () =>
{
    var connectionString = builder.Configuration.GetConnectionString("SqlDatabase");
    var diagnostics = new Dictionary<string, object>
    {
        { "timestamp", DateTime.UtcNow },
        { "connectionStringConfigured", !string.IsNullOrEmpty(connectionString) },
        { "connectionStringValue", "SET, CHECK APP SETTINGS FOR VALUE" ?? "NOT SET" }
    };
    
    if (string.IsNullOrEmpty(connectionString))
    {
        return Results.Ok(diagnostics);
    }
    
    try
    {
        using var connection = new SqlConnection(connectionString);
        var startTime = DateTime.UtcNow;
        await connection.OpenAsync();
        var connectTime = (DateTime.UtcNow - startTime).TotalMilliseconds;
        
        diagnostics["sqlConnectionStatus"] = "SUCCESS";
        diagnostics["connectionTimeMs"] = connectTime;
        diagnostics["serverVersion"] = connection.ServerVersion;
        diagnostics["database"] = connection.Database;
        
        using var command = new SqlCommand("SELECT SERVERPROPERTY('MachineName') as ServerName, CONNECTIONPROPERTY('client_net_address') as ClientIP", connection);
        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            diagnostics["serverName"] = reader["ServerName"];
            diagnostics["clientIP"] = reader["ClientIP"];
        }
        
        return Results.Ok(diagnostics);
    }
    catch (Exception ex)
    {
        diagnostics["sqlConnectionStatus"] = "FAILED";
        diagnostics["errorMessage"] = ex.Message;
        diagnostics["errorType"] = ex.GetType().Name;
        if (ex.InnerException != null)
        {
            diagnostics["innerError"] = ex.InnerException.Message;
        }
        return Results.Ok(diagnostics);
    }
})
.WithName("Diagnose")
.WithOpenApi();

// Get all items from SQL
app.MapGet("/api/items", async () =>
{
    var connectionString = builder.Configuration.GetConnectionString("SqlDatabase");
    
    if (string.IsNullOrEmpty(connectionString))
    {
        return Results.Problem("Database connection string not configured");
    }
    
    try
    {
        // DefaultAzureCredential is used automatically via "Authentication=Active Directory Default" in connection string
        using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();
        
        using var command = new SqlCommand("SELECT Id, Name, Description, CreatedDate FROM Items ORDER BY CreatedDate DESC", connection);
        using var reader = await command.ExecuteReaderAsync();
        
        var items = new List<object>();
        while (await reader.ReadAsync())
        {
            items.Add(new 
            { 
                id = reader["Id"], 
                name = reader["Name"],
                description = reader["Description"],
                createdDate = reader["CreatedDate"]
            });
        }
        
        return Results.Ok(items);
    }
    catch (SqlException ex)
    {
        return Results.Problem($"Database error: {ex.Message}");
    }
    catch (Exception ex)
    {
        return Results.Problem($"Error: {ex.Message}");
    }
})
.WithName("GetItems")
.WithOpenApi();

// Create sample table if it doesn't exist (for testing)
app.MapPost("/api/setup", async () =>
{
    var connectionString = builder.Configuration.GetConnectionString("SqlDatabase");
    
    if (string.IsNullOrEmpty(connectionString))
    {
        return Results.Problem("Database connection string not configured");
    }
    
    try
    {
        // DefaultAzureCredential is used automatically via "Authentication=Active Directory Default" in connection string
        using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();
        
        var createTableSql = @"
            IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Items')
            BEGIN
                CREATE TABLE Items (
                    Id INT IDENTITY(1,1) PRIMARY KEY,
                    Name NVARCHAR(100) NOT NULL,
                    Description NVARCHAR(500),
                    CreatedDate DATETIME2 DEFAULT GETUTCDATE()
                );
                
                INSERT INTO Items (Name, Description) VALUES 
                ('Sample Item 1', 'This is a test item'),
                ('Sample Item 2', 'Another test item'),
                ('Sample Item 3', 'Yet another test item');
            END";
        
        using var command = new SqlCommand(createTableSql, connection);
        await command.ExecuteNonQueryAsync();
        
        return Results.Ok(new { message = "Database setup completed successfully" });
    }
    catch (Exception ex)
    {
        return Results.Problem($"Setup error: {ex.Message}");
    }
})
.WithName("SetupDatabase")
.WithOpenApi();

app.Run();
