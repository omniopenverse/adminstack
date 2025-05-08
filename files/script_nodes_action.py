import os
import ansible_runner
from iaac_helper.module import cprint, get_yaml

# # Current and Parent working directories
# #
# CWD                 = os.path.dirname(os.path.realpath(__file__))
# PWD                 = os.path.abspath(os.path.join(CWD, os.pardir))

# Ansible files 
#
CLUSTER             = os.getenv("CLUSTER", default = None)
PLAYBOOK            = os.getenv("PLAYBOOK", default = None)
INVENTORY           = os.getenv("INVENTORY", default = None)

# Environemnt variables
#
CLICMD              = os.getenv("clicmd", default = "status")
NODES_SELECTOR      = os.getenv("nodes_selector", default = None)

# Run playbook
#
def run_playbook(host: str, extra_vars: dict, nodes_selector: str = None):
    extra_vars["host"] = host
    extra_vars["clicmd"] = CLICMD
    if nodes_selector != None:
        extra_vars["nodes_selector"] = nodes_selector.split(",")
    try:
        r = ansible_runner.run(
            inventory = INVENTORY,
            extravars = extra_vars,
            playbook = PLAYBOOK,
            suppress_env_files = True,
            quiet = False,
            artifact_dir = None
        )
        cprint("{}: {}".format(r.status, r.rc), "magenta")
    except Exception as exc:
        raise Exception(cprint(
            f"Run playbook failed for host: { host }. Exception { exc }", "red"
        ))
    return

# Check if a node name is present in the vnodes of a machine
#
def is_node_in_vnodes(node: str, extra_vars: dict, machine_name: str) -> bool:
    if "vnodes" not in extra_vars:
        cprint(
            f"vnodes not supplied for '{ machine_name }'.", "yellow"
        )
        return False
    vnodes = extra_vars["vnodes"]
    for vnode in vnodes:
        if vnode["NAME"] == node:
            return True
    return False

# Main function
#
def main():
    machines_extra_vars = get_yaml(CLUSTER)
    for machine_name, extra_vars in machines_extra_vars.items():
        if NODES_SELECTOR != None:
            if is_node_in_vnodes(NODES_SELECTOR, extra_vars, machine_name) == True:
                run_playbook(machine_name, extra_vars, NODES_SELECTOR)
            else:
                cprint(
                    f"Node: '{ NODES_SELECTOR }' not in machine: '{ machine_name }'",
                    "yellow"
                )
        else:
            run_playbook(machine_name, extra_vars)
    return 0

if __name__ == '__main__':
    exit(main())
