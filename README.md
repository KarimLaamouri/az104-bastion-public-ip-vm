# Azure Modular Infrastructure

This repository provides a clean, modular approach to deploying an Azure environment using Bicep. It sets up a Virtual Network with subnets, a Windows Virtual Machine, and an Azure Bastion host for secure access.

## Architecture

- **Network Module:** Provisions the VNet and required subnets.
- **Compute Module:** Handles the Virtual Machine and its Network Interface.
- **Bastion Module:** Deploys the Bastion host and its associated Public IP.
- **Main Orchestrator:** Connects the modules, passing outputs (like Subnet IDs) between them to ensure correct dependency ordering.

## Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed.
- An active Azure Subscription.
- VS Code with Bicep extension installed.

## Setup Instructions

1. **Login to Azure:**
   ```bash
   az login
   ```

2. **Set your target subscription:**
   ```bash
   az account set --subscription "<Your-Subscription-ID>"
   ```

3. **Configure Parameters:**
   - Locate the `params/` folder.
   - You will find a `template.params` file which serves as a schema.
   - **Important:** Create a copy of this file and rename the extension to `.bicepparam` (e.g., `deployment.bicepparam`).
   - Open your new `deployment.bicepparam` file and update the values (admin username, password, etc.) with your specific details.
   - **Note:** This file is ignored by Git to ensure your credentials remain local and secure.

4. **Deploy the Infrastructure:**
   Run the following command from the root of the repository:
   ```bash
   az deployment group create \
     --resource-group <Your-Resource-Group-Name> \
     --template-file main.bicep \
     --parameters params/deployment.bicepparam
   ```

## Scripts

To simplify deployment and cleanup, this repository includes PowerShell scripts under `scripts/`.

### Deploy Script

Use `scripts/deploy.ps1` to deploy `main.bicep` with `params/deployment.bicepparam` and capture deployed resource IDs for cleanup.

```powershell
pwsh -File scripts/deploy.ps1 -ResourceGroupName <Your-Resource-Group-Name>
```

Optional parameters:
- `-SubscriptionId <Your-Subscription-ID>`
- `-DeploymentName <Custom-Deployment-Name>`
- `-TemplateFile <Template-Path>` (default: `main.bicep`)
- `-ParameterFile <Parameter-Path>` (default: `params/deployment.bicepparam`)

After a successful deployment, the script writes a manifest to `scripts/last-deployment-resources.json`.

### Remove Script

Use `scripts/remove.ps1` to delete resources from the last deployment (using deployment operations or the manifest fallback).

```powershell
pwsh -File scripts/remove.ps1 -ResourceGroupName <Your-Resource-Group-Name>
```

Optional parameters:
- `-DeploymentName <Deployment-Name>`
- `-SubscriptionId <Your-Subscription-ID>`
- `-ManifestFile <Manifest-Path>` (default: `scripts/last-deployment-resources.json`)
- `-DeleteResourceGroup` (deletes the entire resource group)

## Repository Structure

```plaintext
.
├── modules/
│   ├── network.bicep       # VNet & Subnet definitions
│   ├── vm.bicep            # VM & NIC configuration
│   └── bastion.bicep       # Bastion Host & Public IP
├── params/
│   └── template.params     # Template for configuration
├── scripts/
│   ├── deploy.ps1          # Deploys resources and writes deployment manifest
│   └── remove.ps1          # Removes deployed resources or deletes the resource group
├── main.bicep              # Orchestrator: links modules together
├── .gitignore              # Excludes sensitive files (*.bicepparam)
└── README.md
```

## Security Note

This project uses `@secure()` parameters for credentials. Always ensure your `.bicepparam` files are listed in your `.gitignore` to prevent sensitive information from being pushed to version control.