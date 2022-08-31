#!/bin/sh
set -o errexit

reg_name='registry'
reg_port='5000'
cluster_name=$1
echo $cluster_name

# TODO: this should check if the cluster exists first
kind delete cluster --name=${cluster_name}

# create registry container unless it already exists
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run -d --restart=always -p "127.0.0.1:${reg_port}:5000" --name "${reg_name}" registry:2
fi

# create a cluster with the local registry enabled in containerd
kind create cluster --name "${cluster_name}" --config ./kind/kind-cluster.yaml

# connect the registry to the cluster network if not already connected
if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${reg_name}")" = 'null' ]; then
  docker network connect "kind" "${reg_name}"
fi

# Document the local registry
# https://github.com/kubernetes/enhancements/tree/master/keps/sig-cluster-lifecycle/generic/1755-communicating-a-local-registry
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-registry-hosting
  namespace: kube-public
data:
  localRegistryHosting.v1: |
    host: "127.0.0.1:${reg_port}"
    help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

