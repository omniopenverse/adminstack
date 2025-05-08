import os
import ssh_config
from iaac_helper.module import cprint
from ansible.inventory.manager import InventoryManager
from ansible.parsing.dataloader import DataLoader

# # Current and Parent working directories
# #
# CWD                 = os.path.dirname(os.path.realpath(__file__))
# PWD                 = os.path.abspath(os.path.join(CWD, os.pardir))

# Files and directories
#
INVENTORY           = os.getenv("INVENTORY", default = None)
SSH_CONFIG_FILE     = os.getenv("SSH_CONFIG_FILE", default = None)

def get_hosts_from_inventory_file(inventory_file) -> list[ssh_config.Host]:
    # Initialize DataLoader and VariableManager
    loader = DataLoader()
    # variable_manager = VariableManager()

    # Create InventoryManager and load the inventory file
    inventory = InventoryManager(loader=loader, sources=inventory_file)

    # Get the list of hosts from the inventory
    inventory_hosts = inventory.get_hosts()

    # Extract hostnames and user names from the Host objects
    config_hosts = []
    for host in inventory_hosts:
        # Get ansible_user and ansible_host (if defined) for the host
        config_hosts.append(
            ssh_config.Host(
                host.name, {
                    "User": host.vars.get('ansible_user', None),
                    "HostName": host.vars.get('ansible_host', None)
                }
            )
        )
    return config_hosts

# Main function
#
def main():
    # Get hosts in inventory
    hosts = get_hosts_from_inventory_file(INVENTORY)

    # Create ssh_config object and read existing config file
    config = ssh_config.SSHConfig(SSH_CONFIG_FILE)

    # Loop through inventory hosts and add them in config oject
    for host in hosts:
        if config.exists(host.name):
            config.update(host.name, host.attributes())
        else:
            config.add(host)
    
    # Save the new config
    config.write()
    cprint("SHH Config file synced", "green")
    return 0

if __name__ == '__main__':
    exit(main())
