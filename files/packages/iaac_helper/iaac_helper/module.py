import yaml # PyYaml
import subprocess

# Color string
#
def cprint(output: str, color: str) -> str:
    colors = {
        "red": 31,
        "green": 32,
        "yellow": 33,
        "bleu": 34,
        "magenta": 35,
        "cyan": 36,
        "white": 37
    }
    msg = f"\033[{ colors[color] };5m{ output }\033[0m"
    print(msg)
    return msg 

# Get Yaml file
#
def get_yaml(filename: str):
    try:
        with open(filename, "r") as file:
            result = yaml.safe_load(file)
    except Exception as exc:
        raise Exception(cprint(
            f"ERROR - get_yaml() - Failed to get yaml '{ filename }'. Exception: { exc }", "red"
        ))
    return result

# Run shell command
#
def run_shell(cmd: str, output_return: bool = False, output_print: bool = False) -> str:
    capture_output = True
    if output_return == False and output_print == False:
        capture_output = False
    try:
        result = subprocess.run(
            cmd, shell = True, capture_output = capture_output, text = True
        )
    except Exception as exc:
        raise Exception(cprint(
            f"ERROR - run_shell() - Command: { cmd } Exception: { exc }", "red"
        ))
    if output_print == True:
        cprint(f"Output: { result.stdout }", "cyan")
    if result.returncode != 0:
        raise Exception(cprint(
            f"Wrong code { result.returncode } - Command '{ cmd }' - run_shell()", "red"
        ))
    if output_return == True:
        return result.stdout
    return None
