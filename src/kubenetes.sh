#!/usr/bin/env bash

function kubenetes.etcd.Install() {
    local etcdIp=${CONFIG_IPDICT["${KUBE_ETCD_HOSTNAME}"]}
    #log.Debug "${etcdIp}"
    local ip
    for ip in ${etcdIp};do
        log.Debug "start to install ${ip} : ${KUBE_ETCD_SERVICE_NAME}"
        kubenetes.etcd._install
    done
    log.Info "etcd installed, please use etcdctl to check ..."
}

function kubenetes.etcd._install() {
    systemd.etcd.Build ${ip} "${etcdIp}"
    log.Debug "copy service file to remote ${ip}"
    scp -C  ${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_ETCD_SERVICE_NAME}.${ip} root@${ip}:${KUBE_SYSTEMD_PATH}/${KUBE_ETCD_SERVICE_NAME}
    log.Debug "copy service file to remote done.."
    scp -C  ${SOURCE_BIN_PATH}/etcd/etcd* root@${ip}:/tmp/
    ssh root@${ip} /bin/bash << EOF
systemctl daemon-reload
systemctl stop ${KUBE_ETCD_SERVICE_NAME}
mv /tmp/etcd* /usr/bin/
chmod +x /usr/bin/etcd*
/usr/bin/rm -rf ${KUBE_ETCD_DATA_DIR}
systemctl enable ${KUBE_ETCD_SERVICE_NAME}
systemctl start ${KUBE_ETCD_SERVICE_NAME}
EOF
}

function kubenetes.apiserver.Install(){
    local apiServerIP=${CONFIG_IPDICT["${KUBE_APISERVER_HOSTNAME}"]}
    local ip
    for ip in ${apiServerIP};do
        log.Debug "start to install ${ip} : ${KUBE_APISERVER_SERVICE_NAME} ${ip}"
        kubenetes.apiserver._install
    done
    log.Info "apiserver installed"
}

function kubenetes.apiserver._install(){
    systemd.apiserver.Build ${ip} "${apiServerIP}"
    scp -C  ${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_APISERVER_SERVICE_NAME}.${ip} root@${ip}:${KUBE_SYSTEMD_PATH}/${KUBE_APISERVER_SERVICE_NAME}
    scp -C  ${SOURCE_BIN_PATH}/kubernetes/server/bin/kube-apiserver ${SOURCE_BIN_PATH}/kubernetes/client/bin/kubectl root@${ip}:/tmp/
    ssh root@${ip} /bin/bash << EOF
systemctl daemon-reload
systemctl stop ${KUBE_APISERVER_SERVICE_NAME}
mv /tmp/kube-apiserver /tmp/kubectl /usr/bin/
chmod +x /usr/bin/kube-apiserver /usr/bin/kubectl
systemctl enable ${KUBE_APISERVER_SERVICE_NAME}
systemctl start ${KUBE_APISERVER_SERVICE_NAME}
EOF
}

function kubenetes.client.config._create() {
    log.Debug "start to create ${kubeType} config..."
    # generate the kube-config file
    local apiserver=(${CONFIG_IPDICT["${KUBE_APISERVER_HOSTNAME}"]})
    local kubectlCmd="${SOURCE_BIN_PATH}/kubernetes/client/bin/kubectl"
    local clusterName="kubernetes"
    local credentialsName="system:kube-${kubeType}"

    rm -rf ${SOURCE_KUBE_CONFIG_PATH}
    ${kubectlCmd} config set-cluster ${clusterName} \
    --certificate-authority=${SOURCE_SSL_PATH}/ca.pem \
    --embed-certs=true \
    --server=${KUBE_PROTOCOL}://${apiserver[0]}:${KUBE_APISERVER_PORT} \
    --kubeconfig=${SOURCE_KUBE_CONFIG_PATH}

    ${kubectlCmd} config set-credentials ${credentialsName} \
    --embed-certs=true \
    --client-certificate=${SOURCE_SSL_PATH}/client.pem \
    --client-key=${SOURCE_SSL_PATH}/client-key.pem \
    --kubeconfig=${SOURCE_KUBE_CONFIG_PATH}

    ${kubectlCmd} config set-context ${credentialsName}@${clusterName} \
    --cluster=kubernetes \
    --user=${credentialsName} \
    --kubeconfig=${SOURCE_KUBE_CONFIG_PATH}

    ${kubectlCmd} config use-context ${credentialsName}@${clusterName} --kubeconfig=${SOURCE_KUBE_CONFIG_PATH}
}

function kubenetes.scheduler.Install(){
    local kubeType="scheduler"
    local KUBE_CONFIG_NAME="${kubeType}-kubeconfig"
    local KUBE_CONFIG_PATH="${KUBE_ETC_PATH}/${KUBE_CONFIG_NAME}"
    local SOURCE_KUBE_CONFIG_PATH="${SOURCE_ETC_PATH}/${KUBE_CONFIG_NAME}"
    kubenetes.client.config._create

    local schedulerIP=${CONFIG_IPDICT["${KUBE_SCHEDULER_HOSTNAME}"]}
    local ip
    for ip in ${schedulerIP};do
        kubenetes.scheduler._install ${ip}
    done
    log.Info "scheduler installed"
}

function kubenetes.scheduler._install(){
    log.Debug "start to install ${ip} : ${KUBE_SCHEDULER_SERVICE_NAME}"
    systemd.scheduler.Build ${ip} "${schedulerIP}"
    scp -C  ${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_SCHEDULER_SERVICE_NAME}.${ip} root@${ip}:${KUBE_SYSTEMD_PATH}/${KUBE_SCHEDULER_SERVICE_NAME}
    scp -C  ${SOURCE_BIN_PATH}/kubernetes/server/bin/kube-scheduler root@${ip}:/tmp/
    scp -C  ${SOURCE_KUBE_CONFIG_PATH} root@${ip}:${KUBE_ETC_PATH}/
    ssh root@${ip} /bin/bash  << EOF
systemctl daemon-reload
systemctl stop ${KUBE_SCHEDULER_SERVICE_NAME}
mv /tmp/kube-scheduler /usr/bin/
chmod +x /usr/bin/kube-scheduler
systemctl enable ${KUBE_SCHEDULER_SERVICE_NAME}
systemctl start ${KUBE_SCHEDULER_SERVICE_NAME}
EOF
}

function kubenetes.controller-manager.Install(){
    local kubeType="controller-manager"
    local KUBE_CONFIG_NAME="${kubeType}-kubeconfig"
    local KUBE_CONFIG_PATH="${KUBE_ETC_PATH}/${KUBE_CONFIG_NAME}"
    local SOURCE_KUBE_CONFIG_PATH="${SOURCE_ETC_PATH}/${KUBE_CONFIG_NAME}"
    kubenetes.client.config._create
    local controllerIP=${CONFIG_IPDICT["${KUBE_CONTROLLER_MANAGE_HOSTNAME}"]}
    local ip
    for ip in ${controllerIP};do
        log.Debug "start to install ${ip} : ${KUBE_CONTROLLER_MANAGE_SERVICE_NAME}"
        kubenetes.controller-manager._install ${ip}
    done
    log.Info "controller-manager installed"
}

function kubenetes.controller-manager._install(){
    ip=$1
    systemd.controller-manager.Build ${ip}
    scp -C  ${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_CONTROLLER_MANAGE_SERVICE_NAME}.${ip} root@${ip}:${KUBE_SYSTEMD_PATH}/${KUBE_CONTROLLER_MANAGE_SERVICE_NAME}
    scp -C  ${SOURCE_BIN_PATH}/kubernetes/server/bin/kube-controller-manager root@${ip}:/tmp/
    scp -C  ${SOURCE_KUBE_CONFIG_PATH} root@${ip}:${KUBE_ETC_PATH}/
    ssh root@${ip} /bin/bash  << EOF
systemctl daemon-reload
systemctl stop ${KUBE_CONTROLLER_MANAGE_SERVICE_NAME}
mv /tmp/kube-controller-manager /usr/bin/
chmod +x /usr/bin/kube-controller-manager
systemctl enable ${KUBE_CONTROLLER_MANAGE_SERVICE_NAME}
systemctl start ${KUBE_CONTROLLER_MANAGE_SERVICE_NAME}
EOF
}

function kubenetes.node.Install() {
    local nodeIP=${CONFIG_IPDICT["${KUBE_NODE_HOSTNAME}"]}
    local ip
    for ip in ${nodeIP};do
        kubenetes.docker._install ${ip}
#        kubenetes.calico._install ${ip}
        kubenetes.kube-proxy._install ${ip}
        kubenetes.kubelet._install ${ip}
    done
}

function kubenetes.docker._install() {
    local curIp=$1
    log.Debug "start to install docker ${curIp}"
    systemd.docker.Build ${curIp}
    scp -C ${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_NODE_DOCKER_SERVICE_NAME}.${curIp} root@${curIp}:${KUBE_SYSTEMD_PATH}/${KUBE_NODE_DOCKER_SERVICE_NAME}
    ssh root@${curIp} /bin/bash << EOF
systemctl daemon-reload
systemctl disable docker
systemctl enable ${KUBE_NODE_DOCKER_SERVICE_NAME}
systemctl restart ${KUBE_NODE_DOCKER_SERVICE_NAME}
EOF
    log.Info "install docker ${curIp} over"
}

function kubenetes.calico._install() {
    local curIp=$1
    systemd.calico.Build ${curIp}
    scp -C  ${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_NODE_CALICO_SERVICE_NAME}.${curIp} root@${curIp}:${KUBE_SYSTEMD_PATH}/${KUBE_NODE_CALICO_SERVICE_NAME}
    ssh root@${curIp} /bin/bash << EOF
systemctl daemon-reload
systemctl enable ${KUBE_NODE_CALICO_SERVICE_NAME}
systemctl restart ${KUBE_NODE_CALICO_SERVICE_NAME}
EOF
}

function kubenetes.kube-proxy._install() {
    local kubeType="proxy"
    local KUBE_CONFIG_NAME="${kubeType}-kubeconfig"
    local KUBE_CONFIG_PATH="${KUBE_ETC_PATH}/${KUBE_CONFIG_NAME}"
    local SOURCE_KUBE_CONFIG_PATH="${SOURCE_ETC_PATH}/${KUBE_CONFIG_NAME}"
    kubenetes.client.config._create

    local curIp=$1
    log.Debug "start to install ${curIp} : ${KUBE_NODE_PROXY_SERVICE_NAME}"
    systemd.proxy.Build ${curIp}
    scp -C  ${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_NODE_PROXY_SERVICE_NAME}.${curIp} root@${curIp}:${KUBE_SYSTEMD_PATH}/${KUBE_NODE_PROXY_SERVICE_NAME}
    scp -C  ${SOURCE_BIN_PATH}/kubernetes/server/bin/kube-proxy root@${curIp}:/tmp/
    scp -C  ${SOURCE_KUBE_CONFIG_PATH} root@${curIp}:${KUBE_ETC_PATH}/
    ssh root@${curIp} /bin/bash << EOF
yum install -y ipset
systemctl daemon-reload
systemctl stop ${KUBE_NODE_PROXY_SERVICE_NAME}
mv /tmp/kube-proxy /usr/bin/
chmod +x /usr/bin/kube-proxy
systemctl enable ${KUBE_NODE_PROXY_SERVICE_NAME}
systemctl start ${KUBE_NODE_PROXY_SERVICE_NAME}
EOF
    log.Info "install ${KUBE_NODE_PROXY_SERVICE_NAME} ${curIp} over"
}

function kubenetes.kubelet._install() {
    local kubeType="kubelet"
    local KUBE_CONFIG_NAME="${kubeType}-kubeconfig"
    local KUBE_CONFIG_PATH="${KUBE_ETC_PATH}/${KUBE_CONFIG_NAME}"
    local SOURCE_KUBE_CONFIG_PATH="${SOURCE_ETC_PATH}/${KUBE_CONFIG_NAME}"
    kubenetes.client.config._create

    local curIp=$1
    log.Debug "start to install ${curIp} : ${KUBE_NODE_KUBELET_SERVICE_NAME}"
    systemd.kubelet.Build ${curIp}
    scp -C  ${SOURCE_SYSTEMD_PRODUCE_PATH}/${KUBE_NODE_KUBELET_SERVICE_NAME}.${curIp} root@${curIp}:${KUBE_SYSTEMD_PATH}/${KUBE_NODE_KUBELET_SERVICE_NAME}
    scp -C  ${SOURCE_BIN_PATH}/kubernetes/server/bin/kubelet root@${curIp}:/tmp/
    scp -C  ${SOURCE_KUBE_CONFIG_PATH} root@${curIp}:${KUBE_ETC_PATH}/
    ssh root@${curIp} /bin/bash << EOF
systemctl daemon-reload
systemctl stop ${KUBE_NODE_KUBELET_SERVICE_NAME}
chmod +x /usr/bin/kubelet
systemctl stop docker
systemctl enable ${KUBE_NODE_KUBELET_SERVICE_NAME}
systemctl start ${KUBE_NODE_KUBELET_SERVICE_NAME}
EOF
    log.Info "install ${KUBE_NODE_KUBELET_SERVICE_NAME} ${curIp} over"
}