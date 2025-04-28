
# Helm 3 Documentation

Helm is a package manager for Kubernetes, designed to simplify the deployment and management of applications through reusable configuration packages called charts. Helm 3, the latest major release, introduces a more secure, client-only architecture by removing Tiller (the server-side component from Helm 2), allowing direct interaction with the Kubernetes API server and leveraging Kubernetes-native security and permissions.

## 1. What is Helm?
Helm is a tool for managing Kubernetes packages called charts. A chart is a collection of files that describe a set of Kubernetes resources.

With Helm, you can define, install, and upgrade even the most complex Kubernetes applications using charts.

Maintained by CNCF in collaboration with Microsoft, Google, Bitnami, and the Helm community.

## 2. Key Differences: Helm 2 vs. Helm 3

| Feature | Helm 2 | Helm 3 |
|---------|--------|--------|
| Server-side | Uses Tiller | No Tiller |
| Security | Cluster-wide | Uses kubeconfig |
| Architecture | Client/Server | Client-only |

Helm 3 removes Tiller, making it more secure and simpler to use. Permissions are now based on the Kubernetes config file, allowing for fine-grained access control.

## 3. Installing Helm 3

To install Helm 3, run the following commands in your terminal:

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

Verify the installation:

```bash
helm --version
```

Helm uses the kubeconfig file (`~/.kube/config`) by default, but you can specify another file using the `$KUBECONFIG` environment variable.

## 4. Basic Helm 3 Commands

### Chart Management
- **Create a new chart:**
  ```bash
  helm create [NAME]
  ```

- **Package a chart:**
  ```bash
  helm package [CHART]
  ```

- **Lint a chart (validate structure):**
  ```bash
  helm lint [CHART]
  ```

- **Show chart details:**
  ```bash
  helm show all [CHART]
  helm show values [CHART]
  ```

- **Pull a chart from a repository:**
  ```bash
  helm pull [CHART]
  ```

- **List chart dependencies:**
  ```bash
  helm dependency list [CHART]
  ```

### Repository Management
- **Add a chart repository:**
  ```bash
  helm repo add [NAME] [URL]
  ```

- **List repositories:**
  ```bash
  helm repo list
  ```

- **Remove a repository:**
  ```bash
  helm repo remove [NAME]
  ```

- **Update repository information:**
  ```bash
  helm repo update
  ```

### OCI Registry Support
Helm 3 supports OCI-based registries (experimental). Enable with:

```bash
export HELM_EXPERIMENTAL_OCI=1
```

- **Login to a registry:**
  ```bash
  helm registry login [HOST]
  ```

- **Logout from a registry:**
  ```bash
  helm registry logout [HOST]
  ```

## 5. Application Lifecycle Management

### Install and Uninstall Applications
- **Install a chart:**
  ```bash
  helm install [RELEASE_NAME] [CHART]
  ```

- **Install in a specific namespace:**
  ```bash
  helm install [RELEASE_NAME] [CHART] --namespace [NAMESPACE]
  ```

- **Override values:**
  ```bash
  helm install [RELEASE_NAME] [CHART] --values [VALUES_FILE]
  ```

- **Test installation (dry run):**
  ```bash
  helm install [RELEASE_NAME] [CHART] --dry-run --debug
  ```

- **Uninstall a release:**
  ```bash
  helm uninstall [RELEASE_NAME]
  ```

### Upgrade and Rollback
- **Upgrade a release:**
  ```bash
  helm upgrade [RELEASE_NAME] [CHART]
  ```

- **Automatic rollback on failure:**
  ```bash
  helm upgrade [RELEASE_NAME] [CHART] --atomic
  ```

- **Install if release does not exist:**
  ```bash
  helm upgrade [RELEASE_NAME] [CHART] --install
  ```

- **Rollback a release:**
  ```bash
  helm rollback [RELEASE_NAME] [REVISION]
  ```

## 6. Searching for Charts
- **Search Helm Hub:**
  ```bash
  helm search hub [KEYWORD]
  ```

- **Search local repositories:**
  ```bash
  helm search repo [KEYWORD]
  ```

## 7. Monitoring and Release Management

- **Check release status:**
  ```bash
  helm status [RELEASE_NAME]
  ```

- **List all releases:**
  ```bash
  helm list
  ```

- **View release history:**
  ```bash
  helm history [RELEASE_NAME]
  ```

## 8. Example Workflow

- **Add a repository:**
  ```bash
  helm repo add bitnami https://charts.bitnami.com/bitnami
  helm repo update
  ```

- **Search for a chart:**
  ```bash
  helm search repo nginx
  ```

- **Install a chart:**
  ```bash
  helm install my-nginx bitnami/nginx
  ```

- **Check status:**
  ```bash
  helm status my-nginx
  ```

- **Upgrade the release:**
  ```bash
  helm upgrade my-nginx bitnami/nginx --set service.type=LoadBalancer
  ```

- **Rollback if needed:**
  ```bash
  helm rollback my-nginx 1
  ```

- **Uninstall the release:**
  ```bash
  helm uninstall my-nginx
  ```

## 9. Additional Resources

For detailed command references, use:

```bash
helm [COMMAND] --help
```

- Official Helm documentation: [helm.sh/docs](https://helm.sh/docs)
- Helm command cheat sheets: [Helm Cheat Sheet](https://helm.sh/docs/helm/helm_cheat_sheet.pdf)
