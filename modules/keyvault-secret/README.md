# keyvault-secret

A terraform module to provide Key Vaults secrets for existing Key Vaults in Azure with the following characteristics:

- Secrets have a name that identifies them in the URL/ID
- Secrets have a secret value that gets encrypted and protected by the key vault

## Usage

Key Vault secret usage example:

```
module "resource_group" {
  source = "github.com/danielscholl/iac-terraform/modules/resource-group"

  name     = "iac-terraform"
  location = "eastus2"
}

module "keyvault" {
  source              = "github.com/danielscholl/iac-terraform/modules/keyvault"
  name                = "iac-terraform-kv-${module.resource_group.random}"
  resource_group_name = module.resource_group.name
}

module "keyvault_secret" {
  source               = "github.com/danielscholl/iac-terraform/modules/keyvault-secret"
  keyvault_id          = module.keyvault.id
  secrets              = {
    "iac": "terraform"
  }
}
```

## Inputs

| Variable                      | Default                              | Description                          | 
| ----------------------------- | ------------------------------------ | ------------------------------------ |
| keyvault_id                   | _(Required)_                         | Id of the Key Vault to store the secret in.  |
| secrets                       | __(Object)__                         | Key/value pair of keyvault secret names and corresponding secret value. |

> __secrets__
```
The secrets object produces a list of secrets to be added.

{
  jedi = "master"
}
```

## Variables Reference

The following variables are used:

- `secrets`: A map of Key Vault Secrets. The Key/Value association is the KeyVault secret name and value.
- `keyvault_id`: The id of the Key Vault.

## Attributes Reference

The following attributes are exported:

- `secrets`: A mapping of secret names and URIs.
- `references`: A mapping of Key Vault references for App Service and Azure Functions.
