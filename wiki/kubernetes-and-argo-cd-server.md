# 📦 Raspberry Pi Kubernetes + Argo CD Server

A complete guide to set up a Raspberry Pi as a home server running Kubernetes, Argo CD, and various self-hosted services like Samba, AdGuard Home, and monitoring stack.

⸻

## 🗂 Repository Structure

.
├── README.md
├── manifests/                # Kubernetes raw manifests
│   ├── samba/
│   ├── adguard-home/
│   ├── monitoring/
│   └── namespace.yaml
├── helm-releases/            # Helm values & Argo CD Application manifests
│   ├── samba/
│   ├── adguard-home/
│   └── monitoring/
└── bootstrap/
    ├── install-k3s.sh
    ├── install-argocd.sh
    └── bootstrap-apps.yaml


⸻

1️⃣ Flash & Prepare Raspberry Pi
	1.	Download Raspberry Pi OS Lite (64-bit)
	•	Raspberry Pi OS Lite 64-bit
	•	Use Raspberry Pi Imager to flash to an SD card.
	2.	Enable SSH before first boot:
Place an empty file named ssh in the /boot partition.
	3.	Boot the Pi and SSH into it:

ssh pi@<raspberry-ip>



⸻

## 2️⃣ Install K3s (Lightweight Kubernetes)

curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

Check cluster status:
```sh
kubectl get nodes
```

Make kubectl usable without sudo:
```sh
mkdir -p $HOME/.kube
sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

⸻

## 3️⃣ Install Argo CD

### Create namespace
kubectl create namespace argocd

### Install Argo CD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

### Get initial password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

Expose Argo CD UI:

kubectl port-forward svc/argocd-server -n argocd 8080:443

Access at: https://localhost:8080
Default user: admin

⸻

## 4️⃣ Install Helm

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash


⸻

## 5️⃣ Bootstrap Apps with Argo CD

Create bootstrap/bootstrap-apps.yaml:

apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: home-server
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/<your-username>/<your-repo>'
    targetRevision: main
    path: helm-releases
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true

Apply:

kubectl apply -f bootstrap/bootstrap-apps.yaml


⸻

## 6️⃣ Service Stubs

Samba (helm-releases/samba/values.yaml)

persistence:
  enabled: true
  size: 50Gi
users:
  - name: pi
    password: yourpassword
shares:
  - name: public
    path: /data/public

AdGuard Home (helm-releases/adguard-home/values.yaml)

service:
  type: LoadBalancer
  port: 3000
config:
  bind_host: 0.0.0.0
  dns:
    port: 53

Monitoring (helm-releases/monitoring/values.yaml)

prometheus:
  service:
    type: ClusterIP
grafana:
  adminPassword: admin123


⸻

## 7️⃣ Updating Configs

To deploy changes:

git add .
git commit -m "Update configs"
git push

Argo CD will auto-sync changes to your cluster.

⸻

## 8️⃣ Extras
	•	Ingress Controller: Install traefik or nginx-ingress for domain-based routing.
	•	TLS Certificates: Use cert-manager for HTTPS.
	•	Persistent Storage: Configure local-path-provisioner or NFS.

⸻

📌 Notes
	•	All services must be ARM64-compatible.
	•	Keep an eye on Pi’s CPU/memory usage (kubectl top nodes).
	•	Regularly back up /var/lib/rancher/k3s/server/db/ for disaster recovery.

⸻