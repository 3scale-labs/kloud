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
