# Log in to Azure Powershell
Connect-AzAccount -Identity

# Retrieve the resource group names from the Azure Automation variable
$resourceGroupsJson = Get-AutomationVariable -Name 'AutomationAccountRGScope'

# Convert the JSON string back into an array of resource group names
$resourceGroups = $resourceGroupsJson | ConvertFrom-Json

# Iterate over each resource group
foreach ($resourceGroup in $resourceGroups) {
    # Get all VMs in the resource group
    $vms = Get-AzVM -ResourceGroupName $resourceGroup

    # Iterate over each VM
    foreach ($vm in $vms) {
        # Run Azure CLI commands for triggering update assessment and update deployment over each Azure VM
        Invoke-AzVMPatchAssessment -ResourceGroupName $resourceGroup -VMName $vm.Name
        Invoke-AzVmInstallPatch -ResourceGroupName $resourceGroup -VmName $vm.Name -Linux -RebootSetting 'IfRequired' -MaximumDuration PT4H -ClassificationToIncludeForLinux Critical, Security, Other
    }
}
