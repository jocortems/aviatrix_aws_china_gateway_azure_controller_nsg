output "eip" {
  value = aws_eip.aviatrix_gateway_eip
}

output "ha_eip" {
  value = var.ha_enabled ? aws_eip.aviatrix_gateway_ha_eip[0] : null
}
