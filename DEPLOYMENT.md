# Hub-and-Spoke Architecture with SQL Database

## Architecture Overview

This infrastructure now implements a **hub-and-spoke network architecture** with four VNets:

```
┌─────────────────────────────────────────────────────────────┐
│                    DMZ VNet (10.0.0.0/16)                   │
│                    - Front Door Private Link                 │
└──────────────────────────┬──────────────────────────────────┘
                           │ Peering
┌──────────────────────────┴──────────────────────────────────┐
│                    Hub VNet (10.1.0.0/16)                   │
│                    - Central Connectivity Hub                │
│                    - Private DNS Zones                       │
└────────────┬────────────────────────────┬────────────────────┘
             │ Peering                    │ Peering
┌────────────┴──────────────┐  ┌─────────┴──────────────────┐
│ Spoke App VNet             │  │ Spoke Data VNet            │
│ (10.2.0.0/16)              │  │ (10.3.0.0/16)              │
│ - App Service              │  │ - SQL Database             │
│ - App Service PE           │  │ - SQL Private Endpoint     │
└────────────────────────────┘  └────────────────────────────┘
```

## Traffic Flow

**App Service to SQL Database:**
1. Request originates from App Service (10.2.x.x)
2. Traffic traverses through Hub VNet (10.1.x.x) via VNet peering
3. Reaches SQL Database private endpoint in Data Spoke (10.3.1.x)
4. DNS resolution via Private DNS Zone linked to all VNets

## Network Segmentation

- **DMZ VNet (10.0.0.0/16)**: Hosts Front Door private link connections
- **Hub VNet (10.1.0.0/16)**: Central connectivity, shared services, Private DNS
- **Spoke App VNet (10.2.0.0/16)**: Application tier (App Service)
- **Spoke Data VNet (10.3.0.0/16)**: Data tier (SQL Database) - isolated from app tier

## API Deployment

The .NET API in `/API` folder is automatically deployed via Terraform:

1. **Build**: `dotnet publish` creates release build
2. **Package**: Compressed into zip file
3. **Deploy**: Deployed to App Service using Azure CLI
4. **Connection String**: Automatically configured for SQL Database

### API Endpoints

- `GET /health` - Health check
- `GET /api/items` - Retrieve items from SQL Database
- `POST /api/setup` - Initialize database table (for testing)

## Deployment Instructions

1. **Update SQL Password** in `terraform/environments/dev/terraform.tfvars`:
   ```hcl
   sql_admin_password = "YourSecurePasswordHere!"
   ```

2. **Ensure .NET 8 SDK is installed**:
   ```powershell
   dotnet --version
   ```

3. **Login to Azure CLI**:
   ```powershell
   az login
   ```

4. **Deploy Infrastructure**:
   ```powershell
   cd terraform/environments/dev
   terraform init
   terraform plan
   terraform apply
   ```

The `terraform apply` will:
- Create all infrastructure (VNets, App Service, SQL Database)
- Build and deploy the .NET API
- Configure connection strings automatically

## Security Considerations

### ✅ Implemented
- SQL Database has **public access disabled**
- SQL accessible only via **private endpoint** in isolated VNet
- App Service must traverse **Hub VNet** to reach database
- All DNS resolution through **Private DNS Zones**
- **VNet integration** for App Service outbound traffic
- **WAF** enabled on Front Door

### ⚠️ Production Recommendations
- Store SQL password in **Azure Key Vault**
- Use **Managed Identity** for App Service to SQL authentication
- Enable **diagnostic logs** and monitoring
- Implement **Network Security Groups** on data subnet
- Use **Azure Firewall** in Hub for additional security
- Enable **Azure Defender for SQL**

## Customization

### Network Address Spaces
Edit `terraform/environments/dev/terraform.tfvars`:
```hcl
vnet_address_space            = "10.0.0.0/16"  # DMZ
hub_vnet_address_space        = "10.1.0.0/16"  # Hub (via variables.tf defaults)
spoke_app_vnet_address_space  = "10.2.0.0/16"  # App Spoke (via variables.tf defaults)
spoke_data_vnet_address_space = "10.3.0.0/16"  # Data Spoke (via variables.tf defaults)
```

### SQL Database SKU
```hcl
sql_database_sku = "Basic"  # Options: Basic, S0, S1, S2, S3, P1, P2, P4, etc.
sql_database_max_size_gb = 2
```

## Troubleshooting

### API Not Deploying
- Ensure .NET 8 SDK is installed
- Check Azure CLI is authenticated: `az account show`
- Review Terraform output for deployment errors

### SQL Connection Issues
- Verify Private DNS Zone is linked to all VNets
- Check VNet peering status in Azure Portal
- Ensure SQL connection string is configured in App Service

### Testing the API
```powershell
# Get App Service URL
$appUrl = "FRONT_DOOR_URL"

# Health check
Invoke-RestMethod -Uri "$appUrl/health"

# Setup database (first time)
Invoke-RestMethod -Uri "$appUrl/api/setup" -Method Post

# Get items
Invoke-RestMethod -Uri "$appUrl/api/items"
```
