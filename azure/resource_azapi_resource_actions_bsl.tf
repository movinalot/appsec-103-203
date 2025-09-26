resource "azapi_resource_action" "create_link" {
  type        = "Microsoft.Network/bastionHosts@2022-05-01"
  resource_id = azurerm_bastion_host.bastion_host.id
  action      = "createShareableLinks"
  body = {
    vms = [
      {
        vm = {
          id = azurerm_linux_virtual_machine.client.id
        }
      }
    ]
  }
}

data "azapi_resource_action" "get_link" {
  type                   = "Microsoft.Network/bastionHosts@2022-05-01"
  resource_id            = azurerm_bastion_host.bastion_host.id
  action                 = "getShareableLinks"
  response_export_values = ["*"]
  depends_on             = [azapi_resource_action.create_link]
}

output "bastion_shareable_link" {
  value = data.azapi_resource_action.get_link.output
}