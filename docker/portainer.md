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