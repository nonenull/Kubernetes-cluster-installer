#!/usr/bin/env bash

function systemd._replaceVar() {
    local newServiceFile=$1
    local varStrs=$(grep -oE "\{{[_A-Z]*}}" ${newServiceFile})
    local v
    for v in ${varStrs};do
        local vName="$"KUBE_$(echo ${v}|sed "s/{{//;s/}}//")
        local vValue=$(eval echo ${vName})
        #log.Debug "vName: ${vName} vValue: ${vValue}"
        sed -i "s%${v}%${vValue}%" ${newServiceFile}
        if [[ ! $? -eq 0 ]];then
            log.Exception "${newServiceFile} build failed, set the var \"${v}\" error."
        fi
    done
}

# record
# request sent was ignored (cluster ID mismatch: ...) 相关的错误应该是由于旧的 datadir 数据上的冲突, 删除 datadir 后重新启动服务即可
function systemd.etcd.Build() {
    local KUBE_ETCD_IP=$1
    local KUBE_ETCD_NAME="${KUBE_ETCD_NAME_PREFIX}${KUBE_ETCD_IP}"
    local etcdIP=$2
    local KUBE_ETCD_INITIAL_CLUSTER=""
    local ip
    for ip in $2;do
        local curCluster="${KUBE_ETCD_NAME_PREFIX}${ip}=${KUBE_PROTOCOL}://${ip}:${KUBE_ETCD_LISTEN_PEER_PORT}"
        KUBE_ETCD_INITIAL_CLUSTER+="${curCluster},"
    done
    KUBE_ETCD_INITIAL_CLUSTER=${KUBE_ETCD_INITIAL_CLUSTER:0:-1}
    local newServiceFile="${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_ETCD_SERVICE_NAME}.${KUBE_ETCD_IP}"
    /usr/bin/cp -rf ${SOURCE_SYSTEMD_TEMPLATE_PATH}/${KUBE_ETCD_SERVICE_NAME} ${newServiceFile}
    systemd._replaceVar ${newServiceFile}
}

function systemd.apiserver.Build() {
    local curIp=$1
    local apiServerIP=($2)
    local KUBE_APISERVER_COUNT=${#apiServerIP[@]}
    local etcdIp=${CONFIG_IPDICT["${KUBE_ETCD_HOSTNAME}"]}
    local KUBE_ETCD_SERVERS=""
    local ip
    for ip in ${etcdIp};do
        local curCluster="${KUBE_PROTOCOL}://${ip}:${KUBE_ETCD_LISTEN_CLIENT_PORT}"
        KUBE_ETCD_SERVERS+="${curCluster},"
    done
    KUBE_ETCD_SERVERS=${KUBE_ETCD_SERVERS:0:-1}
    local newServiceFile="${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_APISERVER_SERVICE_NAME}.${curIp}"
    /usr/bin/cp -rf ${SOURCE_SYSTEMD_TEMPLATE_PATH}/${KUBE_APISERVER_SERVICE_NAME} ${newServiceFile}
    systemd._replaceVar ${newServiceFile}
}

function systemd.scheduler.Build() {
    local curIp=$1
    local schedulerIP=$2
    local apiserver=(${CONFIG_IPDICT["${KUBE_APISERVER_HOSTNAME}"]})
    local KUBE_APISERVER_URL=${KUBE_PROTOCOL}://${apiserver[0]}:${KUBE_APISERVER_PORT}
    local newServiceFile="${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_SCHEDULER_SERVICE_NAME}.${curIp}"
    /usr/bin/cp -rf ${SOURCE_SYSTEMD_TEMPLATE_PATH}/${KUBE_SCHEDULER_SERVICE_NAME} ${newServiceFile}
    systemd._replaceVar ${newServiceFile}
}

function systemd.controller-manager.Build() {
    local curIp=$1
    local apiserver=(${CONFIG_IPDICT["${KUBE_APISERVER_HOSTNAME}"]})
    local KUBE_APISERVER_URL=${KUBE_PROTOCOL}://${apiserver[0]}:${KUBE_APISERVER_PORT}
    local newServiceFile="${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_CONTROLLER_MANAGE_SERVICE_NAME}.${curIp}"
    /usr/bin/cp -rf ${SOURCE_SYSTEMD_TEMPLATE_PATH}/${KUBE_CONTROLLER_MANAGE_SERVICE_NAME} ${newServiceFile}
    systemd._replaceVar ${newServiceFile}
}

function systemd.proxy.Build() {
    local curIp=$1
    local newServiceFile="${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_NODE_PROXY_SERVICE_NAME}.${curIp}"
    /usr/bin/cp -rf ${SOURCE_SYSTEMD_TEMPLATE_PATH}/${KUBE_NODE_PROXY_SERVICE_NAME} ${newServiceFile}
    systemd._replaceVar ${newServiceFile}
}

function systemd.kubelet.Build() {
    local curIp=$1
    local newServiceFile="${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_NODE_KUBELET_SERVICE_NAME}.${curIp}"
    /usr/bin/cp -rf ${SOURCE_SYSTEMD_TEMPLATE_PATH}/${KUBE_NODE_KUBELET_SERVICE_NAME} ${newServiceFile}
    systemd._replaceVar ${newServiceFile}
}

function systemd.docker.Build() {
    local curIp=$1
    local newServiceFile="${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_NODE_DOCKER_SERVICE_NAME}.${curIp}"
    /usr/bin/cp -rf ${SOURCE_SYSTEMD_TEMPLATE_PATH}/${KUBE_NODE_DOCKER_SERVICE_NAME} ${newServiceFile}
    systemd._replaceVar ${newServiceFile}
}

function systemd.calico.Build() {
    local curIp=$1
    local etcdIp=${CONFIG_IPDICT["${KUBE_ETCD_HOSTNAME}"]}
    local KUBE_ETCD_ENDPOINTS=""
    local ip
    for ip in ${etcdIp};do
        local curCluster="${KUBE_PROTOCOL}://${ip}:${KUBE_ETCD_LISTEN_CLIENT_PORT}"
        KUBE_ETCD_ENDPOINTS+="${curCluster},"
    done
    KUBE_ETCD_ENDPOINTS=${KUBE_ETCD_ENDPOINTS:0:-1}
    local newServiceFile="${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_NODE_CALICO_SERVICE_NAME}.${curIp}"
    /usr/bin/cp -rf ${SOURCE_SYSTEMD_TEMPLATE_PATH}/${KUBE_NODE_CALICO_SERVICE_NAME} ${newServiceFile}
    systemd._replaceVar ${newServiceFile}
}