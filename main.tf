terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {}
  # Subscription comes from `az login` / ARM_SUBSCRIPTION_ID, or var.subscription_id
  subscription_id = var.subscription_id
}

# ---------- Shared platform ----------
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${var.prefix}-logs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_app_environment" "env" {
  name                       = "${var.prefix}-env"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id
}

# ---------- Product API ----------
resource "azurerm_container_app" "product" {
  name                         = "${var.prefix}-product"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    min_replicas = 0
    max_replicas = 3

    container {
      name   = "product-service"
      image  = "docker.io/${var.dockerhub_user}/product-service:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "PORT"
        value = "3001"
      }
    }
  }

  ingress {
    external_enabled = true # the browser calls this API directly
    target_port      = 3001
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# ---------- Order API ----------
resource "azurerm_container_app" "order" {
  name                         = "${var.prefix}-order"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    min_replicas = 0
    max_replicas = 3

    container {
      name   = "order-service"
      image  = "docker.io/${var.dockerhub_user}/order-service:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "PORT"
        value = "3002"
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 3002
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}

# ---------- React frontend ----------
# Gets the API URLs from the other apps' outputs, so Terraform creates it last.
resource "azurerm_container_app" "frontend" {
  name                         = "${var.prefix}-frontend"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  template {
    min_replicas = 0
    max_replicas = 3

    container {
      name   = "frontend"
      image  = "docker.io/${var.dockerhub_user}/frontend:${var.image_tag}"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "PRODUCT_API_URL"
        value = "https://${azurerm_container_app.product.ingress[0].fqdn}"
      }
      env {
        name  = "ORDER_API_URL"
        value = "https://${azurerm_container_app.order.ingress[0].fqdn}"
      }

      # Optional feature flag: the coupon box appears only when a coupon API URL is given.
      dynamic "env" {
        for_each = var.coupon_api_url == "" ? [] : [var.coupon_api_url]
        content {
          name  = "COUPON_API_URL"
          value = env.value
        }
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
}
