param(
    [string]$ResourceGroupName,

    [string]$DeploymentName,

    [string]$SubscriptionId,

    [string]$ManifestFile = "scripts/last-deployment-resources.json",

    [switch]$DeleteResourceGroup
)

$ErrorActionPreference = 'Stop'

function Assert-AzCli {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) is not installed or not in PATH."
    }
}

function Get-ManifestData {
    param([string]$Path)

    if (-not (Test-Path -Path $Path)) {
        return $null
    }

    try {
        return Get-Content -Path $Path -Raw | ConvertFrom-Json
    }
    catch {
        throw "Failed to parse manifest file '$Path'."
    }
}

Assert-AzCli

if ($SubscriptionId) {
    Write-Host "Setting subscription to '$SubscriptionId'..."
    az account set --subscription $SubscriptionId | Out-Null
}

$manifest = Get-ManifestData -Path $ManifestFile

if (-not $ResourceGroupName -and $manifest) {
    $ResourceGroupName = $manifest.resourceGroupName
}

if (-not $DeploymentName -and $manifest) {
    $DeploymentName = $manifest.deploymentName
}

if (-not $ResourceGroupName) {
    throw "ResourceGroupName is required. Provide -ResourceGroupName or use a valid manifest file."
}

if ($DeleteResourceGroup) {
    Write-Host "Deleting resource group '$ResourceGroupName'..."
    az group delete --name $ResourceGroupName --yes
    Write-Host "Resource group delete requested."
    return
}

$resourceIds = @()

if ($DeploymentName) {
    Write-Host "Reading resources from deployment '$DeploymentName' in resource group '$ResourceGroupName'..."
    $resourceIds = az deployment operation group list `
        --resource-group $ResourceGroupName `
        --name $DeploymentName `
        --query "[].properties.targetResource.id" `
        -o tsv | Where-Object { $_ -and $_.Trim() -ne '' } | Select-Object -Unique
}

if ((-not $resourceIds -or $resourceIds.Count -eq 0) -and $manifest -and $manifest.resourceIds) {
    Write-Host "Falling back to resource IDs from manifest file..."
    $resourceIds = @($manifest.resourceIds | Where-Object { $_ -and $_.Trim() -ne '' } | Select-Object -Unique)
}

if (-not $resourceIds -or $resourceIds.Count -eq 0) {
    throw "No resources found to delete. Provide -DeploymentName, use a valid manifest, or use -DeleteResourceGroup."
}

$resourceIds = @($resourceIds)
[array]::Reverse($resourceIds)

Write-Host "Deleting $($resourceIds.Count) resource(s) in reverse order..."

foreach ($id in $resourceIds) {
    Write-Host "Deleting: $id"
    try {
        az resource delete --ids $id | Out-Null
    }
    catch {
        Write-Warning "Failed to delete $id. It may already be removed or have dependent resources."
    }
}

if ($DeploymentName) {
    Write-Host "Attempting to delete deployment record '$DeploymentName'..."
    try {
        az deployment group delete --resource-group $ResourceGroupName --name $DeploymentName | Out-Null
    }
    catch {
        Write-Warning "Could not delete deployment record '$DeploymentName'."
    }
}

Write-Host "Delete workflow completed."