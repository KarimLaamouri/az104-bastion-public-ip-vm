param location string
param vmName string
@secure()
param adminUsername string
@secure()
param adminPassword string

module network './modules/network.bicep' = {
	params: {
		location: location
	}
}

module vm './modules/vm.bicep' = {
	params: {
		location: location
		vmName: vmName
		adminUsername: adminUsername
		adminPassword: adminPassword
		subnetId: network.outputs.vmSubnetId
	}
}

module bastion './modules/bastion.bicep' = {
	params: {
		location: location
		bastionSubnetId: network.outputs.bastionSubnetId
	}
}


