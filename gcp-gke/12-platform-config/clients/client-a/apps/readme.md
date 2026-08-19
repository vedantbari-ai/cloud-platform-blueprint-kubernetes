# GKE Application Deployment & Filestore Guide

This guide documents the complete end-to-end steps, configurations, and troubleshooting solutions implemented to deploy a containerized application (Nginx) using a custom network-aware Google Cloud Filestore storage class (`ReadWriteMany`) via Terraform, Terragrunt, and Helm.

---

## 1. Custom Storage Class Configuration

Because GKE clusters operating within a custom VPC network require network-aware storage configurations to avoid mount timeouts (`DeadlineExceeded`), a custom storage class was created for Google Cloud Filestore.

Create and apply the following manifest (`custom-filestore-sc.yaml`):

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: custom-standard-rwx
provisioner: filestore.csi.storage.gke.io
volumeBindingMode: Immediate
allowVolumeExpansion: true
parameters:
  tier: standard
  network: YOUR_CUSTOM_VPC_NETWORK_NAME  # Replace with your actual GKE VPC network name

```

Apply it to the cluster:

```bash
kubectl apply -f custom-filestore-sc.yaml

```

---

## 2. Platform Configuration (`values.yaml`)

The application-specific configurations are maintained as a single source of truth inside the platform config directory:

`gcp-gke/12-platform-config/clients/client-a/apps/test-app-values.yaml`

```yaml
releaseName: test-app
timeout: 600

namespace:
  create: true
  name: dev-frontend

serviceAccount:
  create: true

image:
  repository: nginx
  tag: "alpine"
  pullPolicy: IfNotPresent

service:
  enabled: true
  port: 80
  targetPort: 80
  type: ClusterIP

persistence:
  enabled: true
  storageClassName: "custom-standard-rwx"
  accessMode: ReadWriteMany
  size: 100Gi  # Minimum required capacity for Basic HDD Filestore tier
  mountPath: /usr/share/nginx/html

securityContext:
  runAsNonRoot: false
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
    add:
      - CHOWN
      - SETUID
      - SETGID

resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 100m
    memory: 128Mi

```

---

## 3. Live Terragrunt Configuration (`terragrunt.hcl`)

The live Terragrunt deployment configuration dynamically loads values from the YAML file, extracting variables such as `release_name`, `namespace`, and `timeout`.

Located at: `gcp-gke/03-live/clients/client-a/dev/apps/test-app/terragrunt.hcl`

```hcl
include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

terraform {
  source = "${get_repo_root()}/gcp-gke/02-modules/06-app-deploy"
}

dependency "gke" {
  config_path = "../../04-gke"
  mock_outputs = {
    cluster_endpoint       = "0.0.0.0"
    cluster_ca_certificate = "bW9jay1jZXJ0"
  }
}

locals {
  app_values = yamldecode(file("${get_repo_root()}/gcp-gke/12-platform-config/clients/client-a/apps/test-app-values.yaml"))
}

inputs = {
  chart_path             = "${get_repo_root()}/gcp-gke/13-helm-charts-app/generic-app"
  release_name           = local.app_values.releaseName
  namespace              = local.app_values.namespace.name
  timeout                = local.app_values.timeout
  app_values             = local.app_values
  cluster_endpoint       = dependency.gke.outputs.cluster_endpoint
  cluster_ca_certificate = dependency.gke.outputs.cluster_ca_certificate
}

```

---

## 4. Deployment Execution

Navigate to the live application directory and deploy using Terragrunt:

```bash
cd gcp-gke/03-live/clients/client-a/dev/apps/test-app
terragrunt apply

```

---

## 5. Troubleshooting Steps & Key Adjustments Made

* **Filestore Provisioning Latency:** Network file shares (`-rwx`) take 3 to 10 minutes to provision. The PVC will remain in a `Pending` state until Google Cloud fully establishes the file share instance.
* **Nginx Startup Permissions (`Operation not permitted`):** Nginx attempts to adjust cache directory permissions using `chown` upon startup. Adding `CHOWN`, `SETUID`, and `SETGID` capabilities to the container's `securityContext` resolved startup blocks while maintaining security best practices (`drop: [ALL]`).
* **Namespace Conflict Resolution:** Removed duplicate `namespace.yaml` template files from the generic Helm chart to prevent conflicts with Terragrunt/Helm's native `create_namespace = true` logic.

---

## 6. Final Validation & Initialization Command

Because mounting an empty network share over `/usr/share/nginx/html` triggers a `403 Forbidden` error (due to the lack of an `index.html` file), populate a test index page into the mounted volume using the following `kubectl exec` command:

```bash
kubectl exec -it deploy/frontend-web-generic-app -n dev-frontend -- sh -c 'echo "<h1>Hello from Shared GKE Filestore!</h1>" > /usr/share/nginx/html/index.html'

```