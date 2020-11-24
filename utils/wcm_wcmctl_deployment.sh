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
kind get kubeconfig --name=kind1 > ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig
sleep 20
wcmctl install central-cluster-components -k ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig

kind create cluster --name kind2
kind get kubeconfig --name=kind2 > ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig
sleep 20
wcmctl install member-cluster-components --central-kubeconfig ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig --prefix 254 -k ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig

kind create cluster --name kind3
kind get kubeconfig --name=kind3 > ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig
sleep 20
wcmctl install member-cluster-components --central-kubeconfig ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig --prefix 253 -k ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig

sleep 10
wcmctl create connectivitydomain -k ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig --name example --memberConfig=${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig,${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig

${WCM_SYSTEM_DIR}/system_topo/deploy_demo_app.sh --cluster-map-file=${WCM_SYSTEM_DIR}/system_topo/config/systest_clustermap.sh --component-map-file=${WCM_SYSTEM_DIR}/system_topo/config/wcm-3-cluster.sh --service-name=example --nsc-delay=10

cd  ${WCM_SYSTEM_DIR} && make integration-tests-connectivity label='app=helloworld-example' kcnsmdir=${WCM_SYSTEM_DIR}/kubeconfigs/nsm deployment='helloworld-example'