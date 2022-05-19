#!/bin/bash
VERSION=$@
docker build -f _docker/Dockerfile.prod -t andridus/bomber . && 
docker tag andridus/bomber andridus/bomber:$VERSION && 
docker --config ~/_andridus push andridus/bomber &&
docker --config ~/_andridus push andridus/bomber:$VERSION
echo "finish!"