# Azure App Sample - Hub-and-Spoke Architecture with Azure Front Door

This Terraform configuration uses a three-layer modular architecture to deploy a secure Azure web application infrastructure with a **hub-and-spoke network topology** and **Azure Front Door** as the entry point.

## 📁 Folder Structure

```
terraform/
├── environments/
│   └── dev/
│       ├── main.tf                    # Environment-specific configuration
│       ├── variables.tf               # Environment variables
│       ├── outputs.tf                 # Environment outputs
│       └── terraform.tfvars.example   # Example configuration
├── project/
│   ├── main.tf                        # Project-level orchestration
│   ├── variables.tf                   # Project variables
│   └── outputs.tf                     # Project outputs
└── modules/
    └── azurerm/
        ├── resource_group/            # Resource Group module
        ├── virtual_network/           # Virtual Network module
        ├── subnet/                    # Subnet module
        ├── vnet_peering/              # VNet Peering module (NEW)
        ├── private_dns/               # Private DNS Zone module
        ├── private_endpoint/          # Private Endpoint module
        ├── app_service/               # App Service module
        ├── front_door/                # Azure Front Door module (NEW)
        ├── waf_policy/                # WAF Policy module (NEW)
        └── network_security_group/    # NSG module
```

## 🏗️ Architecture Overview

### Hub-and-Spoke Network Topology

This infrastructure implements a **hub-and-spoke architecture** with three virtual networks:

1. **DMZ VNet (10.0.0.0/16)** - Entry point for Azure Front Door
   - Front Door Subnet: 10.0.1.0/24
   - Contains Azure Front Door Private Link connection

2. **Hub VNet (10.1.0.0/16)** - Central connectivity hub
   - Firewall Subnet: 10.1.1.0/24 (reserved for future use)
   - Connects both DMZ and Spoke VNets via VNet peering
   - Hosts shared services and Private DNS zones

3. **Spoke VNet (10.2.0.0/16)** - Application workload
   - App Service Integration Subnet: 10.2.1.0/24
   - Private Endpoints Subnet: 10.2.2.0/24
   - Contains the private App Service

### Traffic Flow

```
Internet → Azure Front Door → DMZ VNet → Hub VNet → Spoke VNet → Private App Service
```

1. **Azure Front Door** receives HTTPS traffic from the internet
2. Traffic flows through **Private Link** to the DMZ VNet
3. **VNet Peering** routes traffic from DMZ to Hub VNet
4. **VNet Peering** routes traffic from Hub to Spoke VNet
5. **Private Endpoint** connects to the App Service (not publicly accessible)

### Three-Layer Design

1. **Environments Layer** (`environments/dev/`)
   - Terraform and provider version constraints
   - Generates random suffix for resource uniqueness
   - Sets environment-specific configuration
   - Calls the project module

2. **Project Layer** (`project/`)
   - Orchestrates all infrastructure components
   - Builds resource names following naming conventions
   - Calls individual resource modules
   - Manages dependencies between resources

3. **Modules Layer** (`modules/azurerm/`)
   - Reusable, single-purpose resource modules
   - Standardized inputs (name, resource_group_name, location, tags)
   - Consistent outputs (id, name, resource-specific outputs)

### Deployed Resources

- **Resource Group**: Container for all resources
- **Three Virtual Networks**: Hub-and-Spoke topology
  - DMZ VNet (10.0.0.0/16): Front Door entry point
  - Hub VNet (10.1.0.0/16): Central connectivity
  - Spoke VNet (10.2.0.0/16): App Service hosting
- **VNet Peerings**: DMZ ↔ Hub, Hub ↔ Spoke
- **Azure Front Door Premium**: Global entry point with WAF
- **App Service**: Linux-based, VNet integrated (completely private)
- **Private Endpoint**: Secure connection to App Service
- **Private DNS Zone**: Name resolution for private resources
- **Network Security Groups**: Traffic filtering at subnet level
- **WAF Policy**: Web Application Firewall protection

## 🔒 Security Features

✅ **App Service is COMPLETELY private** - No public access, only via Front Door  
✅ **Hub-and-Spoke Architecture** - Centralized security and network control  
✅ **Azure Front Door with WAF** - Global entry point with DDoS and WAF protection  
✅ **Private Link** - Front Door connects privately to the App Service  
✅ **VNet Integration** - App Service integrated into isolated virtual network  
✅ **HTTPS enforced** - App Service configured for HTTPS only  
✅ **TLS 1.2 minimum** - Modern encryption standards enforced  
✅ **Network Security Groups** - Traffic filtering at subnet level  
✅ **Private DNS** - Internal name resolution across peered networks

## 🚀 Quick Start

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Active Azure subscription with appropriate permissions

### Deployment Steps

1. **Authenticate with Azure**

```bash
az login
az account set --subscription "<your-subscription-id>"
```

2. **Navigate to Environment Directory**

```bash
cd terraform/environments/dev
```

3. **Configure Variables**

Copy and customize the tfvars file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to customize network ranges and SKUs if needed.

4. **Initialize Terraform**

```bash
terraform init
```

5. **Review the Deployment Plan**

```bash
terraform plan
```

6. **Deploy Infrastructure**

```bash
terraform apply
```

Type `yes` when prompted.

7. **Deploy API Code**

To deploy the API code via the Azure Portal:

1. Build the API project locally:
   ```bash
   dotnet publish API/WebAppApi.csproj -c Release -o ./publish
   ```
2. Compress the contents of the `./publish` directory into a zip file.
3. In the Azure Portal, navigate to the newly created App Service.
4. **Important**: Since the App Service is private, you must temporarily remove the **Network** > **Public network access** restrictions (or specific IP restrictions) to allow validation and deployment from the Portal/your machine.
5. Upload the code using the **Deployment Center** or via **Advanced Tools (Kudu)** > Zip Push Deploy.

8. **Re-Apply Configuration**

Re-run Terraform apply to ensure network restrictions are re-applied and the state is consistent.

```bash
terraform apply
```

9. **Wait for Front Door Url to be active**
This powershell script will collect the front door url and check the /health endpoint of the api until it is available. This maty take 10-30 minutes:
```ps
# Script to check API health through Front Door

$ErrorActionPreference = "Stop"

try {
    Write-Host "Getting Front Door URL from Terraform outputs..."
    # Check if terraform is initialized/has state
    if (-not (Test-Path "terraform.tfstate")) {
        Write-Warning "terraform.tfstate not found in $terraformDir. Was terraform apply run?"
    }

    $frontDoorUrl = terraform output -raw front_door_url
}
catch {
    Write-Error "Failed to get Front Door URL from Terraform. Ensure Terraform is initialized and applied."
    Pop-Location
    exit 1
}
finally {
    Pop-Location
}

if ([string]::IsNullOrWhiteSpace($frontDoorUrl)) {
    Write-Error "Front Door URL is empty."
    exit 1
}

# Ensure correct URL formatting
if ($frontDoorUrl.EndsWith("/")) {
    $healthUrl = "${frontDoorUrl}health"
} else {
    $healthUrl = "${frontDoorUrl}/health"
}

Write-Host "Monitoring Health Endpoint: $healthUrl"
Write-Host "Checking every 30 seconds..."

while ($true) {
    try {
        $response = Invoke-WebRequest -Uri $healthUrl -Method Get -ErrorAction Stop
        
        if ($response.StatusCode -eq 200) {
            Write-Host -ForegroundColor Green "`nAPI is Ready! (Status: 200 OK)"
            Write-Host "Response: $($response.Content)"
            break
        }
        else {
            Write-Host -NoNewline "."
        }
    }
    catch {
        # Catch 4xx/5xx errors or connection failures
        Write-Host -NoNewline "."
    }

    Start-Sleep -Seconds 30
}
```


10. **Access Application**

After deployment and propagation (~10-20 minutes for Front Door), get the Front Door URL:

```bash
terraform output front_door_url
```

Use the Front Door URL to verify the application:

- **Health Probe**: `https://<front-door-url>/health`
- **Initialize Database**: `https://<front-door-url>/setup` (Required first run)
- **List Items**: `https://<front-door-url>/items`



## ⚙️ Configuration

### Key Variables

#### Hub-and-Spoke Network

| Variable | Description | Default |
|----------|-------------|---------|
| `dmz_vnet_address_space` | DMZ VNet CIDR | `10.0.0.0/16` |
| `hub_vnet_address_space` | Hub VNet CIDR | `10.1.0.0/16` |
| `spoke_app_vnet_address_space` | Spoke VNet CIDR | `10.2.0.0/16` |
| `dmz_frontdoor_subnet_address_prefix` | Front Door subnet | `10.0.1.0/24` |
| `hub_firewall_subnet_address_prefix` | Hub firewall subnet | `10.1.1.0/24` |
| `app_subnet_address_prefix` | App integration subnet | `10.2.1.0/24` |
| `pe_subnet_address_prefix` | Private endpoints subnet | `10.2.2.0/24` |

#### Application Services

| Variable | Description | Default |
|----------|-------------|---------|
| `environment_prefix` | Environment name | `dev` |
| `workload` | Workload identifier | `webapp` |
| `location` | Azure region | `eastus` |
| `app_service_sku` | App Service SKU | `P1v3` |
| `frontdoor_sku_name` | Front Door SKU | `Premium_AzureFrontDoor` |
| `waf_mode` | WAF mode | `Prevention` |

### Resource Naming Convention

Resources follow: `<type>-<workload>-<environment>-<suffix>`

Examples:
- Resource Group: `rg-webapp-dev-a1b`
- App Service: `app-webapp-dev-a1b`
- Hub VNet: `vnet-hub-webapp-dev-a1b`
- Front Door: `fd-webapp-dev-a1b`

## 📤 Outputs

After deployment, these outputs are available:

### Main Application Access
- `front_door_url` - **Use this URL to access the application**
- `front_door_endpoint_hostname` - Front Door endpoint hostname

### Infrastructure Details
- `resource_group_name` - Resource group name
- `app_service_name` - App Service name (private, not directly accessible)
- `vnet_dmz_name` - DMZ VNet name
- `vnet_hub_name` - Hub VNet name
- `vnet_spoke_app_name` - Spoke App VNet name

View all outputs:

```bash
terraform output
```

## 🌐 Network Architecture Diagram

```
                              Internet
                                 │
                                 ▼
                     ┌───────────────────────┐
                     │  Azure Front Door     │
                     │  (Global, with WAF)   │
                     └───────────┬───────────┘
                                 │ Private Link
                                 ▼
                     ┌───────────────────────┐
                     │    DMZ VNet           │
                     │    10.0.0.0/16        │
                     │                       │
                     │  ┌─────────────────┐  │
                     │  │ Front Door      │  │
                     │  │ Subnet          │  │
                     │  │ 10.0.1.0/24     │  │
                     │  └─────────────────┘  │
                     └───────────┬───────────┘
                                 │ VNet Peering
                                 ▼
                     ┌───────────────────────┐
                     │    Hub VNet           │
                     │    10.1.0.0/16        │
                     │  (Central Hub)        │
                     │                       │
                     │  ┌─────────────────┐  │
                     │  │ Firewall        │  │
                     │  │ Subnet          │  │
                     │  │ 10.1.1.0/24     │  │
                     │  └─────────────────┘  │
                     │                       │
                     │  Private DNS Zones    │
                     └───────────┬───────────┘
                                 │ VNet Peering
                                 ▼
                     ┌───────────────────────┐
                     │  Spoke App VNet       │
                     │  10.2.0.0/16          │
                     │                       │
                     │  ┌─────────────────┐  │
                     │  │ App Service     │  │
                     │  │ Integration     │  │
                     │  │ 10.2.1.0/24     │  │
                     │  └────────┬────────┘  │
                     │           │           │
                     │  ┌────────▼────────┐  │
                     │  │ Private         │  │
                     │  │ Endpoints       │  │
                     │  │ 10.2.2.0/24     │  │
                     │  │                 │  │
                     │  │ ┌─────────────┐ │  │
                     │  │ │ App Service │ │  │
                     │  │ │ (Private)   │ │  │
                     │  │ └─────────────┘ │  │
                     │  └─────────────────┘  │
                     └───────────────────────┘
```


## 🔧 Module Usage

Each module follows a consistent pattern:

### Module Inputs
```hcl
module "example" {
  source = "../modules/azurerm/<resource>"
  
  name                = "resource-name"
  resource_group_name = "rg-name"
  location            = "eastus"
  tags                = { Environment = "dev" }
  
  # Resource-specific properties
}
```

### Module Outputs
```hcl
output "id" { value = azurerm_<resource>.main.id }
output "name" { value = azurerm_<resource>.main.name }
# Additional resource-specific outputs
```

## 🎯 Next Steps

1. **Deploy Application Code**
   - Use Azure CLI or CI/CD pipeline
   - Deploy to the App Service

2. **Configure SSL/TLS**
   - Add SSL certificate to Application Gateway
   - Configure custom domain

3. **Set Up Monitoring**
   - Enable Application Insights
   - Configure Azure Monitor alerts

4. **Implement CI/CD**
   - GitHub Actions or Azure DevOps
   - Automated deployments

5. **Enhance Security**
   - Enable WAF on Application Gateway
   - Configure Azure Key Vault for secrets
   - Implement managed identities

## 🧹 Cleanup

To destroy all resources:

```bash
cd terraform/environments/dev
terraform destroy
```

Type `yes` to confirm. This will remove all resources in the resource group.

## 🐛 Troubleshooting

### Common Issues

**App Service can't connect to SQL**
- Verify Private Endpoint is healthy
- Check DNS resolution: `nslookup <sql-server>.database.windows.net`
- Ensure `WEBSITE_VNET_ROUTE_ALL=1` is set

**Application Gateway health probe failing**
- Check App Service is running
- Verify backend pool FQDN
- Review probe configuration (protocol, path, timeout)

**Terraform init fails**
- Verify Terraform version >= 1.0
- Check internet connectivity
- Clear `.terraform` directory and retry

**Deployment timeout**
- Application Gateway takes 15-20 minutes
- Be patient, monitor Azure Portal for progress


## 📚 Additional Resources

- [Azure App Service Documentation](https://docs.microsoft.com/azure/app-service/)
- [Application Gateway Documentation](https://docs.microsoft.com/azure/application-gateway/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
