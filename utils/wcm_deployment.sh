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
rm cmd.errors
docker rm -f $(docker ps -a | grep wcm-runner | awk '{ print $1 }')
kind delete cluster --name=kind1
kind delete cluster --name=kind2
kind delete cluster --name=kind3
# We need to delete it in order to force script to recreate with latest code changes
docker image rm ciscoappnetworking/wcm-runner:latest

WCM_SYSTEM_REPO=github.com/cisco-app-networking/wcm-system.git
WCM_SYSTEM_BRANCH=master

WCM_COMMON_REPO=github.com/cisco-app-networking/wcm-common.git
WCM_COMMON_BRANCH=master

WCM_API_REPO=github.com/cisco-app-networking/wcm-api.git
WCM_API_BRANCH=master

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

#git config --global credential.helper 'cache --timeout=36000'

#NSE_REPO=https://github.com/adodon2go/nsm-nse.git
#NSE_BRANCH=rebranding2

#NSM_REPO=https://github.com/cisco-app-networking/networkservicemesh.git
#NSM_BRANCH=vl3_latest
#echo $sudoPW | sudo -S mkdir -p /go/src/github.com/cisco-app-networking/nsm-nse
echo $sudoPW | sudo -S mkdir -p /go/gopath
echo $sudoPW | sudo -S mkdir -p /go/src/github.com/cisco-app-networking
 
export GOPATH=/go/gopath
echo $sudoPW | sudo -S chown -R adodon:adodon /go

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

echo "======================================= Done Cloning repos  ================================="

## This is for job e2e-kind-test
cd ${WCM_SYSTEM_DIR}
GOPATH=
. dependencies.env 
NSM_REPO=${NSM_REPO} NSM_BRANCH=${NSM_BRANCH} NSE_REPO=${NSE_REPO} NSE_BRANCH=${NSE_BRANCH} WCM_COMMON_BRANCH=${WCM_COMMON_BRANCH} make docker-ci-runner DEPENDENCIES=${WCM_SYSTEM_DIR}/dependencies.env 

docker run -d --rm -v /var/run/docker.sock:/var/run/docker.sock --name=wcm-runner --network=host -e GOPATH=/go -e DEPENDENCIES=${WCM_SYSTEM_DIR}/dependencies.env -e CIRCLE_SHA1=${CIRCLE_SHA1} ciscoappnetworking/wcm-runner:latest bash -c "while [[ 1 ]]; do sleep 900; done"

docker exec -t wcm-runner bash -c "kind create cluster --name kind1" 
docker exec -t wcm-runner bash -c "kind create cluster --name kind2" 
docker exec -t wcm-runner bash -c "kind create cluster --name kind3"

docker exec -t wcm-runner bash -c "mkdir -p ${WCM_SYSTEM_DIR}/kubeconfigs/nsm"
docker exec -t wcm-runner bash -c "mkdir -p ${WCM_SYSTEM_DIR}/kubeconfigs/central"
docker exec -t wcm-runner bash -c "kind get kubeconfig --name=kind1 > ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig"
docker exec -t wcm-runner bash -c "kind get kubeconfig --name=kind2 > ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig"
docker exec -t wcm-runner bash -c "kind get kubeconfig --name=kind3 > ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig"
docker exec -t wcm-runner bash -c "cd /go/src/github.com/cisco-app-networking/wcm-system; cat system_topo/config/kind_clustermaps.sh | sed 's@\${HOME}@/go/src/github.com/cisco-app-networking/wcm-system@g' > system_topo/config/systest_clustermap.sh"
  
# docker pull cnns/cnns-ipam:latest
# docker pull cnns/connectivity-domain-operator:latest
# docker pull cnns/nsmrs:latest
# docker pull cnns/vl3_ucnf-nse:master
# docker pull cnns/ucnf-kiknos-vppagent:master
# docker pull cnns/app-dns-publisher-controller:latest
# docker pull cnns/nse-discovery-operator:latest
# docker pull ciscoappnetworking/nsmdp:vl3_latest
# docker pull ciscoappnetworking/nsmd:vl3_latest
# docker pull ciscoappnetworking/nsmd-k8s:vl3_latest
# docker pull ciscoappnetworking/vppagent-forwarder:vl3_latest
# docker pull ciscoappnetworking/proxy-nsmd:vl3_latest
# docker pull ciscoappnetworking/proxy-nsmd-k8s:vl3_latest
# docker pull networkservicemesh/crossconnect-monitor:master
# docker pull networkservicemesh/nsm-init:master
# docker pull networkservicemesh/nsm-dns-init:master
# docker pull networkservicemesh/nsm-monitor:master
# docker pull networkservicemesh/coredns:master
# docker pull ciscoappnetworking/admission-webhook:release-v0.1.0
# docker pull networkservicemesh/nsm-spire:master


# for cluster in kind1; do
    # kind load docker-image --name $cluster quay.io/coreos/etcd:v3.2.13
    # kind load docker-image --name $cluster quay.io/coreos/etcd-operator:v0.9.4
    # kind load docker-image --name $cluster metallb/controller:v0.8.2
    # kind load docker-image --name $cluster metallb/speaker:v0.8.2
    # kind load docker-image --name $cluster registry.opensource.zalan.do/teapot/external-dns:v0.7.1
    # kind load docker-image --name $cluster cnns/cnns-ipam:latest
    # kind load docker-image --name $cluster cnns/connectivity-domain-operator:latest
    # kind load docker-image --name $cluster cnns/nsmrs:latest
# done
 
# for cluster in kind2 kind3; do
    # kind load docker-image --name $cluster cnns/vl3_ucnf-nse:master
    # kind load docker-image --name $cluster cnns/ucnf-kiknos-vppagent:master
    # kind load docker-image --name $cluster gcr.io/spiffe-io/wait-for-it
    # kind load docker-image --name $cluster gcr.io/spiffe-io/spire-agent:0.9.0
    # kind load docker-image --name $cluster gcr.io/spiffe-io/spire-server:0.9.0
    # kind load docker-image --name $cluster ciscoappnetworking/nsmdp:release-v0.1.0
    # kind load docker-image --name $cluster ciscoappnetworking/nsmd:release-v0.1.0
    # kind load docker-image --name $cluster ciscoappnetworking/nsmd-k8s:release-v0.1.0
    # kind load docker-image --name $cluster ciscoappnetworking/vppagent-forwarder:release-v0.1.0
    # kind load docker-image --name $cluster ciscoappnetworking/proxy-nsmd:release-v0.1.0
    # kind load docker-image --name $cluster ciscoappnetworking/proxy-nsmd-k8s:release-v0.1.0
    # kind load docker-image --name $cluster registry.opensource.zalan.do/teapot/external-dns:v0.7.1
    # kind load docker-image --name $cluster metallb/controller:v0.8.2
    # kind load docker-image --name $cluster metallb/speaker:v0.8.2
    # kind load docker-image --name $cluster networkservicemesh/crossconnect-monitor:master
    # kind load docker-image --name $cluster networkservicemesh/nsm-init:master
    # kind load docker-image --name $cluster networkservicemesh/nsm-dns-init:master
    # kind load docker-image --name $cluster networkservicemesh/nsm-monitor:master
    # kind load docker-image --name $cluster networkservicemesh/coredns:master
    # kind load docker-image --name $cluster ciscoappnetworking/admission-webhook:release-v0.1.0
    # kind load docker-image --name $cluster networkservicemesh/nsm-spire:master
    # kind load docker-image --name $cluster jaegertracing/all-in-one:1.14.0
    # kind load docker-image --name $cluster rancher/local-path-provisioner:v0.0.11
    # kind load docker-image --name $cluster skydive/skydive:0.24.0
    # kind load docker-image --name $cluster skydive/skydive:0.23.0
    # kind load docker-image --name $cluster quay.io/coreos/etcd:v3.3.15
    # kind load docker-image --name $cluster ciscolabs/kiknos:latest 
    # kind load docker-image --name $cluster cnns/app-dns-publisher-controller:latest
    # kind load docker-image --name $cluster cnns/nse-discovery-operator:latest
# done

echo "======================================= Done creating kind clusters & image loading  ================================="

GOPATH=
echo "All components will be installed and integrated for multi-connectivity domain functionality"
docker exec -t wcm-runner ${WCM_SYSTEM_DIR}/system_topo/install_wcm.sh --component-map-file=${WCM_SYSTEM_DIR}/system_topo/config/wcm-3-cluster.sh --cluster-map-file=${WCM_SYSTEM_DIR}/system_topo/config/systest_clustermap.sh --spire-disabled 2>&1 | tee cmd.errors
if [ $? -ne 0 ]; then
    echo "error: Install WCM failed!"
    exit 1
fi
echo ""
echo "====== Script errors & failures messages ====="
cat cmd.errors | grep -i error
cat cmd.errors | grep -i fail
cat cmd.errors | grep -i "timed out"
echo ""
echo "======================================= Done installing WCM  ================================="
rm cmd.errors

docker exec -t wcm-runner bash -c "cd ${WCM_SYSTEM_DIR} && make resiliency-tests KUBECONFIG_CTRL=${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig KUBECONFIG_MEMBER1=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig KUBECONFIG_MEMBER2=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig" 2>&1 | tee cmd.errors
echo "======================================= Done running resiliency tests  ================================="
echo ""

sleep 10
docker exec -t wcm-runner bash -c "${WCM_SYSTEM_DIR}/system_topo/create_connectdomain.sh --component-map-file=${WCM_SYSTEM_DIR}/system_topo/config/wcm-3-cluster.sh --cluster-map-file=${WCM_SYSTEM_DIR}/system_topo/config/systest_clustermap.sh --nse-tag=${NSE_TAG} --name=example --ipam-prefix=172.100.0.0/16" 2>&1 | tee cmd.errors
if [ $? -ne 0 ]; then
    echo "error: Create connectivity domain failed!"
    exit 1
fi
echo ""
echo "====== Script errors & failures messages ====="
cat cmd.errors | grep -i error
cat cmd.errors | grep -i fail
echo ""
echo "======================================= Done Creating connectivity domain  ================================="
rm cmd.errors

sleep 5
docker exec -t wcm-runner ${WCM_SYSTEM_DIR}/system_topo/deploy_demo_app.sh --cluster-map-file=${WCM_SYSTEM_DIR}/system_topo/config/systest_clustermap.sh --component-map-file=${WCM_SYSTEM_DIR}/system_topo/config/wcm-3-cluster.sh --service-name=example --nsc-delay=10 2>&1 | tee cmd3.errors
if [ $? -ne 0 ]; then
    echo "error: Deploy Demo App failed!"
    exit 1
fi
echo ""
echo "====== Script errors & failures messages ====="
cat cmd3.errors | grep -i error
cat cmd3.errors | grep -i fail
echo ""
echo "======================================= Done Deploying Demo App  ================================="

docker exec -t wcm-runner bash -c "cd  ${WCM_SYSTEM_DIR} && make integration-tests-connectivity label='app=helloworld-example' kcnsmdir=${WCM_SYSTEM_DIR}/kubeconfigs/nsm deployment='helloworld-example'" 2>&1 | tee cmd4.errors
if [ $? -ne 0 ]; then
    echo "error: integration-tests-connectivity failed!"
    exit 1
fi
echo "Check externaldns-etcd connectivity"
docker exec -t wcm-runner bash -c "cd ${WCM_SYSTEM_DIR} && make integration-test-externaldns KUBECONFIG_CTRL=${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig EXTERNALDNS_NS=wcm-system" 2>&1 | tee cmd4.errors
if [ $? -ne 0 ]; then
    echo "error: integration-test-externaldns failed!"
    exit 1
fi
echo "Check app-dns-publisher: confirm client DNS resolution"
docker exec -t wcm-runner bash -c "cd ${WCM_SYSTEM_DIR} && make integration-test-appdnspublisher KUBECONFIG_CTRL=${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig KUBECONFIG_MEMBER1=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig KUBECONFIG_MEMBER2=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig SERVICE_NAME=example" 2>&1 | tee cmd4.errors
if [ $? -ne 0 ]; then
    echo "error: integration-test-appdnspublisher failed!"
    exit 1
fi
docker exec -t wcm-runner bash -c "cd ${WCM_SYSTEM_DIR} && make integration-tests-deployment KUBECONFIG_CTRL=${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig KUBECONFIG_MEMBER1=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig KUBECONFIG_MEMBER2=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig SERVICE_NAME=example" 2>&1 | tee cmd4.errors
if [ $? -ne 0 ]; then
    echo "error: integration-tests-deployment failed!"
    exit 1
fi

echo ""
echo "====== Script errors & failures messages ====="
cat cmd4.errors | grep -i error
cat cmd4.errors | grep -i fail
echo ""
echo "======================================= Done Testing  ================================="


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


 
