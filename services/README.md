## 5. Kubernetes Services
### What is a Service in Kubernetes?
A Service in Kubernetes is an abstraction that defines a logical set of Pods and a policy to access them. Services enable communication between different components of an application, whether inside the cluster or externally.

### Types of Services
1. **ClusterIP** (Default): Exposes the service on an internal IP within the cluster.
2. **NodePort**: Exposes the service on each Node’s IP at a static port.
3. **LoadBalancer**: Provisions an external load balancer to route traffic.
4. **ExternalName**: Maps a service to a DNS name.
5. **Headless Service**: Used when you don't need load balancing and want direct pod discovery.

---

## 6. Deploy the Application
Apply the deployment and service to your cluster:
```sh
$ kubectl apply -f nginx-deployment.yaml
```

---

## 7. Verify the Deployment
Check if the pods are running:
```sh
$ kubectl get pods
```
**Expected output:**
```
NAME                               READY   STATUS    RESTARTS   AGE
nginx-deployment-5d69c4b8b8-xyz1   1/1     Running   0          30s
nginx-deployment-5d69c4b8b8-xyz2   1/1     Running   0          30s
```

deploy loadbalancerin the service:
```sh
$ kubectl apply -f nginx-loadbalancer.yaml 
```
Check the service:
```sh

$ kubectl get svc
```

If `EXTERNAL-IP` is still pending, wait a few minutes. Once it appears, you can access your application via:
```sh
$ curl http://<EXTERNAL-IP>
```
or open it in a browser.

---

## 8. (Optional) Delete the Application
If you want to remove the deployment:
```sh
$ kubectl delete -f nginx-deployment.yaml
```


