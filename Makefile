
default: k3d_infra setup 3scale

include coredns.mk

setup: nfs traefik insert_coredns_entry

nfs:
	kubectl apply -f kubernetes/nfs/

traefik:
	kubectl delete daemonset -n kube-system svclb-traefik
	kubectl delete deployment -n kube-system traefik
	kubectl apply -f kubernetes/admin-sa.yaml
	kubectl apply -f kubernetes/traefik.yaml
	kubectl apply -f kubernetes/ingress-routes.yaml

3scale_k8s/resources:
	mkdir -p $@
	$(MAKE) -C 3scale_k8s


3scale: 3scale_k8s/resources
	kubectl apply -f 3scale_k8s/resources


k3d_infra:
	k3d create --publish 8000:80 --publish 8080:8080 --publish 8443:443 --workers 2
	sleep 30
	export KUBECONFIG="$$(k3d get-kubeconfig --name='k3s-default')"


clean:
	rm -f 3scale_k8s/playbook/passwords/*
	rm -rf 3scale_k8s/resources
	rm -rf kubernetes/coredns

teardown:
	k3d delete
