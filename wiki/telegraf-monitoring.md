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
