terraform {
  backend "azurerm" {
    resource_group_name   = "TerraformStateResourceGroup"
    storage_account_name  = "terraformstatestorageacc"
    container_name        = "tfstate"
    key                   = "terraform.tfstate"
  }
}

