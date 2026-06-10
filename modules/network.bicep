param location string

var addressPrefix = '10.0.0.0/16'
var vmSubnetPrefix = '10.0.0.0/24'
var bastionSubnetPrefix = '10.0.1.0/24'
var vnetName = 'vnet-vm-bastion'
var vmSubnetName = 'VMSubnet'
var bastionSubnetName = 'AzureBastionSubnet'  // Azure Bastion requires the subnet to be named 'AzureBastionSubnet'


resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
  }
}

resource vmSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: vmSubnetName
  properties: {
    addressPrefix: vmSubnetPrefix
  }
}

resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  parent: vnet
  name: bastionSubnetName
  properties: {
    addressPrefix: bastionSubnetPrefix
  }
}

output vmSubnetId string = vmSubnet.id
output bastionSubnetId string = bastionSubnet.id
