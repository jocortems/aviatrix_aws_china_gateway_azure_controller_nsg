terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.56.0"
      configuration_aliases = [azurerm.controller]
    }
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.67.0"
      configuration_aliases = [aws.china]
    }
}
}