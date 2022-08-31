#!/bin/sh
set -o errexit
cluster_name=$1
echo $cluster_name
# local context 
kubectl config use-context kind-${cluster_name}
skaffold config set default-repo 127.0.0.1:5000
skaffold config set insecure-registries http://127.0.0.1:5000
skaffold config set local-cluster true 
skaffold config set kind-disable-load true