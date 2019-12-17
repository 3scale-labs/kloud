# Multikloud

A proof-of-concept kind of repository we created during the 2019 3scale Engineering Hackfest, to show how 3scale can be deployed on vanilla Kubernetes, across the major cloud providers, AND locally, on your laptop, with k3d. 

## Run 3scale on your laptop

This repo contains an example of deploying 3scale on your laptop, on [k3d](https://github.com/rancher/k3d), a lightweight Kubernetes distro by Rancher, running in Docker. 

### Prerequisites

* Docker 
* k3d - e.g. `brew install k3d`
* ansible (for generating the k8s templates)

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


### Troubleshooting

#### Loitering Traefik DaemonSet

By default, k3d ships with an older version of traefik (1.7 at time of writing), in `kube-system` 
namespace. We need v2 for its IngressRoutes and regexp routing features. As such, we delete the 
Traefik Deployment and DaemonSet in `kube-system` and deploy our own.

Sometimes, the DaemonSet gets recreated, so please ensure it is deleted in `kube-system` 
(`kubectl delete daemonset --namespace=kube-system svclb-traefik`) and only exists in the `default` 
namespace. 
 
    

