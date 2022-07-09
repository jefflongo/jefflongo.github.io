#!/bin/bash
set -e

readonly DEPLOY_DIR=$(dirname $(realpath $0))/../assets/files/longbow/release
cp $1 ${DEPLOY_DIR}/dist.zip
crc32 $1 > ${DEPLOY_DIR}/hash.txt
