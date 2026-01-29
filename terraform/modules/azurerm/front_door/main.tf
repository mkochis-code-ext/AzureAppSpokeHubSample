resource "azurerm_cdn_frontdoor_profile" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  tags                = var.tags
}

resource "azurerm_cdn_frontdoor_endpoint" "main" {
  name                     = "${var.name}-endpoint"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id
  tags                     = var.tags
}

resource "azurerm_cdn_frontdoor_origin_group" "main" {
  name                     = "${var.name}-origin-group"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  load_balancing {
    sample_size                        = 4
    successful_samples_required        = 3
    additional_latency_in_milliseconds = 50
  }

  health_probe {
    protocol            = "Https"
    request_type        = "HEAD"
    interval_in_seconds = 100
    path                = var.health_probe_path
  }
}

resource "azurerm_cdn_frontdoor_origin" "main" {
  name                          = "${var.name}-origin"
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  enabled                       = true

  certificate_name_check_enabled = true
  host_name                      = var.backend_hostname
  http_port                      = 80
  https_port                     = 443
  origin_host_header             = var.backend_hostname
  priority                       = 1
  weight                         = 1000

  private_link {
    request_message        = "Request access for Private Link Origin from Front Door"
    target_type            = "sites"
    location               = var.backend_location
    private_link_target_id = var.backend_resource_id
  }
}

resource "azurerm_cdn_frontdoor_route" "main" {
  name                          = "${var.name}-route"
  cdn_frontdoor_endpoint_id     = azurerm_cdn_frontdoor_endpoint.main.id
  cdn_frontdoor_origin_group_id = azurerm_cdn_frontdoor_origin_group.main.id
  cdn_frontdoor_origin_ids      = [azurerm_cdn_frontdoor_origin.main.id]
  enabled                       = true

  forwarding_protocol    = "HttpsOnly"
  https_redirect_enabled = true
  patterns_to_match      = ["/*"]
  supported_protocols    = ["Http", "Https"]

  cdn_frontdoor_custom_domain_ids = []
  link_to_default_domain          = true
}

resource "azurerm_cdn_frontdoor_security_policy" "main" {
  name                     = "${var.name}-security-policy"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.main.id

  security_policies {
    firewall {
      cdn_frontdoor_firewall_policy_id = var.waf_policy_id
      association {
        domain {
          cdn_frontdoor_domain_id = azurerm_cdn_frontdoor_endpoint.main.id
        }
        patterns_to_match = ["/*"]
      }
    }
  }
}

# Approve Private Link connection automatically
# Note: This requires a sleep to allow Azure to create the pending connection
resource "null_resource" "approve_private_link" {
  triggers = {
    origin_id              = azurerm_cdn_frontdoor_origin.main.id
    private_link_target_id = var.backend_resource_id
  }

  provisioner "local-exec" {
    command     = <<-EOT
      Start-Sleep -Seconds 30
      $targetId = "${var.backend_resource_id}"
      $parts = $targetId -split '/'
      $rgName = $parts[4]
      $appName = $parts[8]
      Write-Host "Looking for pending Private Link connection on $appName..."
      $connections = az network private-endpoint-connection list --name $appName --resource-group $rgName --type Microsoft.Web/sites --query "[?properties.privateLinkServiceConnectionState.status=='Pending'].name" -o tsv
      foreach ($conn in $connections) {
        Write-Host "Approving connection: $conn"
        az network private-endpoint-connection approve --name $conn --resource-group $rgName --resource-name $appName --type Microsoft.Web/sites --description "Auto-approved by Terraform"
      }
      Write-Host "Private Link approval complete for $appName"
    EOT
    interpreter = ["PowerShell", "-Command"]
  }

  depends_on = [azurerm_cdn_frontdoor_origin.main]
}
