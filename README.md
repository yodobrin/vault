
# Using Hashicorp Vault

## Use case

As an ISVs using Vault for their secret storage, avoiding proprietary use of tools such as Azure KeyVault, or GCP's secret manager, or AWS secret manager and their respective APIs. Instead I want to use the same SDK for my secrets management, and have an underline service control my seal/unseal of the vault.

Using Vault by hashicorp would allow my developers to focus on single set of API calls.

## Credit

This repo was initialy taken from this [GitHub repository](https://github.com/hashicorp/vault). More information can be found ath this [Website](https://www.vaultproject.io).
The original repo was altered to match more recent providers versions and semantics.

While trying to implement the [Quick Start](https://learn.hashicorp.com/tutorials/vault/autounseal-azure-keyvault?in=vault/auto-unseal) it was noticed that dedicated project might be in order.

## Setup

### Terraform user/SPN

If you running this for learning purposes, using your own identity (provided it has contributer role on your subscription) is enough. If you prefer using a service principle for the resource provisioning, please follow the steps 1 through 39 in the [Quick Start](https://learn.hashicorp.com/tutorials/vault/autounseal-azure-keyvault?in=vault/auto-unseal#create-an-azure-service-principal).

In the case your user is enough, make sure to perform:

```azurecli
az login
```

In the case you have multiple subscriptions, you will need to set the right one by using this command:

```azurecli
az account set --subscription <Your Subscription>
```

### Terraform assests & provisioning resources

Clone this repository to your local machine, by running the following command:

```bash
git clone https://github.com/yodobrin/vault
```

Change directory to ```deploy/terraform```.
Then use the provided ```variable.tf``` file for your subscription, by editing it in your IDE. (are you using [VS Code](https://code.visualstudio.com/download)?)

TODO explain more on the sshkey

Once the variable file is updated you will need to run the following commands in sequance:

```bash
terraform init
terraform plan -out hashi-learn.plan
terraform apply "hashi-learn.plan"
```

Post these commands, you should have a new resource group, with the name you specified in the variable file, KeyVault, Virtual Machine and storage account are created. Virtual network, subnet, nsg and rules are also created.

Your newly created resource group should look like this:

![deployments](./media/rg_content.png)

#### KeyVault Access

There are two ways you can allow the vault to access the KeyVault:

- Use dedicated SPN, grant it Get, Wrap & Un-Wrap roles.
- Use System Assigned managed identity of the VM hosting the vault - preffered method.

In this repo, the preffered option is outlined.

Verify that in the newly created KeyVault:

- A key was created (witht the name outlined in the variable file).

- The access policy is allowing you (the user executing terraform) and the system assigned identity Get, Wrap & Unwrap roles.

Examine the KeyVault access policy, it should show something like this:

![policies](./media/akv_policies.png)

### Vault configuration

While the terraform script provision all resources required (and configure them) the final steps are to be executed manually. One of the reasons is to enable the operator to aquire required tokens & recovery keys.
TODO: try to output the keys and token from the script.
TODO: output the url of the vault UI.

The steps are outlined in the [Quick Start](https://learn.hashicorp.com/tutorials/vault/autounseal-azure-keyvault?in=vault/auto-unseal#step-2-test-the-auto-unseal-feature).
For convienient purpose they are also listed here:

1. ssh to the vm ```ssh azureuser@<ip provided as output>```

2. Check the vault status by ```vault status```. You might need to restart the vault service (as it might finishined creation before the key in the keyvault) - ```sudo systemctl restart vault```

3. Initilize the vault ```vault operator init``` this will output 5 recovery keys and an access token required to access the UI, save them.

4. If you need to restart the vault use: ```sudo systemctl restart vault```

5. To check logs you can run: ```sudo journalctl --no-pager -u vault```

Accessing the UI can be done via: http://ip-of-the-vm:8200. Use the token saved earlier to access.

![login to vault](./media/login_to_vault.png)

## Clean Up

Run the following command:

```bash
terraform destroy
```

This will clean all resources provisioned during the apply stage.