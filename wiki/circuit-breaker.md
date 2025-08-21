# How to Configure the Cron Job Circuit Breaker
The cron service is a daemon that runs continuously on your system. It reads its schedule from a file called the crontab. Jobs added to your user's crontab will automatically run at the specified times, and this schedule persists across system reboots.

> Save the Script: Make sure the Python script is saved to a file, for example, /usr/local/bin/check_and_reboot.py.

Open Crontab: Open your user's crontab for editing by running the following command in your terminal.

```shell
crontab -e
```

Add the Job: Add the following line to the crontab file.

```shell
*/5 * * * * python3 /usr/local/bin/check_and_reboot.py >> /var/log/circuit_breaker.log 2>&1
```

### This configuration does two important things:

- Persistence: The cron daemon will read this line every time the system starts up, ensuring the script is scheduled to run every 5 minutes automatically.

- Logging: The `>> /var/log/circuit_breaker.log 2>&1` part redirects all output from the script, including both standard output and any errors, to the `/var/log/circuit_breaker.log` file. This lets you review the logs to see exactly when the script ran and what it did.

By setting up the job this way, you'll have a robust, self-restarting service that will keep your Raspberry Pi accessible even when a process is causing it to slow down

## Raspberry Pi Circuit Breaker Script

```python
import os
import psutil
import datetime
import subprocess

# --- Configuration ---
# Set the maximum acceptable 15-minute load average.
# A good starting point is the number of CPU cores.
# A Raspberry Pi 4 has 4 cores.
# Adjust this value based on your specific needs.
LOAD_THRESHOLD = 3.2 # Changed to 80% as discussed

# --- Get the current 15-minute load average ---
# psutil.getloadavg() returns a tuple of (1-min, 5-min, 15-min) load averages.
load_avg_15_min = psutil.getloadavg()[2]

# --- Get the current time for logging ---
now = datetime.datetime.now()
timestamp = now.strftime("%Y-%m-%d %H:%M:%S")

# --- Log the current load average ---
# This print statement will be captured in the log file by cron.
print(f"[{timestamp}] Current 15-minute load average: {load_avg_15_min}")

# --- Check if the load average exceeds the threshold ---
if load_avg_15_min > LOAD_THRESHOLD:
    print(f"[{timestamp}] Load average {load_avg_15_min} is above the threshold {LOAD_THRESHOLD}.")

    # --- Stop all containers except Portainer ---
    print(f"[{timestamp}] Stopping all containers except Portainer.")
    try:
        result = subprocess.run(['sudo', 'docker', 'ps', '-q'], capture_output=True, text=True, check=True)
        container_ids = result.stdout.strip().split('\n')
    except subprocess.CalledProcessError as e:
        print(f"[{timestamp}] Error getting container list: {e}")
        container_ids = []

    for container_id in container_ids:
        try:
            name_result = subprocess.run(['sudo', 'docker', 'inspect', '--format', '{{.Name}}', container_id], capture_output=True, text=True, check=True)
            container_name = name_result.stdout.strip().lstrip('/')
            
            if container_name.lower() == 'portainer':
                print(f"[{timestamp}] Skipping Portainer container: {container_id}")
                continue
            
            print(f"[{timestamp}] Stopping container {container_name} ({container_id})...")
            stop_result = subprocess.run(['sudo', 'docker', 'stop', '-f', container_id], check=True)
            print(f"[{timestamp}] Container {container_name} stopped successfully.")
            
        except subprocess.CalledProcessError as e:
            print(f"[{timestamp}] Error stopping container {container_id}: {e}")
    
    # --- Clear the Linux memory caches to free up RAM ---
    print(f"[{timestamp}] Clearing system memory caches...")
    try:
        # The 'sync' command writes buffered data to disk.
        subprocess.run(['sync'], check=True)
        # The 'echo 3 > /proc/sys/vm/drop_caches' command clears all caches.
        subprocess.run(['sudo', 'sh', '-c', 'echo 3 > /proc/sys/vm/drop_caches'], check=True)
        print(f"[{timestamp}] Memory caches cleared successfully.")
    except subprocess.CalledProcessError as e:
        print(f"[{timestamp}] Error clearing memory caches: {e}")
    
else:
    print(f"[{timestamp}] System load is stable. No action required.")

```