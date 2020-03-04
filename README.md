# Multikloud

A proof-of-concept kind of repository we created during the 2019 3scale Engineering Hackfest, to show how 3scale can be deployed on vanilla Kubernetes, across the major cloud providers, AND locally, on your laptop, with k3d. 

## Run 3scale on your laptop

This repo contains an example of deploying 3scale on your laptop, on [k3d](https://github.com/rancher/k3d), a lightweight Kubernetes distro by Rancher, running in Docker. 

### Prerequisites

* Docker 
* k3d - e.g. `brew install k3d`
* ansible (for generating the k8s templates)

### RWX PVC support

* 3scale System component needs a RWC PVC for `system-storage`:
  * Configuration files read by the System component at run-time
  * Static files (HTML, CSS, JS, etc) uploaded to System by its CMS feature, for the purpose of creating a Developer Portal
  * Note that System can be scaled horizontally with multiple pods uploading and reading said static files, hence the need for a RWX PersistentVolume
* For dev purpose, it can deployed on the k8s cluster a small [nfs-provisioner](kubernetes/nfs/) in order to create a RWX `PersistentVolumeClaim` without using S3 or any external NFS...
  * 3scale templates: specify template variable `RWX_STORAGE_CLASS` to value `nfs`
  * 3scale operator: specify `APIManager` CR variable `StorageClassName` to value `nfs`
  ```yaml
  apiVersion: apps.3scale.net/v1alpha1
  kind: APIManager
  metadata:
    name: your-apimanager
    namespace: your-namespace
  spec:
    wildcardDomain: YOUR-WILDCARD.apps.CLUSTER-NAME.dev.3sca.net
    resourceRequirementsEnabled: false
    system:
      fileStorage:
        persistentVolumeClaim:
          storageClassName: nfs
  ```
* Example of [system-storage-pvc](kubernetes/system-storage-pvc.yml)

### Usage

1. `make` or `make help` - for usage instructions
1. `make infra` - to create a cluster with k3d
1. `make setup` - some prerequisites for 3scale
1. `make 3scale` - generating 3scale k8s resources from jinja templates (check localhost.ini for values) and deploy on k3d
1. Grab a cup of :coffee: 
1. use `kubectl get pods` (or, even better [k9s](https://github.com/derailed/k9s) :tada: ) to watch deployment status
1. Go to https://master-account.127.0.0.1.nip.io:8443 on your browser
1. Accept the self-signed certificate warning
1. Login with username `master` and password the value that you'll find in `$PROJECT_ROOT/3scale_k8s/playbook/passwords/master_password`.
