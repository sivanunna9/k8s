
# Kubernetes Pod Presets Documentation

## Introduction to Pod Presets

In Kubernetes, **Pod Presets** provide a mechanism to inject configuration data into pods automatically at runtime. This feature allows for a more streamlined way of managing common configurations that need to be applied to multiple pods. Rather than manually defining environment variables, volume mounts, and annotations within each pod spec, **Pod Presets** allow these configurations to be applied automatically based on label selectors.

### Key Features of Pod Presets
- **Automatic Injection:** They inject configurations like environment variables, volume mounts, and annotations into pods without requiring changes to the pod spec.
- **Centralized Configuration:** Pod Presets help in managing common configurations centrally and apply them consistently across multiple pods.
- **Label Selectors:** Pod Presets apply to pods that match specific labels, providing flexibility in selecting which pods the presets should affect.
- 
- PodPreset was part of the Settings API group and required enabling the PodPreset admission controller, which is not available in EKS or most managed Kubernetes distributions post v1.20.

### How Pod Presets Work
1. A `PodPreset` object is created and defines the configuration settings that need to be injected into matching pods.
2. The `PodPreset` is then applied to pods by using label selectors to identify which pods should receive the configuration.
3. The Pod Preset is processed by the Kubernetes **PodPreset admission controller**, which modifies the pod's configuration at runtime.

### Pod Preset Example

Here’s an example that demonstrates the usage of a Pod Preset:

#### Step 1: Define the PodPreset
```yaml
apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: db-connection
spec:
  selector:
    matchLabels:
      app: web
  env:
    - name: DB_HOST
      value: db.example.com
    - name: DB_PORT
      value: "5432"
  volumeMounts:
    - name: db-volume
      mountPath: /mnt/db
```

- In this example, the `PodPreset` is named `db-connection` and defines environment variables (`DB_HOST` and `DB_PORT`) that will be injected into matching pods.
- The selector applies the preset to pods with the label `app: web`, and it also mounts a volume named `db-volume` to the pod.

#### Step 2: Applying the Pod Preset to a Pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-pod
  annotations:
    podpreset.admission.kubernetes.io/podpreset-apply: db-connection
spec:
  containers:
  - name: web-container
    image: my-web-app
```

- In this pod spec, the `db-connection` Pod Preset is applied via the annotation `podpreset.admission.kubernetes.io/podpreset-apply`.
- When the pod is created, the environment variables and volume mount defined in the Pod Preset are injected automatically.

---

## Difference Between ConfigMap and PodPreset

While both **ConfigMap** and **PodPreset** are used to inject configuration data into pods, there are several key differences between the two:

| **Feature**                    | **ConfigMap**                                                | **PodPreset**                                                     |
|---------------------------------|--------------------------------------------------------------|-------------------------------------------------------------------|
| **Purpose**                     | Stores configuration data in key-value pairs.                | Injects common settings into pods automatically.                  |
| **Usage**                       | Manually referenced in Pod/Deployment spec.                  | Automatically applied to pods based on label selectors.           |
| **Data Provided**               | Can store environment variables, configuration files, command args, etc. | Can only provide environment variables, volume mounts, and annotations. |
| **Scope**                       | Applied manually to each pod.                                | Automatically applied to matching pods using label selectors.     |
| **Automation**                  | Manual inclusion of data into the pod's configuration.       | Automatic injection into matching pods without additional effort. |
| **Controller Required**         | No additional controller needed.                             | Requires the `PodPreset` admission controller to be enabled.      |
| **Example Use Case**            | Centralized application configuration, feature toggles.      | Injecting shared secrets (e.g., database credentials) into multiple pods. |
| **Kubernetes Version Support**  | Fully supported in all Kubernetes versions.                  | An alpha feature; may require enabling and is not recommended for production use in older versions. |
| **Flexibility**                 | Very flexible; can be mounted as volumes or used in environment variables. | Limited to environment variables, volume mounts, and annotations. |

---

## Summary

### ConfigMap:
- **ConfigMaps** allow you to store configuration data that can be used across multiple pods and services.
- It is a flexible mechanism to inject configurations such as environment variables, configuration files, or command-line arguments.
- ConfigMaps need to be explicitly referenced in pod specifications.

### PodPreset:
- **PodPresets** are designed to automate the injection of common configuration data into matching pods at runtime.
- This feature helps manage configurations centrally, reducing the need for repeated configuration definitions across multiple pods.
- Pod Presets are applied to pods automatically based on label selectors, but they require the `PodPreset` admission controller to be enabled.

### Key Differences:
- **Manual vs. Automatic:** ConfigMaps require manual reference in each pod, whereas PodPresets are automatically applied to matching pods.
- **Scope of Data:** ConfigMaps can store more flexible data types, including files and configurations, while PodPresets are limited to environment variables, volume mounts, and annotations.
- **Use Case:** ConfigMaps are ideal for centralized configuration management, whereas PodPresets are used for automating common configurations across multiple pods without modifying each pod spec.

In conclusion, use **ConfigMap** when you need more flexibility and control over the configuration data being injected into pods. Use **PodPreset** when you want to automatically inject shared configurations like environment variables and volume mounts across multiple pods with minimal effort.

