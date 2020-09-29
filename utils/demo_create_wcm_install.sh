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
docker rm -f $(docker ps -a | grep wcm-runner | awk '{ print $1 }')
kind delete cluster --name=kind1
kind delete cluster --name=kind2
kind delete cluster --name=kind3
# We need to delete it in order to force script to recreate with latest code changes
docker image rm cnns/wcm-runner:latest

WCM_SYSTEM_REPO=github.com/adodon2go/wcm-system.git
WCM_SYSTEM_BRANCH=latest

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

echo "======================================= Done Cloning repos  ================================="

## This is for job e2e-kind-test
cd ${WCM_SYSTEM_DIR}
GOPATH=
. dependencies.env 
NSM_REPO=${NSM_REPO} NSM_BRANCH=${NSM_BRANCH} NSE_REPO=${NSE_REPO} NSE_BRANCH=${NSE_BRANCH} WCM_COMMON_BRANCH=${WCM_COMMON_BRANCH} make docker-ci-runner DEPENDENCIES=${WCM_SYSTEM_DIR}/dependencies.env 

docker run -d --rm --name=wcm -v /var/run/docker.sock:/var/run/docker.sock --network=host cnns/wcm-runner:latest bash -c "while [[ 1 ]]; do sleep 900; done"
docker exec -it wcm sh
cd /go/src/github.com/cisco-app-networking/wcm-system/system_topo/
./setup_kind_clusters.sh