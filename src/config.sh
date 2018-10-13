#!/usr/bin/env bash

# local source config
PROXY="192.168.98.1:1080"
SOURCE_BIN_PATH="${INSTALL_PATH}/bin"
SOURCE_ETC_PATH="${INSTALL_PATH}/etc"
SOURCE_LOGS_PATH="${INSTALL_PATH}/logs"
mkdir -p ${SOURCE_LOGS_PATH}
SOURCE_TMP_PATH="${INSTALL_PATH}/tmp"
mkdir -p ${SOURCE_TMP_PATH}

SOURCE_SYSTEMD_PATH="${SOURCE_ETC_PATH}/systemd"
SOURCE_SYSTEMD_TEMPLATE_PATH="${SOURCE_SYSTEMD_PATH}/templates"
SOURCE_SYSTEMD_PRODUCE_PATH="${SOURCE_SYSTEMD_PATH}/produce"
SOURCE_SSL_PATH="${SOURCE_ETC_PATH}/ssl"

# remote kube config
KUBE_VERSION="v1.10.7"
KUBE_HOSTNAME_SUFFIX=".kube"
KUBE_PROTOCOL="https"
KUBE_SERVICE_CLUSTER_IP_RANGE="10.254.0.0/24"
KUBE_SERVICE_KUBERNETES_IP="10.254.0.1"
KUBE_ETC_PATH="/etc/kubernetes"
KUBE_SSL_PATH="${KUBE_ETC_PATH}/ssl"
KUBE_SYSTEMD_PATH="/usr/lib/systemd/system"

# etcd config
KUBE_ETCD_SERVICE_NAME="kube-etcd.service"
KUBE_ETCD_HOSTNAME="etcd"
KUBE_ETCD_NAME_PREFIX="etcd-"
KUBE_ETCD_DATA_DIR="/var/lib/etcd"
KUBE_ETCD_LISTEN_CLIENT_PORT="2379"
KUBE_ETCD_LISTEN_PEER_PORT="2380"
KUBE_ETCD_INITIAL_CLUSTER_STATE="new" #existing

# api server config
KUBE_APISERVER_SERVICE_NAME="kube-apiserver.service"
KUBE_APISERVER_HOSTNAME="apiserver"
KUBE_APISERVER_PORT="6443"

# scheduler config
KUBE_SCHEDULER_SERVICE_NAME="kube-scheduler.service"
KUBE_SCHEDULER_HOSTNAME="scheduler"

# controller_manager config
KUBE_CONTROLLER_MANAGE_SERVICE_NAME="kube-controller-manager.service"
KUBE_CONTROLLER_MANAGE_HOSTNAME="controller_manager"
KUBE_CONTROLLER_MANAGE_PORT="5443"

# kube node
KUBE_NODE_HOSTNAME="node"

# node kubelet config
KUBE_NODE_KUBELET_SERVICE_NAME="kube-kubelet.service"
KUBE_NODE_KUBELET_CLUSTER_DNS="10.254.0.2"
KUBE_NODE_KUBELET_CLUSTER_DOMAIN="cluster.local"

# kube node proxy config
KUBE_NODE_PROXY_SERVICE_NAME="kube-proxy.service"
KUBE_NODE_PROXY_ADDR="172.30.200.21"
KUBE_NODE_PROXY_CLUSTER_CIDR="169.169.0.0/16"
KUBE_NODE_PROXY_HOSTNAME="node"

# kube node docker config
KUBE_NODE_DOCKER_SERVICE_NAME="kube-docker.service"

# kube node calico config
KUBE_NODE_CALICO_SERVICE_NAME="kube-calico-node.service"