# Aviatrix Controller in Azure China NSG Management for Aviatrix Gateways Deployed in AWS China

## Description

### Note:

This Terraform module automates the creation of NSG rules in the NSG attached to an Aviatrix Controller deployed in Azure China to allow communication with Aviatrix Gateways. This is needed because Avitrix Controllers deployed in Azure China doesn't support Security Group Management; this makes deploying Aviatrix Gateways through automation using Terraform challenging, requiring users to manually add the public IP addresses of the gateways to the NSG attached to the controller before the gateway creation times out.

This Terraform module:

- Is limited to Aviatrix Controller deployed in Azure China and Aviatrix Gateways deployed in AWS China.
- Doesn't create any Aviatrix resources. It is intended to be used in conjunction with [mc-transit](https://registry.terraform.io/modules/terraform-aviatrix-modules/mc-transit/aviatrix/latest), [mc-spoke](https://registry.terraform.io/modules/terraform-aviatrix-modules/mc-spoke/aviatrix/latest) modules, Aviatrix Transit or Spoke gateway resources.
- Supports Azure controller deployment with only 6.7 and above versions.
- Creates one or two Elastic IP addresses to be associated with the gateways.
- Adds a security rule to the existing NSG associated with an Azure Controller deployed in China


## Prerequisites

1. [Terraform v0.13+](https://www.terraform.io/downloads.html) - execute terraform files


## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.52 |


## Procedures for Running this Module

### 1. Authenticating to Azure

Set the environment in Azure CLI to Azure China:

```shell
az cloud set -n AzureChinaCloud
```

Login to the Azure CLI using:

```shell
az login --use-device-code
````
*Note: Please refer to the [documentation](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs#authenticating-to-azure-active-directory) for different methods of authentication to Azure, incase above command is not applicable.*

Pick the subscription you want and use it in the command below.

```shell
az account set --subscription <subscription_id>
```

Set environment variables ARM_ENDPOINT and ARM_ENVIRONMENT to use Azure China endpoints:

  ``` shell
  export ARM_ENDPOINT=https://management.chinacloudapi.cn
  export ARM_ENVIRONMENT=china
  ```

If executing this code from a CI/CD pipeline, the following environment variables are required. The service principal used to authenticate the CI/CD tool into Azure must either have subscription owner role or a custom role that has `Microsoft.Authorization/roleAssignments/write` to be able to succesfully create the role assignments required

``` shell
export ARM_CLIENT_ID="00000000-0000-0000-0000-000000000000"
export ARM_CLIENT_SECRET="00000000-0000-0000-0000-000000000000"
export ARM_SUBSCRIPTION_ID="00000000-0000-0000-0000-000000000000"
export ARM_TENANT_ID="00000000-0000-0000-0000-000000000000"
```

### 2. Applying Terraform configuration

```hcl

provider azurerm {
    alias = "controller"
    // additional configuration
}

provider aws {
    alias = "china"
    // additional configuration goes here
}

module "aws-gateway-nsg" {
  providers = {
    azurerm.controller  = azurerm.controller
    aws.china           = aws.china
  }
  source                                      = "github.com/jocortems/aviatrix_aws_china_gateway_azure_controller_nsg"
  gateway_name                                = "example-gw"                      # Required. This is used to derive the name tag for the EIP that will be used by the Aviatrix Gateway
  tags                = {                                                         # Optional. These tags are only for the public IP addresses that will be created. In addition to the specified tags here the following tags are added {avx-gw-association = format("%s-gw", var.gateway_name), avx-created-resource = "DO-NOT-DELETE"} 
                          user = "jorge",
                          environment = "testing"
                        }
  ha_enabled                                  = true/false                         # Optional. Defaults to true. If set to false only one Public IP address is created and must disable ha_gw when creating Aviatrix spoke or transit gateways              
  controller_nsg_name                         = "controller-nsg"                   # Required. Name of the NSG associated with the Aviatrix Controller
  controller_nsg_resource_group_name          = "controller-nsg-rg"                # Required. Name of the resource group where the NSG associated with the Aviatrix Controller is deployed
  controller_nsg_rule_priority                = 300                                # Required. This number must be unique. Before running this module verify the priority number is available in the NSG associated with the Aviatrix Controller
}


module "mc-transit" {
  source                                      = "terraform-aviatrix-modules/mc-transit/aviatrix"
  version                                     = "2.3.2"
  name                                        = "avx-transit-vnet"
  account                                     = "aws-account"
  cloud                                       = "AWS"
  region                                      = "cn-north-1"
  az_support                                  = false
  gw_name                                     = "example-gw"
  cidr                                        = "172.16.0.0/23"
  allocate_new_eip                            = false
  eip                                         = module.aws-gateway-nsg.eip.public_ip
  ha_eip                                      = module.aws-gateway-nsg.ha_eip.public_ip
}
```

### Execute

```shell
terraform init
terraform apply --var-file=<terraform.tfvars>
````