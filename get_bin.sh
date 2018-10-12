#!/bin/bash

declare -x INSTALL_PATH=$(pwd)
source ${INSTALL_PATH}/src/log.sh

BIN_PATH=${INSTALL_PATH}/bin
BIN_KUBE_PATH=${BIN_PATH}/kubernetes
BIN_ETCD_PATH=${BIN_PATH}/etcd

function bin.kubernetes.Get (){
    local version=$(cat ${BIN_KUBE_PATH}/VERSION)
    local serverUrl="https://storage.googleapis.com/kubernetes-release/release/${version}/kubernetes-server-linux-amd64.tar.gz"
    local clientUrl="https://storage.googleapis.com/kubernetes-release/release/${version}/kubernetes-client-linux-amd64.tar.gz"
    cd ${BIN_KUBE_PATH}
    /usr/bin/rm -rf `ls|egrep -v VERSION`

    local serverFileFullName=$(echo ${serverUrl} | awk -F '/' '{print $NF}')
    local clientFileFullName=$(echo ${clientUrl} | awk -F '/' '{print $NF}')
    wget ${serverUrl}
    wget ${clientUrl}
    tar zxf ./${serverFileFullName} -C ../
    tar zxf ./${clientFileFullName} -C ../
}

function bin.etcd.Get (){
    local version=$(cat ${BIN_ETCD_PATH}/VERSION)
    log.Debug "etcd version === ${version}"
    cd ${BIN_ETCD_PATH}
    # init the path
    /usr/bin/rm `ls|egrep -v VERSION`
    # start
    wget https://github.com/etcd-io/etcd/releases/download/${version}/etcd-${version}-linux-amd64.tar.gz
    tar zxf ./etcd-${version}-linux-amd64.tar.gz
    /usr/bin/mv ./etcd-${version}-linux-amd64/* ./
    /usr/bin/rm -rf ./etcd-${version}-linux-amd64
}

#function bin.calico.Get (){
#
#}

bin.kubernetes.Get
bin.etcd.Get
#bin.calico.Get

