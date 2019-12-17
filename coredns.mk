.PHONY: insert_coredns_entry
insert_coredns_entry: kubernetes/coredns/configmap.yaml
	kubectl apply -n kube-system -f kubernetes/coredns/configmap.yaml
	kubectl patch -n kube-system deployment coredns -p "{\"spec\": {\"template\": {\"metadata\": { \"labels\": {  \"redeploy\": \"$$(date +%s)\"}}}}}"

kubernetes/coredns:
	mkdir -p kubernetes/coredns

kubernetes/coredns/Corefile: kubernetes/coredns
	kubectl get cm coredns -n kube-system -o jsonpath='{.data.Corefile}' > $@
	cat $@ | sed -e $$'s/errors/errors\\\n     rewrite name master-account.127.0.0.1.nip.io traefik.default.svc.cluster.local/' | tee $@

kubernetes/coredns/NodeHosts: kubernetes/coredns
	kubectl get cm coredns -n kube-system -o jsonpath='{.data.NodeHosts}' > $@

kubernetes/coredns/configmap.yaml: kubernetes/coredns kubernetes/coredns/Corefile kubernetes/coredns/NodeHosts
	kubectl create configmap coredns --from-file=kubernetes/coredns/Corefile --from-file=kubernetes/coredns/NodeHosts --output=json --dry-run > $@

kubernetes/coredns-config.yaml: kubernetes/coredns
	kubectl get configmap  coredns -n kube-system -o yaml | sed -e $$'s/health/health  \\\n      rewrite name master-account.127.0.0.1.nip.io traefik.default.svc.cluster.local/' > kubernetes/coredns-config.yaml
