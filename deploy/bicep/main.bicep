@description('The location of the resource group and the location in which all resurces would be created')
param location string = resourceGroup().location
@description('The resource group name')
param rg_name string = resourceGroup().name 
@description('The vm name hosting the vault')
param vmName string 
@description('The name of the keyvault')
param key_vault_name string 
@description('The name of the key used to open the vault')
param key_name string
@description('The object id of the user executing this bicep')
param userObjId string
@description('The suffix added to all resources to be created')
param suffix string 
@description('The admin username')
param adminUsername string 
@description('The password of admin user')
param adminPassword string 

@description('Specifies the relative path of the script used to initialize the virtual machine. note it is pointing to the raw file')
param scriptFilePath string = 'https://raw.githubusercontent.com/yodobrin/vault/main/deploy/bicep/configure_vault.sh'
@description('Specifies the name of the script to execute')
param scriptName string = 'configure_vault.sh'


// storage for diagniostic 
resource diag_storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: 'akvydsa${suffix}'
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
output ip string = pip.properties.ipAddress
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
  name: 'subnet${suffix}'
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

param vault_version string
param tenantId string = subscription().tenantId
param subscriptionId string = subscription().subscriptionId


// VM - hosting the vault
// created with system assigned identity
// this vm is created with user/pass, you can use ssh key for enhanced security 
resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: '${vmName}${suffix}'
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
      // customData : base64(rendedFile)
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

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = {
  parent: vm
  name: 'CustomScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: false
      timestamp: 123456789
      fileUris: [
        scriptFilePath
      ]
    }    
    protectedSettings: {
      commandToExecute: 'bash ${scriptName} ${vault_version} ${tenantId} ${AKV.outputs.key_vault_name} ${key_name} ${subscriptionId} ${rg_name} ${vmName}'
    }
  }
}

module AKV 'keyvault-rbac.bicep' = {
  name: 'keyVault'
  params: {
    key_vault_name: '${key_vault_name}${suffix}'
    userObjId : userObjId
    key_name: key_name
    location: location
    vmIdentityObjId: vm.identity.principalId
  }
}
