# Local Subdomain Reverse Proxy Setup

This guide provides instructions for configuring local subdomains (e.g., `portainer.server.home`) to access services running on non-standard ports (e.g., 9443) on a remote Ubuntu server ($\text{192.168.1.100}$) via a reverse proxy (Nginx).

## Prerequisites

  * **Server IP:** $\text{192.168.1.100}$ (Ubuntu Server)
  * **Client IP:** $\text{192.168.1.2}$ (macOS Client)
  * **Services:** Portainer (on 9443), Jellyfin (on 8096), Netdata (on 19999) - *All services must be explicitly bound to the server's public IP ($\text{192.168.1.100}$), as determined by your `docker ps` output.*

-----

## Part 1: Configure the macOS Client (The Host File)

The client needs to be told which IP address corresponds to your new subdomains.

1.  **Open the hosts file:**
    On your macOS machine, open the `/etc/hosts` file with administrator privileges:

    ```bash
    sudo nano /etc/hosts
    ```

2.  **Add Subdomain Mappings:**
    Add the following lines, mapping all your desired subdomains to the IP address of your Ubuntu server ($\text{192.168.1.100}$):

    ```hosts
    # Ubuntu Server Subdomains
    192.168.1.100   server.home
    192.168.1.100   portainer.server.home
    192.168.1.100   jellyfin.server.home
    192.168.1.100   netdata.server.home
    ```

3.  **Save and Close:**
    Save the file (Control + X, then Y, then Enter).

4.  **Flush DNS Cache (Critical Step):**
    Force your macOS system to recognize the new host entries immediately:

    ```bash
    sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
    ```

-----

## Part 2: Configure the Ubuntu Server (Nginx Reverse Proxy)

The server must run Nginx to listen for the incoming hostname on the standard port 80 and forward the request to the correct secure port ($\text{9443}$, $\text{8096}$, etc.).

### 1\. Install Nginx

If Nginx is not installed, run the following commands on your Ubuntu server:

```bash
# Update package list
sudo apt update

# Install Nginx
sudo apt install nginx -y

# Ensure Nginx is running
sudo systemctl start nginx
sudo systemctl enable nginx
```

### 2\. Create the Nginx Configuration File

We will create a specific configuration file for all your services.

1.  **Navigate to the sites-available directory:**

    ```bash
    cd /etc/nginx/sites-available/
    ```

2.  **Create the configuration file:**

    ```bash
    sudo nano local-services
    ```

3.  **Paste the Configuration:**
    Paste the following configuration. **The critical change is using `https://` and the explicit server IP ($\text{192.168.1.100}$) for Docker-mapped ports to avoid 502 errors and SSL handshake failures.**

    ```nginx
    # /etc/nginx/sites-available/local-services

    # PORTAINER setup
    # Portainer runs on HTTPS (9443)
    server {
        listen 80;
        server_name portainer.server.home;

        location / {
            # Use HTTPS and the server's explicit IP
            proxy_pass https://192.168.1.100:9443;
            
            # Necessary for HTTPS backend and WebSockets
            proxy_ssl_server_name on;
            proxy_ssl_session_reuse off;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }
    }

    # JELLYFIN setup
    # Assuming Jellyfin is running on HTTP (8096)
    server {
        listen 80;
        server_name jellyfin.server.home;

        location / {
            # Use HTTP and the server's explicit IP
            proxy_pass http://192.168.1.100:8096;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }

    # NETDATA setup
    # Assuming Netdata is running on HTTP (19999)
    server {
        listen 80;
        server_name netdata.server.home;

        location / {
            # Use HTTP and the server's explicit IP
            proxy_pass http://192.168.1.100:19999;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        }
    }
    ```

4.  **Save and Close:**
    Save the file.

### 3\. Enable and Restart Nginx

1.  **Enable the configuration** by creating a symbolic link:

    ```bash
    sudo ln -s /etc/nginx/sites-available/local-services /etc/nginx/sites-enabled/
    ```

2.  **Remove the default configuration** to prevent conflicts:

    ```bash
    sudo rm /etc/nginx/sites-enabled/default
    ```

3.  **Test the configuration syntax:**

    ```bash
    sudo nginx -t
    ```

    Ensure you see: `syntax is ok` and `test is successful`.

4.  **Restart Nginx:**

    ```bash
    sudo systemctl restart nginx
    ```

-----

## Part 3: Final Testing

1.  Open your web browser on your macOS client.

2.  Test the access:

      * **Portainer:** `http://portainer.server.home`
      * **Jellyfin:** `http://jellyfin.server.home`
      * **Netdata:** `http://netdata.server.home`
