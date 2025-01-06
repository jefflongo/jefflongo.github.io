#!/bin/bash
set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path to distribution package>"
    exit 1
fi

read -p "You're about to push to the stable track. Press y to continue or n to abort: " -r
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo Aborted
    exit 1
fi


readonly DEPLOY_DIR=$(dirname $(realpath $0))/../assets/files/longbow/release
cp $1 ${DEPLOY_DIR}/dist.zip
crc32 $1 > ${DEPLOY_DIR}/hash.txt

git add ${DEPLOY_DIR}
git commit -m "chore: deploying longbow"
git push origin jeff
