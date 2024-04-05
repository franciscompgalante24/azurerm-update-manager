# Update Management Center Solution

This Terraform module is intended to implement the Azure Update Manager solution for managing automatic system updates for Azure Virtual Machines https://learn.microsoft.com/en-us/azure/update-center/overview.

## Benefits
1. **Automated System Updates**: Facilitates automatic system updates for Azure Virtual Machines, ensuring systems are always up to date with the latest patches and security improvements.

2. **Supports Various VM Images**: Compatible with Virtual Machines created from both custom and marketplace images, providing flexibility in Azure VM deployments.

3. **Update Management Automation**: Utilizes a PowerShell script to automate update assessments and deployments, streamlining the update process across Virtual Machines within a Resource Group.

## Module Usage
### Virtual Network and Virtual Machine
Create a `terraform.tfvars` file that encompasses configurations for the virtual network and virtual machine. Below is an illustrative example:

```
vnet = {
  name          = "vnet"
  address_space = ["10.0.0.0/16"]
}

subnet = {
  name              = "subnet"
  address_prefixes  = ["10.0.2.0/24"]
  service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
}

nic = {
  name = "nic"
  ip_configuration = {
    name                          = "linux_vm_nic"
    private_ip_address_allocation = "Dynamic"
  }
}

linux_vm = {
  name           = "linux_vm"
  size           = "Standard_D2s_v3"
  admin_username = "adminuser"
  os_disk = {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference = {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}
```

### Installation of Azure Monitor Agent Extension
The following steps ensure the proper installation of the extension. To install the agent and connect it to a monitoring data collection rule, your `terraform.tfvars` file should also include the following main configurations as in this example: 

```
monitor_data_collection_rule_name = "dcr_linux"

monitor_data_collection_rule_association_name = "dcr-linux-vm-association"

monitor_destinations_log_analytics = {
  name = "destination-logs"
}

monitor_data_flow = {
  streams      = ["Microsoft-Syslog"]
  destinations = ["destination-logs"]
}

monitor_data_sources = {
  syslog = {
    name = "syslogs"
    facility_names = ["auth", "authpriv", "cron", "daemon", "mark", "kern",
      "local0", "local1", "local2", "local3", "local4", "local5",
    "local6", "local7", "lpr", "mail", "news", "syslog", "user", "uucp"]
    log_levels = ["Debug"]
  }
}

vm_extension = {
  name                 = "AzureMonitorLinuxAgent"
  publisher            = "Microsoft.Azure.Monitor"
  type                 = "AzureMonitorLinuxAgent"
  type_handler_version = "1.0"
}
```

### Update Center (Automation Account)
Finally, here is an example of the configurations for the automation account that executes the script to perform the update assessment and deployment on your Azure Virtual Machine within your Resource Group.
```
automation_account_name = "automation-account-updates"

automation_runbook_name = "linux-vm-updates-runbook"

automation_schedule = {
  name        = "automatic-linux-vm-updates-schedule"
  description = "Run on Mondays and Wednesdays"
  frequency   = "Week"
  interval    = 1
  timezone    = "Europe/Lisbon"
  week_days   = ["Monday", "Wednesday"]
}
```

## Notes and Possible Errors

During the processes of Update Assessment and Update Deployment and if you have an Ubuntu VM, there is a potential for encountering an error message, 
which may indicate that your virtual machine cannot be assessed or updated. 
If this situation arises, you can verify the specific nature of the error by connecting to your VM and executing the `sudo apt-get update` command.

You may encounter an error message that looks something like this:

```
Err:7 https://packages.gitlab.com/runner/gitlab-runner/ubuntu focal InRelease
The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
Reading package lists... Done
W: An error occurred during the signature verification. The repository is not updated and the previous index files will be used. GPG error: https://packages.gitlab.com/runner/gitlab-runner/ubuntu focal InRelease: The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
W: Failed to fetch https://packages.gitlab.com/runner/gitlab-runner/ubuntu/dists/focal/InRelease  The following signatures couldn't be verified because the public key is not available: NO_PUBKEY 3F01618A51312F3F
W: Some index files failed to download. They have been ignored, or old ones used instead.
```

If you come across this error, modify the `/etc/apt/sources.list.d/runner_gitlab-runner.list` file as shown below:

```
# deb [signed-by=/usr/share/keyrings/runner-gitlab-runner-archive-keyring.gpg] https://packages.gitlab.com/runner/gitlab-runner/ubuntu/ focal main
deb https://packages.gitlab.com/runner/gitlab-runner/ubuntu/ focal main
# deb-src [signed-by=/usr/share/keyrings/runner-gitlab-runner-archive-keyring.gpg] https://packages.gitlab.com/runner/gitlab-runner/ubuntu/ focal main
deb-src https://packages.gitlab.com/runner/gitlab-runner/ubuntu/ focal main
```

Following these steps you should be able to successfully assess and update your VM.

However, if you encounter any errors, I strongly recommend examining the logs within your VM for further insights.

## References

* [Azure Linux VM](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine)
* [Azure Log Analytics Workspace](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace)
* [Azure Update Manager](https://learn.microsoft.com/en-us/azure/update-center/overview?tabs=azure-vms)
* [Azure Automation Account Runbook](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/automation_runbook)
* [Programmatical Management of Updates](https://learn.microsoft.com/en-us/azure/update-center/manage-vms-programmatically?tabs=cli%2Crest)

## Author Information

Francisco Galante
