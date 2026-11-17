output "frontend_url" {
  description = "Open this in the browser"
  value       = "https://${azurerm_container_app.frontend.ingress[0].fqdn}"
}

output "product_api_url" {
  value = "https://${azurerm_container_app.product.ingress[0].fqdn}/api/products"
}

output "order_api_url" {
  value = "https://${azurerm_container_app.order.ingress[0].fqdn}/api/orders"
}
