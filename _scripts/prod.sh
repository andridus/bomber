#!/bin/bash
docker rmi andridus/bomber:testing -f
docker build -f _docker/Dockerfile.prod -t andridus/bomber:testing . && 
echo "finish!"
docker run -e DATABASE_URL="ecto://h2sadmin:DsJ85&%;@cloud.h2sistemas.com.br:65432/bomber_prod" -e PHX_HOST="localhost" -e PHX_PORT="4002" -e SECRET_KEY_BASE="epvxOem86lX447QdouwPoasdF9dtYAExG3h3f0v3uT1cb1gnr3oaIR0xFojxW0cQ"  -it -p 4002:4000  andridus/bomber:testing