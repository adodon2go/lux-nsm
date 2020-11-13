#! /bin/bash

read -s -p "Enter Password for sudo: " sudoPW
echo ""
read -s -p "Enter Password for GitHub: " githubPW

# Cleanup
echo ""
echo "Performing Cleanup"
echo $sudoPW | sudo -S rm -rf /go
if [ $? -ne 0 ]
then
    echo "error: Cleanup failed!"
    exit 1
fi

rm -rf /tmp/cluster_state
kind delete cluster --name=kind1
kind delete cluster --name=kind2
kind delete cluster --name=kind3

WCM_SYSTEM_REPO=github.com/adodon2go/wcm-system.git
WCM_SYSTEM_BRANCH=cli

WCM_COMMON_REPO=github.com/cisco-app-networking/wcm-common.git
WCM_COMMON_BRANCH=master

WCM_API_REPO=github.com/cisco-app-networking/wcm-api.git
WCM_API_BRANCH=master

NSE_REPO=https://github.com/cisco-app-networking/nsm-nse.git
NSE_BRANCH=master

NSM_REPO=https://github.com/cisco-app-networking/networkservicemesh.git
NSM_BRANCH=vl3_latest

WCM_SYSTEM_DIR=/go/src/github.com/cisco-app-networking/wcm-system

echo "Environment variables:"
echo "==============================="
echo "WCM_SYSTEM_REPO=$WCM_SYSTEM_REPO"
echo "WCM_SYSTEM_BRANCH=$WCM_SYSTEM_BRANCH"
echo "WCM_COMMON_REPO=$WCM_COMMON_REPO"
echo "WCM_COMMON_BRANCH=$WCM_COMMON_BRANCH"
echo "WCM_API_REPO=$WCM_API_REPO"
echo "WCM_API_BRANCH=$WCM_API_BRANCH"
echo "WCM_SYSTEM_DIR=$WCM_SYSTEM_DIR"
echo "==============================="

WCM_SYSTEM_REPO=https://adodon2go:$githubPW@$WCM_SYSTEM_REPO
WCM_COMMON_REPO=https://adodon2go:$githubPW@$WCM_COMMON_REPO
WCM_API_REPO=https://adodon2go:$githubPW@$WCM_API_REPO

NSE_REPO=https://adodon2go:$githubPW@$NSE_REPO
NSM_REPO=https://adodon2go:$githubPW@$NSM_REPO

echo $sudoPW | sudo -S mkdir -p /go/gopath
echo $sudoPW | sudo -S mkdir -p /go/src/github.com/cisco-app-networking
 
export GOPATH=/go/gopath
echo $sudoPW | sudo -S chown -R midgard:midgard /go

cd /go/src/github.com/cisco-app-networking
git clone ${WCM_SYSTEM_REPO}
while [ $? -ne 0 ]; do
    echo "error: Cloning wcm_system repo failed!\n"
    sleep 1
    rm -rf wcm-system
    git clone ${WCM_SYSTEM_REPO}
done
cd wcm-system/
git checkout ${WCM_SYSTEM_BRANCH}
if [ $? -ne 0 ]; then
    echo "error: Checkout of branch ${WCM_SYSTEM_BRANCH} failed!"
    exit 1
fi
cd ..

git clone ${WCM_API_REPO}
while [ $? -ne 0 ]; do
    echo "error: Cloning wcm_api repo failed!\n"
    sleep 1
    rm -rf wcm-api
    git clone ${WCM_API_REPO}
done
cd wcm-api/
git checkout ${WCM_API_BRANCH}
if [ $? -ne 0 ]; then
    echo "error: Checkout of branch ${WCM_API_BRANCH} failed!"
    exit 1
fi
cd ..

git clone ${WCM_COMMON_REPO}
while [ $? -ne 0 ]; do
    echo "error: Cloning wcm_common repo failed!\n"
    sleep 1
    rm -rf wcm-common
    git clone ${WCM_COMMON_REPO}
done
cd wcm-common/
git checkout ${WCM_COMMON_BRANCH}
if [ $? -ne 0 ]; then
    echo "error: Checkout of branch ${WCM_COMMON_BRANCH} failed!"
    exit 1
fi
cd ..

git clone ${NSM_REPO}
while [ $? -ne 0 ]; do
    echo "error: Cloning networkservicemesh repo failed!\n"
    sleep 1
    rm -rf networkservicemesh
    git clone ${NSM_REPO}
done
cd networkservicemesh/
git checkout ${NSM_BRANCH}
if [ $? -ne 0 ]; then
    echo "error: Checkout of branch ${NSM_BRANCH} failed!"
    exit 1
fi
cd ..

git clone ${NSE_REPO}
while [ $? -ne 0 ]; do
    echo "error: Cloning nsm-nse repo failed!\n"
    sleep 1
    rm -rf nsm-nse
    git clone ${NSE_REPO}
done
cd nsm-nse/
git checkout ${NSE_BRANCH}
if [ $? -ne 0 ]; then
    echo "error: Checkout of branch ${NSE_BRANCH} failed!"
    exit 1
fi
cd ..

echo "======================================= Done Cloning repos  ================================="

## This is for job e2e-kind-test
kind create cluster --name kind1
for cluster in kind1; do
    kind load docker-image --name $cluster k8s.gcr.io/coredns:1.6.5
    kind load docker-image --name $cluster k8s.gcr.io/etcd:3.4.3-0
    kind load docker-image --name $cluster k8s.gcr.io/kube-apiserver:v1.17.0
    kind load docker-image --name $cluster k8s.gcr.io/kube-controller-manager:v1.17.0
    kind load docker-image --name $cluster k8s.gcr.io/kube-proxy:v1.17.0
    kind load docker-image --name $cluster k8s.gcr.io/kube-scheduler:v1.17.0
done
kind create cluster --name kind2
for cluster in kind2; do
    kind load docker-image --name $cluster k8s.gcr.io/coredns:1.6.5
    kind load docker-image --name $cluster k8s.gcr.io/etcd:3.4.3-0
    kind load docker-image --name $cluster k8s.gcr.io/kube-apiserver:v1.17.0
    kind load docker-image --name $cluster k8s.gcr.io/kube-controller-manager:v1.17.0
    kind load docker-image --name $cluster k8s.gcr.io/kube-proxy:v1.17.0
    kind load docker-image --name $cluster k8s.gcr.io/kube-scheduler:v1.17.0
done
kind create cluster --name kind3
for cluster in kind3; do
    kind load docker-image --name $cluster k8s.gcr.io/coredns:1.6.5
    kind load docker-image --name $cluster k8s.gcr.io/etcd:3.4.3-0
    kind load docker-image --name $cluster k8s.gcr.io/kube-apiserver:v1.17.0
    kind load docker-image --name $cluster k8s.gcr.io/kube-controller-manager:v1.17.0
    kind load docker-image --name $cluster k8s.gcr.io/kube-proxy:v1.17.0
    kind load docker-image --name $cluster k8s.gcr.io/kube-scheduler:v1.17.0
done

WCM_SYSTEM_DIR=/go/src/github.com/cisco-app-networking/wcm-system
mkdir -p ${WCM_SYSTEM_DIR}/kubeconfigs/nsm
mkdir -p ${WCM_SYSTEM_DIR}/kubeconfigs/central
kind get kubeconfig --name=kind1 > ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig
kind get kubeconfig --name=kind2 > ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig
kind get kubeconfig --name=kind3 > ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig
cd ${WCM_SYSTEM_DIR}
cat system_topo/config/kind_clustermaps.sh | sed 's@=\${KCONFDIR_ROOT}@=/go/src/github.com/cisco-app-networking/wcm-system@g' > system_topo/config/systest_clustermap.sh
  
docker pull cnns/cnns-ipam:latest
docker pull cnns/connectivity-domain-operator:latest
docker pull cnns/wcmd:latest
docker pull cnns/app-dns-publisher-controller:latest
docker pull cnns/nse-discovery-operator:latest
docker pull cnns/member-core-operator:latest
docker pull cnns/wcm-nse-operator:latest
docker pull ciscoappnetworking/vl3_ucnf-nse:master
docker pull ciscoappnetworking/ucnf-kiknos-vppagent:master
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

for cluster in kind3 kind2 kind1; do
    kind load docker-image --name $cluster kindest/kindnetd:0.5.4
    kind load docker-image --name $cluster registry.opensource.zalan.do/teapot/external-dns:v0.7.1
    kind load docker-image --name $cluster metallb/controller:v0.8.2
    kind load docker-image --name $cluster metallb/speaker:v0.8.2
    kind load docker-image --name $cluster quay.io/coreos/etcd:v3.3.15
    kind load docker-image --name $cluster quay.io/coreos/etcd-operator:v0.9.4
done

for cluster in kind1; do
    kind load docker-image --name $cluster cnns/cnns-ipam:latest
    kind load docker-image --name $cluster cnns/connectivity-domain-operator:latest
done
 
for cluster in kind3 kind2; do
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

echo "======================================= Done creating kind clusters & image loading  ================================="

GOPATH=
echo "All components will be installed and integrated for multi-connectivity domain functionality"
${WCM_SYSTEM_DIR}/system_topo/install_wcm.sh --component-map-file=${WCM_SYSTEM_DIR}/system_topo/config/wcm-3-cluster.sh --cluster-map-file=${WCM_SYSTEM_DIR}/system_topo/config/systest_clustermap.sh

echo ""
echo ""
echo ""
echo "======================================= Done installing WCM  ================================="

. dependencies.env
for cluster in kind1; do
    kind load docker-image --name $cluster cnns/app-dns-publisher-controller:latest
    kind load docker-image --name $cluster cnns/wcmd:latest
    kind load docker-image --name $cluster ciscoappnetworking/nsmrs:vl3_latest
done
for cluster in kind3 kind2; do
    kind load docker-image --name $cluster ciscoappnetworking/vl3_ucnf-nse:master
done
${WCM_SYSTEM_DIR}/system_topo/create_connectdomain.sh --component-map-file=${WCM_SYSTEM_DIR}/system_topo/config/wcm-3-cluster.sh --cluster-map-file=${WCM_SYSTEM_DIR}/system_topo/config/systest_clustermap.sh --nse-tag=${NSE_TAG} --name=example --ipam-prefix=172.100.0.0/16

echo ""
echo ""
echo ""
echo "======================================= Done Creating connectivity domain 'example' ================================="

for cluster in kind3 kind2; do
    kind load docker-image --name $cluster istio/examples-helloworld-v1:latest
done
${WCM_SYSTEM_DIR}/system_topo/deploy_demo_app.sh --component-map-file=${WCM_SYSTEM_DIR}/system_topo/config/wcm-3-cluster.sh --cluster-map-file=${WCM_SYSTEM_DIR}/system_topo/config/systest_clustermap.sh --service-name=example --nsc-delay=10
echo ""
echo ""
echo ""
echo "======================================= Done Deploying 'example' connectivity domain client pods  ================================="

cd  ${WCM_SYSTEM_DIR} && make integration-tests-connectivity label='app=helloworld-example' kcnsmdir=${WCM_SYSTEM_DIR}/kubeconfigs/nsm deployment='helloworld-example'
echo ""
echo ""
echo ""
echo "======================================= Done Testing  ================================="

kind create cluster --name=kind4
for cluster in kind4; do
    kind load docker-image --name $cluster kindest/kindnetd:0.5.4
    kind load docker-image --name $cluster registry.opensource.zalan.do/teapot/external-dns:v0.7.1
    kind load docker-image --name $cluster metallb/controller:v0.8.2
    kind load docker-image --name $cluster metallb/speaker:v0.8.2
    kind load docker-image --name $cluster quay.io/coreos/etcd:v3.3.15
    kind load docker-image --name $cluster quay.io/coreos/etcd-operator:v0.9.4
done

kind get kubeconfig --name=kind4 > ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-4.kubeconfig
cd ${WCM_SYSTEM_DIR}/system_topo/config/; cat kind_clustermaps.sh | sed 's@=\${KCONFDIR_ROOT}@=/go/src/github.com/cisco-app-networking/wcm-system@g' > systest_clustermap.sh


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
done

echo "-------------------------------Add member cluster-------------------------------"
${WCM_SYSTEM_DIR}/system_topo/add_membercluster.sh --kconf=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-4.kubeconfig --nameserver=172.17.0.2:32053 --etcd-addr=172.17.0.2 --etcd-port=32379

echo "-------------------------------Join Connectivity Domain-------------------------------"
${WCM_SYSTEM_DIR}/system_topo/member_join_connectdomain.sh --kconf=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-4.kubeconfig --name=example --ipam-prefix=172.100.0.0/16 --ipam-octet=24


docker exec -t wcm-runner bash -c "cd ${WCM_SYSTEM_DIR} && make k8s-log-dump"
if [ $? -ne 0 ]; then
    echo "error: k8s-log-dump failed!"
    exit 1
fi
docker exec -t wcm-runner bash -c "/go/src/github.com/cisco-app-networking/nsm-nse/scripts/vl3/check_vl3_dataplane.sh --kconf_clus1=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig --kconf_clus2=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig > ${WCM_SYSTEM_DIR}/logs/vl3_dataplane.log"
if [ $? -ne 0 ]; then
    echo "error: check_vl3_dataplane failed!"
    exit 1
fi
mkdir -p /tmp/cluster_state
docker cp wcm-runner:${WCM_SYSTEM_DIR}/logs/. /tmp/cluster_state/


 
 
 
adodon@eti-dev8-kvm2:/go/src/github.com/cisco-app-networking/wcm-system$ ${WCM_SYSTEM_DIR}/system_topo/member_join_connectdomain.sh --kconf=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-4.kubeconfig --name=example --ipam-prefix=172.100.0.0/16 --ipam-octet=24
/go/src/github.com/cisco-app-networking/wcm-system /go/src/github.com/cisco-app-networking/wcm-system
/go/src/github.com/cisco-app-networking/wcm-system
kconfref=cluster1
!kconfref=/go/src/github.com/cisco-app-networking/wcm-system/kubeconfigs/nsm/kind-4.kubeconfig
connectdom_name=example
ipam_prefix=172.100.0.0/16
ipam_octetref=VL3_IPAMOCTET
WCM_DNS_DOMAIN=wcm-cisco.com
GLOBAL_NSR_PORT=31505
INSECURE=true

------------------------------------------------------------
Deploying Connectivity Domain 'example' to member cluster cluster1: IP range=172.100.0.0/16
------------------------------------------------------------

cat <<EOF | kubectl apply --kubeconfig /go/src/github.com/cisco-app-networking/wcm-system/kubeconfigs/nsm/kind-4.kubeconfig -f -
apiVersion: networkservicemesh.io/v1alpha1
kind: NetworkService
metadata:
  name: example
  namespace: wcm-system
spec:
  matches: null
  payload: IP
EOF
networkservice.networkservicemesh.io/example created
Install the connectivity domain endpoint to /go/src/github.com/cisco-app-networking/wcm-system/kubeconfigs/nsm/kind-4.kubeconfig
/go/src/github.com/cisco-app-networking/wcm-system/connectivity_domain_endpoint /go/src/github.com/cisco-app-networking/wcm-system
-----------Deploying Connectivity Domain Endpoint example-----------
action=apply
helm template "/home/adodon/go/src/github.com/cisco-app-networking/wcm-api/deployments/helm/wcm-vl3-nse-op"     --namespace "wcm-system"     --set name="example"     --set insecure="true"     --set replicas="2"     --set nsm.serviceName="example"     --set nsm.jaegerServiceName="wcm-jaeger.nsm-system"     --set nsm.nsmgrServiceName="wcm-nsmgr.nsm-system"     --set nse.nsr.address="example.wcm-cisco.com"     --set nse.nsr.port="31505"     --set nse.nsr.connectivityDomain="example-connectivity-domain"     --set nse.ipam.prefixPool="172.100.0.0/16"     --set nse.ipam.serverAddress="ipam-example.wcm-cisco.com:50051"
Error: path "/home/adodon/go/src/github.com/cisco-app-networking/wcm-api/deployments/helm/wcm-vl3-nse-op" not found
error: no objects passed to apply
Waiting for pods to be Ready
kubectl wait     --kubeconfig="/go/src/github.com/cisco-app-networking/wcm-system/kubeconfigs/nsm/kind-4.kubeconfig"     --timeout=150s     --for condition=Ready     -l wcm-nse="example"     -n="wcm-system"     pod
error: no matching resources found
/go/src/github.com/cisco-app-networking/wcm-system

