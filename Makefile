
default: help

install: infra setup 3scale

include coredns.mk

setup: nfs traefik insert_coredns_entry

nfs:  ## Deploy NFS storage class and provisioner
	kubectl apply -f kubernetes/nfs/

traefik: ## Delete standard traefik deployment on k3d and deploy traefik v2
	kubectl apply -f kubernetes/admin-sa.yaml
	kubectl apply -f kubernetes/traefik/
	kubectl apply -f kubernetes/ingress-routes.yaml

3scale_k8s/resources:
	mkdir -p $@
	$(MAKE) -C 3scale_k8s


3scale: ## Generate k8s resources from templates and deploy 3scale
3scale: 3scale_k8s/resources
	kubectl apply -f 3scale_k8s/resources


infra: ## Create k3d Cluster. Requires free ports (8000, 8080 and 8443) on your host machine.
infra: k3d
	k3d create --publish 8000:80 --publish 8080:8080 --publish 8443:443 --workers 2 --server-arg --no-deploy=traefik
	sleep 10
	export KUBECONFIG="$$(k3d get-kubeconfig --name='k3s-default')"

clean: ## Cleanup generated files
	rm -f 3scale_k8s/playbook/passwords/*
	rm -rf 3scale_k8s/resources
	rm -rf kubernetes/coredns

teardown: ## Teardown k3d cluster
teardown: k3d
	k3d delete

K3D := $(shell which k3d 2> /dev/null)
k3d:
ifndef K3D
	$(error missing k3d. Please install https://github.com/rancher/k3d)
endif

# Check http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ## Print this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z1-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort
