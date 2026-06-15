param(
    [Parameter(Mandatory = $true)]
    [string]$ResourceGroupName,

    [string]$SubscriptionId,

    [string]$TemplateFile = "main.bicep",

    [string]$ParameterFile = "params/deployment.bicepparam",

    [string]$DeploymentName = "bastion-vm-$(Get-Date -Format 'yyyyMMddHHmmss')"
)

$ErrorActionPreference = 'Stop'

function Assert-AzCli {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) is not installed or not in PATH."
    }
}

Assert-AzCli

if ($SubscriptionId) {
    Write-Host "Setting subscription to '$SubscriptionId'..."
    az account set --subscription $SubscriptionId | Out-Null
}

Write-Host "Validating resource group '$ResourceGroupName'..."
$rgExists = az group exists --name $ResourceGroupName
if ($rgExists -ne 'true') {
    throw "Resource group '$ResourceGroupName' does not exist. Create it first, then rerun this script."
}

Write-Host "Deploying template '$TemplateFile' with parameters '$ParameterFile'..."
az deployment group create `
    --name $DeploymentName `
    --resource-group $ResourceGroupName `
    --template-file $TemplateFile `
    --parameters $ParameterFile

$resourceIds = az deployment operation group list `
    --resource-group $ResourceGroupName `
    --name $DeploymentName `
    --query "[].properties.targetResource.id" `
    -o tsv | Where-Object { $_ -and $_.Trim() -ne '' } | Select-Object -Unique

$manifest = [ordered]@{
    deploymentName = $DeploymentName
    resourceGroupName = $ResourceGroupName
    templateFile = $TemplateFile
    parameterFile = $ParameterFile
    createdAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    resourceIds = @($resourceIds)
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $scriptRoot 'last-deployment-resources.json'
$manifest | ConvertTo-Json -Depth 5 | Set-Content -Path $manifestPath -Encoding UTF8

Write-Host "Deployment complete."
Write-Host "Deployment name: $DeploymentName"
Write-Host "Manifest saved to: $manifestPath"