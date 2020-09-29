#! /bin/bash

WCM_RUNNER_TAG=v0.1.0
WCM_SYSTEM_DIR=/go/src/github.com/cisco-app-networking/wcm-system
TOPO_DIR=$WCM_SYSTEM_DIR/system_topo/

docker rm -f $(docker ps -a | grep wcm | awk '{ print $1 }')


docker run -d --rm --name=wcm -v /var/run/docker.sock:/var/run/docker.sock --network=host cnns/wcm-runner:$WCM_RUNNER_TAG bash -c "while [[ 1 ]]; do sleep 900; done"

docker exec -t wcm bash -c "mkdir -p ${WCM_SYSTEM_DIR}/kubeconfigs/nsm"
docker exec -t wcm bash -c "mkdir -p ${WCM_SYSTEM_DIR}/kubeconfigs/central"
docker exec -t wcm bash -c "kind get kubeconfig --name=kind-1 > ${WCM_SYSTEM_DIR}/kubeconfigs/central/kind-1.kubeconfig"
docker exec -t wcm bash -c "kind get kubeconfig --name=kind-2 > ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-2.kubeconfig"
docker exec -t wcm bash -c "kind get kubeconfig --name=kind-3 > ${WCM_SYSTEM_DIR}/kubeconfigs/nsm/kind-3.kubeconfig"
docker exec -t wcm bash -c "cd ${WCM_SYSTEM_DIR}/system_topo/config/; cat kind_clustermaps.sh | sed 's@\${HOME}@/go/src/github.com/cisco-app-networking/wcm-system@g' > systest_clustermap.sh"


docker exec -t wcm sh -c "cd $TOPO_DIR; ./setup_kind_clusters.sh"
docker exec -t wcm bash -c ". ${WCM_SYSTEM_DIR}/dependencies.env; sleep 10; ${WCM_SYSTEM_DIR}/system_topo/create_connectdomain.sh --component-map-file=${WCM_SYSTEM_DIR}/system_topo/config/wcm-3-cluster.sh --cluster-map-file=${WCM_SYSTEM_DIR}/system_topo/config/systest_clustermap.sh --nse-tag=${NSE_TAG} --name=example --ipam-prefix=172.100.0.0/16"

docker exec -t wcm sh -c "$WCM_SYSTEM_DIR/ci/runner/deploy_vl3.sh --kconfdir=${HOME}/kubeconfigs/nsm --service-name=example --nsc-delay=60"

make integration-tests-connectivity label="app=helloworld-example"; kcnsmdir=${HOME}/kubeconfigs/nsmdeployment="helloworld-example"


