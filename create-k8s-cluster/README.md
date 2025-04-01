Step 2: Download and Install AWS CLI
Now, download and install AWS CLI v2:

bash
Copy
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
Step 3: Verify Installation
Check if AWS CLI was successfully installed by running:

bash
Copy
$ aws --version
For more details, refer to the AWS CLI Installation Guide.

2. Install kubectl and eksctl
Install kubectl
kubectl is the Kubernetes CLI tool used for interacting with Kubernetes clusters.

Step 1: Download kubectl
Use the following command to download the correct version of kubectl for your system:

bash
Copy
$ curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.32.0/2024-12-20/bin/linux/amd64/kubectl
Step 2: Verify the SHA256 Hash
Verify the integrity of the downloaded kubectl binary by checking the SHA256 hash:

bash
Copy
$ openssl sha1 -sha256 kubectl
Step 3: Make kubectl Executable
Make the kubectl binary executable:

bash
Copy
$ chmod +x ./kubectl
Step 4: Add kubectl to PATH
Move the kubectl binary to a folder in your PATH and export it:

bash
Copy
$ mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH
Step 5: Verify kubectl Installation
Run the following command to verify that kubectl is properly installed:

bash
Copy
$ kubectl version --client
For more details on kubectl installation, refer to the official kubectl installation guide.

Install eksctl
eksctl is a simple CLI tool for creating clusters on EKS.

To install eksctl, follow the installation guide on eksctl.io.

3. Create EKS Cluster
Step 1: Create Cluster Configuration File
Create a configuration file (cluster-config.yaml) to define the cluster specifications.

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
Step 2: Create the EKS Cluster
Use eksctl to create the EKS cluster:

bash
Copy
$ eksctl create cluster -f cluster-config.yaml
This command will create the cluster and the necessary resources based on the configuration file.

Step 3: Verify the Cluster
To verify if the cluster was created successfully, run the following command:

bash
Copy
$ eksctl get cluster --region us-east-2
4. Update kubectl Configuration
Once the cluster is created, update your kubectl configuration to point to the newly created cluster.

Run the following command:

bash
Copy
$ aws eks update-kubeconfig --region us-east-2 --name development
This updates your local kubeconfig file (~/.kube/config) with the cluster credentials.

5. Verify Connection to the EKS Cluster
Now that your kubeconfig is updated, verify the connection to your EKS cluster:

Step 1: Check Node Status
Run the following command to check the status of your nodes:

bash
Copy
$ kubectl get nodes
This will list all the nodes in your EKS cluster.

Step 2: Verify Kubernetes API Access
Run the following command to verify the Kubernetes API:

bash
Copy
$ kubectl cluster-info
This will display information about the cluster, such as the Kubernetes API server and other components.

Useful Links
AWS CLI Installation Guide

kubectl Installation Guide

eksctl Installation Guide

Troubleshooting
kubectl not found in PATH: If kubectl is not recognized after installation, ensure that $HOME/bin is added to your PATH.

Cluster connection issue: If you are unable to connect to the EKS cluster, check your kubeconfig file (~/.kube/config) and ensure it contains the correct cluster details.


