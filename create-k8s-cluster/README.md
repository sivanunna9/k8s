# AWS CLI, kubectl, and eksctl Installation Guide

## 1. AWS CLI

### Installation Steps
```sh
$ apt-get update
$ apt-get install unzip

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

For more details, refer to the [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).

---

## 2. kubectl and eksctl

### Install kubectl
Refer to the [kubectl installation guide](https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html#linux_amd64_kubectl).

#### Downloading kubectl File
```sh
$ curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.32.0/2024-12-20/bin/linux/amd64/kubectl
```

#### Checking the SHA256 Number
```sh
$ openssl sha1 -sha256 kubectl
```

#### Apply Execute Permissions to the Binary
```sh
$ chmod +x ./kubectl
```

#### Copy the Binary to a Folder in Your PATH
```sh
$ mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
```

---

### Install eksctl
Refer to the [eksctl installation guide](https://eksctl.io/installation/).

---

## 3. Create Cluster Configuration

### Create Cluster Configuration File
Create a file named `cluster-config.yaml` and add the following content:

```yaml
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: development
  region: us-east-2

vpc:
  nat:
    gateway: Single  # Required for private worker nodes to access the internet

managedNodeGroups:
  - name: my-nodegroup
    instanceType: t3.large
    minSize: 1
    maxSize: 3
    desiredCapacity: 2
    volumeSize: 100
    privateNetworking: true  # Ensures nodes only get private IPs
    ssh:
      allow: true
      publicKeyName: my-key  # Replace with your actual AWS EC2 key pair name
```

### Create Cluster Using eksctl
```sh
$ eksctl create cluster -f cluster-config.yaml
$ eksctl get cluster --region us-east-2
```

---

## 4. Update kubectl Configuration
Run the following command to add your cluster credentials to kubectl:
```sh
$ aws eks update-kubeconfig --region us-east-2 --name demo
```
This updates your local kubeconfig file (`~/.kube/config`) with the cluster details.

### Verify the Connection
#### Check if Your Cluster is Accessible
```sh
$ kubectl get nodes
```

#### Verify Kubernetes API Access
```sh
$ kubectl cluster-info
```


