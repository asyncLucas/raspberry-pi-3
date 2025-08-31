🔐 WireGuard Configuration – Mini Tutorial

1. Locate your configuration file

On Linux (e.g. Ubuntu, Raspberry Pi):

sudo nano /etc/wireguard/wg0.conf

You’ll see something like:

[Interface]
PrivateKey = <client_private_key>
Address = 10.6.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <server_public_key>
Endpoint = myserver.duckdns.org:51820
AllowedIPs = 0.0.0.0/0, ::/0


⸻

2. Understand AllowedIPs
	•	AllowedIPs = 192.168.1.0/24
➝ Only routes traffic for your home LAN through VPN.
	•	AllowedIPs = 0.0.0.0/0, ::/0
➝ Routes all internet traffic through VPN (most common setup when you want to browse securely).

👉 Choose the one you need.

⸻

3. Apply configuration changes

After saving changes, restart the service:

sudo systemctl restart wg-quick@wg0

Or manually:

sudo wg-quick down wg0
sudo wg-quick up wg0


⸻

4. Verify the active configuration

Run:

sudo wg show

You should see something like:

peer: AbCdEfGhIjKlMnOpQrStUvWxYz1234567890=
  endpoint: 123.45.67.89:51820
  allowed ips: 0.0.0.0/0
  latest handshake: 1 minute ago
  transfer: 12.3 KiB received, 45.6 KiB sent

Check the allowed ips line – it must match your new setting.

⸻

5. Confirm internet routing

Check your public IP before and after connecting to VPN:

curl ifconfig.me

	•	If you see your home server’s public IP, then your traffic is going through the VPN.
	•	If you still see your mobile ISP IP, then only LAN routing is active.

⸻

✅ Done! Now you can control whether only home devices or all internet traffic goes through your WireGuard tunnel.