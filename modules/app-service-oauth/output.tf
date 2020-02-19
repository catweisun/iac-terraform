output "uris" {
  description = "The URLs of the app services created"
  value       = azurerm_app_service.main.*.default_site_hostname
}

output "ids" {
  description = "The resource ids of the app services created"
  value       = azurerm_app_service.main.*.id
}

output "names" {
  description = "The names of the app services created"
  value = [
    for name in keys(var.app_service_config) :
    "${var.name}-${lower(name)}"
  ]
}

output "config_data" {
  description = "A list of app services paired with their fqdn and slot settings."
  value = [
    for i in range(length(data.azurerm_app_service.all)) :
    {
      slot_short_name = azurerm_app_service_slot.staging.*.name[i]
      slot_fqdn       = azurerm_app_service_slot.staging.*.default_site_hostname[i]
      app_name        = azurerm_app_service_slot.staging.*.app_service_name[i]
      app_fqdn = coalesce([for app in data.azurerm_app_service.all :
      app.name == azurerm_app_service_slot.staging.*.app_service_name[i] ? app.default_site_hostname : ""]...)
    }
  ]
}


output "identity_tenant_ids" {
  description = "The Tenant ID for the Service Principal associated with the Managed Service Identity of this App Service."
  value       = azurerm_app_service.main.*.identity.0.tenant_id
}

output "identity_object_ids" {
  description = "The Principal IDs for the Service Principal associated with the Managed Service Identity for all App Services."
  value       = azurerm_app_service.main.*.identity.0.principal_id
}
