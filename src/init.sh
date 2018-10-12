#!/usr/bin/env bash

function init.Start() {
    local initCheckFile="${INSTALL_PATH}/tmp/init_check"
    cat /dev/null > ${initCheckFile}

    for key in $(echo ${!CONFIG_IPDICT[*]});do
        local ips=${CONFIG_IPDICT[${key}]}
        local ip
        local proxyCmd=""
        if [[ ! ${PROXY} == "" ]];then
            proxyCmd="export http_proxy=${PROXY}"
        fi
        local installDocker
        if [[ ${key} == "node" ]];then
            installDocker="yum install -y yum-plugin-fastestmirror
yum remove -y docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-selinux docker-engine-selinux docker-engine
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum-config-manager --enable docker-ce-edge
yum install -y docker-ce"
        fi
        local keyIpNum=0
        for ip in ${ips};do
            log.Debug "ready to init ${key} --- ${ip}"
            #log.Debug "ready to in t ${ip}"
            local  isIpExist=$(grep "${ip}" ${initCheckFile} | wc -l)
            if [[ ${isIpExist} -eq 0 ]];then
                init._item
                keyIpNum=$[$keyIpNum+1]
            fi
        done
    done
}


function init._item() {
    ssh root@${ip} /bin/bash << EOF
rm -rf /etc/kubernetes
rm -rf /etc/systemd/system/kube-*
systemctl stop firewalld
systemctl disable firewalld
setenforce 0
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
mkdir -p ${KUBE_SSL_PATH}
mkdir /var/log/k8s
timedatectl set-timezone Asia/Shanghai
sed -i -e '/(kubectl completion bash)/d' /etc/profile
echo "source <(kubectl completion bash)" >> /etc/profile && source /etc/profile
${proxyCmd}
${installDocker}
EOF
    if [[ $? -eq 0 ]];then
        echo "${ip}" >> ${initCheckFile}
        log.Info "${ip} init successed ..."
    fi
}