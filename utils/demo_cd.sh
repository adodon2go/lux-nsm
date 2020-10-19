#! /bin/bash

read -s -p "Enter Password for sudo: " sudoPW
echo ""
read -s -p "Enter Password for GitHub: " githubPW

RELEASE_BRANCH=release-v0.2.0
RELEASE_VERSION=v0.2.0
ORG=cisco-app-networking
GITHUB_ORG=adodon2go

# Cleanup
echo ""
echo "Performing Cleanup"
echo $sudoPW | sudo -S rm -rf /go
if [ $? -ne 0 ]
then
    echo "error: Cleanup failed!"
    exit 1
fi

# We need to delete it in order to force script to recreate with latest code changes
docker image rm ciscoappnetworking/wcm-runner:latest

# Create the root dir of the code & provide permissions to /go
echo $sudoPW | sudo -S mkdir -p /go/src/github.com/cisco-app-networking
echo $sudoPW | sudo -S chown -R midgard:midgard /go

cd /go/src/github.com/cisco-app-networking

git clone https://github.com/$GITHUB_ORG/wcm-api.git
if [ $? -ne 0 ]; then
    echo "error: Cloning of wcm-api repo failed!"
    exit 1
fi
cd wcm-api/
if [[ "${ORG}" != "$GITHUB_ORG" ]]; then
    git remote add upstream https://github.com/$ORG/wcm-api.git
    git fetch upstream
fi

git checkout ${RELEASE_BRANCH}
if [ $? -ne 0 ]; then
    echo "info: branch ${RELEASE_BRANCH} does not exist on wcm-api repo"
    git checkout -b ${RELEASE_BRANCH}
    if [[ "${ORG}" != "$GITHUB_ORG" ]]; then
        git merge upstream/master
        if [ $? -ne 0 ]; then
            echo "error: merging upstream/master failed on wcm-api!"
            exit 1
        fi
        git push --set-upstream origin ${RELEASE_BRANCH}
        git tag ${RELEASE_VERSION}
        git push origin ${RELEASE_VERSION}
    fi
fi

 
