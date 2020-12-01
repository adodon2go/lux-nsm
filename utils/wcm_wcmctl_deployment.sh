#! /bin/bash

rm -rf /tmp/cluster_state
kind delete cluster --name=kind1
kind delete cluster --name=kind2
kind delete cluster --name=kind3

mkdir -p ${WCM_SYSTEM_DIR}/kubeconfigs/nsm
mkdir -p ${WCM_SYSTEM_DIR}/kubeconfigs/central
cd ${WCM_SYSTEM_DIR}
cat system_topo/config/kind_clustermaps.sh | sed 's@=\${KCONFDIR_ROOT}@=/go/src/github.com/cisco-app-networking/wcm-system@g' > system_topo/config/systest_clustermap.sh

kind create cluster --name kind1
kind create cluster --name kind2
kind create cluster --name kind3

kind get kubeconfig --name=kind1 > ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig
kind get kubeconfig --name=kind2 > ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig
kind get kubeconfig --name=kind3 > ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig

docker pull cnns/cnns-ipam:latest
docker pull cnns/connectivity-domain-operator:latest
docker pull cnns/wcmd:latest
docker pull cnns/app-dns-publisher-controller:latest
docker pull cnns/nse-discovery-operator:latest
docker pull cnns/member-core-operator:latest
docker pull cnns/wcm-nse-operator:latest
docker pull ciscoappnetworking/vl3_ucnf-nse:master
docker pull ciscoappnetworking/nsmrs:vl3_latest
docker pull ciscoappnetworking/nsmdp:vl3_latest
docker pull ciscoappnetworking/nsmd:vl3_latest
docker pull ciscoappnetworking/nsmd-k8s:vl3_latest
docker pull ciscoappnetworking/vppagent-forwarder:vl3_latest
docker pull ciscoappnetworking/proxy-nsmd:vl3_latest
docker pull ciscoappnetworking/proxy-nsmd-k8s:vl3_latest
docker pull ciscoappnetworking/admission-webhook:vl3_latest
docker pull networkservicemesh/crossconnect-monitor:master
docker pull networkservicemesh/nsm-init:master
docker pull networkservicemesh/nsm-dns-init:master
docker pull networkservicemesh/nsm-monitor:master
docker pull networkservicemesh/coredns:master
docker pull networkservicemesh/nsm-spire:master

for cluster in kind1; do
    kind load docker-image --name $cluster cnns/cnns-ipam:latest
    kind load docker-image --name $cluster cnns/connectivity-domain-operator:latest
done

for cluster in kind1 kind2 kind3; do
    kind load docker-image --name $cluster kindest/kindnetd:0.5.4
    kind load docker-image --name $cluster registry.opensource.zalan.do/teapot/external-dns:v0.7.1
    kind load docker-image --name $cluster metallb/controller:v0.8.2
    kind load docker-image --name $cluster metallb/speaker:v0.8.2
    kind load docker-image --name $cluster quay.io/coreos/etcd:v3.3.15
    kind load docker-image --name $cluster quay.io/coreos/etcd-operator:v0.9.4
done
 
for cluster in kind2 kind3; do
    kind load docker-image --name $cluster gcr.io/spiffe-io/wait-for-it
    kind load docker-image --name $cluster gcr.io/spiffe-io/spire-agent:0.9.0
    kind load docker-image --name $cluster gcr.io/spiffe-io/spire-server:0.9.0
    kind load docker-image --name $cluster ciscoappnetworking/nsmdp:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/nsmd:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/nsmd-k8s:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/vppagent-forwarder:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/proxy-nsmd:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/proxy-nsmd-k8s:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/admission-webhook:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/crossconnect-monitor:vl3_latest
    kind load docker-image --name $cluster networkservicemesh/crossconnect-monitor:master
    kind load docker-image --name $cluster networkservicemesh/nsm-init:master
    kind load docker-image --name $cluster networkservicemesh/nsm-dns-init:master
    kind load docker-image --name $cluster networkservicemesh/nsm-monitor:master
    kind load docker-image --name $cluster networkservicemesh/coredns:master
    kind load docker-image --name $cluster networkservicemesh/nsm-spire:master
    kind load docker-image --name $cluster jaegertracing/all-in-one:1.14.0
    kind load docker-image --name $cluster rancher/local-path-provisioner:v0.0.11
    kind load docker-image --name $cluster skydive/skydive:0.24.0
    kind load docker-image --name $cluster skydive/skydive:0.23.0
    kind load docker-image --name $cluster cnns/nse-discovery-operator:latest
    kind load docker-image --name $cluster cnns/member-core-operator:latest
    kind load docker-image --name $cluster cnns/wcm-nse-operator:latest
    kind load docker-image --name $cluster matrohon/skydive:latest
done

GOPATH=/go wcmctl install central-cluster-components -k ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig
GOPATH=/go wcmctl install member-cluster-components --central-kubeconfig ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig --prefix 254 -k ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig
GOPATH=/go wcmctl install member-cluster-components --central-kubeconfig ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig --prefix 253 -k ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig


for cluster in kind1; do
    kind load docker-image --name $cluster cnns/app-dns-publisher-controller:latest
    kind load docker-image --name $cluster cnns/wcmd:latest
    kind load docker-image --name $cluster ciscoappnetworking/nsmrs:vl3_latest
done
for cluster in kind3 kind2; do
    kind load docker-image --name $cluster ciscoappnetworking/vl3_ucnf-nse:master
    kind load docker-image --name $cluster istio/examples-helloworld-v1:latest
done

GOPATH=/go wcmctl create connectivitydomain -k ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig --name example --memberConfig=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig,${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig
${WCM_SYSTEM_DIR}/system_topo/deploy_demo_app.sh --cluster-map-file=${WCM_SYSTEM_DIR}/system_topo/config/systest_clustermap.sh --component-map-file=${WCM_SYSTEM_DIR}/system_topo/config/wcm-3-cluster.sh --service-name=example --nsc-delay=10
cd  ${WCM_SYSTEM_DIR} && make integration-tests-connectivity label='app=helloworld-example' kcnsmdir=${WCM_SYSTEM_DIR}/kubeconfigs/nsm deployment='helloworld-example'

kind create cluster --name=kind4
kind get kubeconfig --name=kind4 > ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-4.kubeconfig
kconf=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-4.kubeconfig
kubectl wait --kubeconfig ${kconf} --timeout=150s --for condition=Ready -l tier=control-plane -n kube-system pod
kubectl wait --kubeconfig ${kconf} --timeout=150s --for condition=Ready -l k8s-app=kube-proxy -n kube-system pod
kubectl wait --kubeconfig ${kconf} --timeout=150s --for condition=Ready -l k8s-app=kindnet -n kube-system pod
kubectl wait --kubeconfig ${kconf} --timeout=150s --for condition=Ready -l k8s-app=kube-dns -n kube-system pod

for cluster in kind4; do
    kind load docker-image --name $cluster gcr.io/spiffe-io/wait-for-it
    kind load docker-image --name $cluster gcr.io/spiffe-io/spire-agent:0.9.0
    kind load docker-image --name $cluster gcr.io/spiffe-io/spire-server:0.9.0
    kind load docker-image --name $cluster ciscoappnetworking/nsmdp:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/nsmd:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/nsmd-k8s:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/vppagent-forwarder:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/proxy-nsmd:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/proxy-nsmd-k8s:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/admission-webhook:vl3_latest
    kind load docker-image --name $cluster ciscoappnetworking/crossconnect-monitor:vl3_latest
    kind load docker-image --name $cluster networkservicemesh/crossconnect-monitor:master
    kind load docker-image --name $cluster networkservicemesh/nsm-init:master
    kind load docker-image --name $cluster networkservicemesh/nsm-dns-init:master
    kind load docker-image --name $cluster networkservicemesh/nsm-monitor:master
    kind load docker-image --name $cluster networkservicemesh/coredns:master
    kind load docker-image --name $cluster networkservicemesh/nsm-spire:master
    kind load docker-image --name $cluster jaegertracing/all-in-one:1.14.0
    kind load docker-image --name $cluster rancher/local-path-provisioner:v0.0.11
    kind load docker-image --name $cluster skydive/skydive:0.24.0
    kind load docker-image --name $cluster skydive/skydive:0.23.0
    kind load docker-image --name $cluster cnns/nse-discovery-operator:latest
    kind load docker-image --name $cluster cnns/member-core-operator:latest
    kind load docker-image --name $cluster cnns/wcm-nse-operator:latest
    kind load docker-image --name $cluster matrohon/skydive:latest
    kind load docker-image --name $cluster ciscoappnetworking/vl3_ucnf-nse:master
    kind load docker-image --name $cluster istio/examples-helloworld-v1:latest
done


GOPATH=/go wcmctl install member-cluster-components --central-kubeconfig ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig --prefix 252 -k ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-4.kubeconfig
GOPATH=/go wcmctl join connectivity-domain -k ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-4.kubeconfig
GOPATH=/go ${WCM_SYSTEM_DIR}/system_topo/deploy_demo_app.sh --cluster-map-file=${WCM_SYSTEM_DIR}/system_topo/config/systest_clustermap.sh --component-map-file=${WCM_SYSTEM_DIR}/system_topo/config/wcm-4-cluster.sh --service-name=example --nsc-delay=10
cd ${WCM_SYSTEM_DIR} && sleep 10 && GOPATH=/go make integration-tests-connectivity label='app=helloworld-example' kcnsmdir=${WCM_SYSTEM_DIR}/kubeconfigs/nsm deployment='helloworld-example'
