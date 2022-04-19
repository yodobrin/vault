param location string = resourceGroup().location
param user string 
param vmName string 

param suffix string = 'a${uniqueString(resourceGroup().id)}'
param adminUsername string 
param adminPassword string 

param tenantid string 


// storage for diagniostic 
resource diag_storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: 'sa${suffix}'
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}
// Public IP, so it can be reused. 
resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: 'pip${suffix}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Static'    
  }
}

// network security group with required ports open for vault and ssh
resource nsg 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: 'nsg${suffix}'
  location: location      
  properties: {
    securityRules: [
      {
        id: '1000'
        name: 'SSH'
        properties: {
          access: 'Allow'
          description: 'a great description'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'        
          direction: 'Inbound'
          priority: 1000
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        id: '1001'
        name: 'Valut'
        properties: {
          access: 'Allow'
          description: 'another great description'
          destinationAddressPrefix: '*'
          destinationPortRange: '8200'        
          direction: 'Inbound'
          priority: 1002
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
      {
        id: '1002'
        name: 'Consul'
        properties: {
          access: 'Allow'
          description: 'yet another great description'
          destinationAddressPrefix: '*'
          destinationPortRange: '8500'        
          direction: 'Inbound'
          priority: 1001
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
        }
      }
    ]
  }
}
output networkSecurityGroup string = nsg.id
// subnet for the vm
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  parent: vnet
  name: 'sub${suffix}'
  properties: {
    addressPrefix: '10.0.0.0/24'
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}
// Virtual network with one subnet
resource vnet 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'vnet${suffix}'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }        
  }               
}
// Network Interface - used by the VM
resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: 'nic${suffix}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: pip.id
          }
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
  }
}
// VM - hosting the vault
// created with system assigned identity
// this vm is created with user/pass, you can use ssh key for enhanced security 
resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: 'vm${suffix}'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_DS1_v2'
    }
      
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }      
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: diag_storage.properties.primaryEndpoints.blob
      }
    }
  }
}
output vmIdentity string = vm.identity.principalId

param networkAcls object = {
  ipRules: []
  virtualNetworkRules: []
}
param key_vault_name string
// Azure Key Vault
// Created with vault access policies:
// required policy for the vm (wrap/unwrap)
// all key (including purge) for you
resource keyvault 'Microsoft.KeyVault/vaults@2021-10-01' = {
  name: key_vault_name
  location: location
  properties: {
    tenantId: tenantid
    sku: {
      family: 'A'
      name: 'standard'
    }
    accessPolicies: [
      {
        tenantId: tenantid
        objectId: vm.identity.principalId
        permissions: {
          keys: [
            'get'
            'wrapKey'
            'unwrapKey'
          ]                   
        }
      }
      {
        tenantId: tenantid
        objectId: user
        permissions: {
          keys: [
            'all'
            'purge'
          ]                   
        }
      }
    ]
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enableSoftDelete : true
    networkAcls: networkAcls
  }
}


