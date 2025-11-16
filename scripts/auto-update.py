import subprocess

# Update and upgrade the system
def run_update():
    subprocess.run(["sudo", "apt", "update"])
    subprocess.run(["sudo", "apt", "upgrade", "-y"])

run_update()