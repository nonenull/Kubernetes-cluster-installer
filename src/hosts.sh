#!/usr/bin/env bash

# preinit
declare -A CONFIG_IPDICT
declare -A HOSTS_DICT
function hosts._load(){
    while read line;do
        local hostArr=(${line// / })
        local ip=${hostArr[0]}
        local rolaName=${hostArr[1]}
        #log.Info "ip=${hostArr[0]}  host=${hostArr[1]}"
        if [[ ! ${ip} == "" ]];then
            CONFIG_IPDICT+=([${rolaName}]="${ip} ")
        fi
    done < ${INSTALL_PATH}/etc/hosts

    for key in $(echo ${!CONFIG_IPDICT[*]});do
        local keyIpNum=0
        local ips=${CONFIG_IPDICT[${key}]}
        local ip
        for ip in ${ips};do
            local hostname=${key}${keyIpNum}${KUBE_HOSTNAME_SUFFIX}
            HOSTS_DICT+=([${hostname}]="${ip} ")
            keyIpNum=$[$keyIpNum+1]
        done
    done
}
hosts._load

# update the config/hosts file to ALL REMOTE /etc/hosts
function hosts.Update() {
    remoteHostFile="/etc/hosts"
    local hostsCheckFile="${INSTALL_PATH}/tmp/hosts_check"
    cat /dev/null > ${hostsCheckFile}

    local hostsDictKeys=$(echo ${!HOSTS_DICT[*]})
    local hostDictStr=$(echo "(" $(for i in ${!HOSTS_DICT[*]};do echo [${i}]=${HOSTS_DICT[${i}]} ; done) ")")
    for host in ${hostsDictKeys};do
        local ip=${HOSTS_DICT[${host}]}
        local  isIpExist=$(grep "${ip}" ${hostsCheckFile} | wc -l)
        if [[ ${isIpExist} -eq 0 ]];then
            log.Debug "start to update host ${ip}"
            ssh root@${ip} /bin/bash << EOF
declare -A hostsDict=${hostDictStr}
for hostItem in ${hostsDictKeys};do
    hostItemIp=\${hostsDict[\${hostItem}]}
    sed -i "/\${hostItem}$/d" ${remoteHostFile}
    if [[ \${hostItemIp} == ${ip} ]];then
        echo "127.0.0.1  \${hostItem}" >> ${remoteHostFile}
    else
        echo "\${hostItemIp}  \${hostItem}" >> ${remoteHostFile}
    fi
done
hostnamectl set-hostname "${host}"
EOF
            echo "${ip}" >> ${hostsCheckFile}
        fi
    done
}