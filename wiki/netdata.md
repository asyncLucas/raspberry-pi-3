# Netdata

### Step 1: Install Dependencies (Optional but Recommended)

First, ensure your system is up-to-date and you have the necessary tools for the installer to work.

```bash
sudo apt update
sudo apt upgrade
sudo apt install wget
```

### Step 2: Install Netdata

Netdata provides a "kickstart" script that automatically handles the installation process, including dependencies, compiling from source, and setting up the service.

Run the following command in your terminal:

```bash
wget -O /tmp/netdata-kickstart.sh https://my-netdata.io/kickstart.sh && sh /tmp/netdata-kickstart.sh
```

During the installation, you'll be prompted to confirm a few things. You can simply press **`Enter`** to accept the default settings, which include:

  * Installing the latest stable version.
  * Enabling automatic updates.
  * Contributing anonymous statistics (you can opt out if you prefer).

The script will take a few minutes to download, compile, and install Netdata on your Raspberry Pi.

### Step 3: Access the Dashboard

Once the installation is complete, Netdata starts automatically. The dashboard is accessible via a web browser on port `19999`.

1.  **Find your Raspberry Pi's IP address:**

    ```bash
    hostname -I
    ```

    This command will output your Pi's IP address. For example, it might be `192.168.1.100`.

2.  **Open the dashboard in your browser:**
    On any device connected to the same network as your Raspberry Pi, open a web browser and navigate to:

    ```
    http://<your_raspberry_pi_ip_address>:19999
    ```

    Replace `<your_raspberry_pi_ip_address>` with the IP address you found in the previous step.

You will immediately be greeted with the real-time Netdata dashboard, showing a vast array of metrics and charts.

### Basic Configuration

While Netdata works out of the box, you might want to make a few quick tweaks. The main configuration file is located at `/opt/netdata/etc/netdata/netdata.conf`.

1.  **Open the configuration file:**

    ```bash
    sudo nano /opt/netdata/etc/netdata/netdata.conf
    ```

2.  **Enable GPU/Temperature Monitoring:**
    By default, some sensors might not be enabled. To enable Raspberry Pi temperature monitoring, you can add or edit the `sensors` line in the `[plugins]` section.

    Find and uncomment or add the following line:

    ```
    sensors=force
    ```

3.  **Restart the service:**
    After making any changes to the configuration, restart the Netdata service to apply them.

    ```bash
    sudo systemctl restart netdata
    ```
