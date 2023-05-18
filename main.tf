resource "aws_eip" "aviatrix_gateway_eip" {
    provider = aws.china
    vpc      = true

  lifecycle {
    create_before_destroy = true
    ignore_changes = all
  }

  tags = merge(
    {
    Name                 = format("%s-eip", var.gateway_name)
    avx-gw-association   = format("%s-gw", var.gateway_name)
    avx-created-resource = "DO-NOT-DELETE"
  },
  var.tags
  )
}

resource "aws_eip" "aviatrix_gateway_ha_eip" {
  count     = var.ha_enabled ? 1 : 0  
  provider  = aws.china
  vpc       = true

  lifecycle {
    create_before_destroy = true    
    ignore_changes = all
  }

  tags = merge(
    {
    Name                 = format("%s-hagw-eip", var.gateway_name)
    avx-gw-association   = format("%s-hagw", var.gateway_name)
    avx-created-resource = "DO-NOT-DELETE"
  },
  var.tags
  )
}

resource "azurerm_network_security_rule" "avx_controller_allow_gw" {
  provider                    = azurerm.controller
  name                        = format("aws-avx-%sgw", var.gateway_name)
  resource_group_name         = var.controller_nsg_resource_group_name
  network_security_group_name = var.controller_nsg_name
  access                      = "Allow"
  direction                   = "Inbound"
  priority                    = var.controller_nsg_rule_priority
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefixes     = local.gateway_address
  destination_address_prefix  = "*"
  description                 = "Allow access to AWS Avaitrix Gateways ${var.gateway_name} and ${var.gateway_name}-hagw"
}