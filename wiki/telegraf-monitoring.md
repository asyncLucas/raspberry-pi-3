# Steps to Set Up a systemd Service for Telegraf with InfluxDB:
 
## 1.⁠ ⁠Create a Script to Run Telegraf:
 
First, create a script that runs the telegraf command to fetch configuration from the InfluxDB API.
 
```shell
sudo vim /usr/local/bin/telegraf-monitor.sh
```
 
Add the following content to the script:
 
```shell
#!/bin/bash
### Set environment variables
export INFLUX_HOST=http://<you_ip>:8086
export INFLUX_TOKEN=<your_api_token_here>
export INFLUX_ORG=<your_organization>

# Run Telegraf with the config URL
telegraf --config $INFLUX_HOST/api/v2/telegrafs/<setup Start Telegraf>
```
Replace `your_api_token_here` with your actual InfluxDB API token.
 
Save and exit (CTRL + X, then Y, and press Enter).
 
## 2.⁠ ⁠Make the Script Executable:
 
Change the permissions on the script to make it executable:
 
```shell
sudo chmod +x /usr/local/bin/telegraf-monitor.sh
```

## 3.⁠ ⁠Create the systemd Service File:
 
Now, create a systemd service file to run this script in the background.
 
```shell
sudo nano /etc/systemd/system/telegraf-monitor.service
```

Add the following content to the service file:

```shell
[Unit]
Description=Telegraf Monitoring Service
After=network.target
 
[Service]
Environment="INFLUX_HOST=http://<your_ip>:8086"
Environment="INFLUX_TOKEN=<your_api_token_here>"
Environment="INFLUX_ORG=<your_organization>"
ExecStart=/usr/local/bin/telegraf-monitor.sh
Restart=always
User=root
 
[Install]
WantedBy=multi-user.target

```
 
Replace `your_api_token_here` with your actual InfluxDB API token.
 
## 4.⁠ ⁠Reload systemd and Enable the Service:
 
Reload systemd to apply the changes and enable the service to start on boot:

```shell
sudo systemctl daemon-reload
sudo systemctl enable telegraf-monitor.service
```
 
## 5.⁠ ⁠Start the Service:
 
Start the Telegraf monitoring service:
 
```shell
sudo systemctl start telegraf-monitor.service
```
 
## 6.⁠ ⁠Verify the Service:
 
Check the status to ensure the service is running:
 
```shell
sudo systemctl status telegraf-monitor.service
```

## 6. Check logs of the service
You can check the logs of your `telegraf-monitor.service` using `journalctl`. Here are some useful commands:

### 1️⃣ **View Recent Logs**
```bash
journalctl -u telegraf-monitor.service --no-pager --lines=50
```
- `-u telegraf-monitor.service` → Filters logs only for this service.
- `--no-pager` → Prevents scrolling, useful for small outputs.
- `--lines=50` → Shows the last 50 lines.

---

### 2️⃣ **Follow Live Logs (Real-Time)**
```bash
journalctl -u telegraf-monitor.service -f
```
This works like `tail -f`, displaying new logs as they appear.

---

### 3️⃣ **View Logs for a Specific Date**
Example: Logs from today:
```bash
journalctl -u telegraf-monitor.service --since today
```
Or a custom range:
```bash
journalctl -u telegraf-monitor.service --since "2025-02-28 10:00:00" --until "2025-02-28 16:00:00"
```

---

### 4️⃣ **Check the Last Restart Logs**
```bash
journalctl -xe -u telegraf-monitor.service
```
- `-xe` → Shows extra details and errors.

---

### 5️⃣ **Check Logs from Boot**
To see what happened when the system started:
```bash
journalctl -u telegraf-monitor.service --boot
```

---

### 6️⃣ **If Service Fails on Startup**
If your service fails right after boot, check logs from the last boot:
```bash
journalctl -u telegraf-monitor.service --boot -1
```

---

### 🔥 **Bonus: If Logs Are Too Long**
To filter only errors:
```bash
journalctl -u telegraf-monitor.service | grep -i "error"
```

---

