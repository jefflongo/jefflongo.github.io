#!/bin/bash
set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <path to distribution package>"
    exit 1
fi

readonly DEPLOY_DIR=$(dirname $(realpath $0))/../assets/files/longbow/beta
cp $1 ${DEPLOY_DIR}/dist.zip
crc32 $1 > ${DEPLOY_DIR}/hash.txt

git add ${DEPLOY_DIR}
git commit -m "deploying longbow beta"
git push origin jeff
