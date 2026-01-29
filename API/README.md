# Web App API

Minimal .NET 8 API with Azure SQL Database connectivity.

## Endpoints

- `GET /health` - Health check endpoint
- `GET /api/items` - Get all items from database
- `POST /api/setup` - Initialize database with sample table and data (for testing)

## Local Development

```bash
dotnet restore
dotnet run
```

Visit `http://localhost:5000/swagger` for API documentation.

## Deployment

This API is automatically deployed to Azure App Service via Terraform using a null_resource provisioner.

The connection string is configured via App Service configuration as `SQLAZURECONNSTR_SqlDatabase`.
