@allowed([
  'eastus'
  'westus'
])
param  location string = 'eastus'

@minLength(4)
@maxLength(7)

param  part string 

var name = '${part}res'

resource storageaccount 'Microsoft.Storage/storageAccounts@2021-02-01' ={

  name: 'st899${name}
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}
