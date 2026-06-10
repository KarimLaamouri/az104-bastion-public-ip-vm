param location string

var publicIpName = 'pip-bastion'
var bastionHostName = 'bastion-vm'

resource bastionHost 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastionIpConfig'
        properties: {
          subnet: {
            id: network.outputs.bastionSubnetId
          }
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
  }
}

module network 'network.bicep' = {
  name: 'network-deployment'
  params: {
    location: location
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
    name: publicIpName
    location: location
    sku: {
        name: 'Standard'
    } 
    properties: {
        publicIPAllocationMethod: 'Static'
    }
}
