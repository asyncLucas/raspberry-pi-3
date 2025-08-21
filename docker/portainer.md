# Portainer in a Docker container

### For Portainer CE (Community Edition)

This is the most common version and is free for use. First, create the volume that Portainer will use to store its data:

```bash
docker volume create portainer_data
```

Next, run the Portainer container. The command below pulls the latest Portainer CE image and starts a container named "portainer". It maps port 9000 on your host to port 9000 in the container and binds the Docker socket to the container, which allows Portainer to manage your Docker environment.

```bash
docker run -d -p 192.168.1.100:8000:8000 -p 192.168.1.100:9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
```

  * `-d`: Runs the container in **detached** mode (in the background).
  * `-p 8000:8000`: Maps the container's Edge agent port to the host.
  * `-p 9443:9443`: Maps the main Portainer UI port to the host. If you're using an older version of Docker, you may need to use `-p 9000:9000`.
  * `--name portainer`: Assigns the name "portainer" to the container.
  * `--restart=always`: Ensures the container restarts automatically if it stops or if the system reboots.
  * `-v /var/run/docker.sock:/var/run/docker.sock`: Binds the Docker socket from the host to the container. This is crucial for Portainer to manage other containers.
  * `-v portainer_data:/data`: Mounts the `portainer_data` volume to the container's data directory to persist configurations and data.

-----

After running this command, you can access the Portainer web interface by navigating to `https://your-server-ip:9443` in your web browser. The first time you access it, you will be prompted to create a new user account.

## Edit Containers

To limit the processor usage of your Jellyfin container on Ubuntu Server using Portainer, you'll need to edit the container's resource limits. Portainer provides a user-friendly interface to set these constraints without using the command line.

### Steps to Limit CPU Usage in Portainer

1.  **Open Portainer**: Log in to your Portainer instance and navigate to the **Containers** section in the left-hand menu.
2.  **Select the Jellyfin Container**: Find your Jellyfin container in the list and click on its name to view its details.
3.  **Edit Container Settings**: On the container details page, click the **Duplicate/Edit** button at the top of the page. This will allow you to modify the container's configuration.
4.  **Configure Resource Limits**:
    * Scroll down to the **"Runtime & Resources"** section.
    * Find the **"CPU"** setting. You can either use the slider to set a maximum percentage of a single CPU core (e.g., `50%`) or enter a specific number in the input field. A value of `0.5` would limit it to half of a CPU core, while `2` would limit it to two full CPU cores. 
    * You can also set a **"CPU Priority"** with the `CPU shares` option. This isn't a hard limit but determines the container's priority for CPU time when the system is under heavy load. A higher value (e.g., `2048` instead of the default `1024`) gives the container more CPU time relative to other containers.
5.  **Recreate the Container**: Once you've set your desired CPU limit, scroll down and click the **Deploy the container** button. Portainer will stop the old container, apply the new settings, and start a new one with the specified CPU limit.

***

### Important Considerations

* **Understanding CPU Limits:** The CPU limit you set is based on a single CPU core. For example, if your server has a 4-core CPU, setting the limit to `0.5` will cap Jellyfin's usage at half of one core, not half of your total CPU power. Setting it to `4` would allow it to use up to four full cores.
* **Noisy Neighbor Problem:** Limiting CPU usage is a great way to prevent a single application, like Jellyfin during a transcoding task, from monopolizing all of your server's resources. This ensures other services on your server remain responsive.

### Specify the IP address a container's port will bind to on the host
Portainer also allows you to configure this. When you are creating or editing a container's settings in Portainer, navigate to the Network section. In the port mappings area, you'll see a field for the Host IP Address or similar, where you can enter the specific IP address you want to bind to. Leave this field blank to use 0.0.0.0 (all interfaces), or enter a specific IP to restrict access.

You can also assign a static IP address to the container itself (the internal IP that is part of the Docker network) using custom networks. Docker's default bridge network doesn't support static IP assignments. To do this, you would first need to create a custom bridge network and specify a subnet for it, and then assign a static IP to the container when you add it to that new network.

The video explains how to assign a static IP address to a container, which is an important step in network configuration for Docker. Assign a static IP to a container.