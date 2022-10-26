#!/bin/bash
set -e

readonly DEPLOY_DIR=$(dirname $(realpath $0))/../assets/files/longbow/beta
cp $1 ${DEPLOY_DIR}/dist.zip
crc32 $1 > ${DEPLOY_DIR}/hash.txt

git add ${DEPLOY_DIR}
git commit -m "auto-pushing longbow deployment"
git push origin jeff
