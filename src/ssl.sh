#!/usr/bin/env bash

function ssl._generate() {
    local cfsslCmd=${SOURCE_BIN_PATH}/cfssl/cfssl
    local cfssljsonCmd=${SOURCE_BIN_PATH}/cfssl/cfssljson
    local hostFile="${SOURCE_ETC_PATH}/hosts"
    local sslPath="${SOURCE_ETC_PATH}/ssl"
    local serverCsrFileName="server-csr.json"
    local clientCsrFileName="client-csr.json"

    cd ${sslPath} && log.Debug "cd to ${sslPath}"
    /usr/bin/rm -rf *.pem *.csr ${serverCsrFileName} ${clientCsrFileName}
    # generate ca pem
    ${cfsslCmd} gencert -initca ca-csr.json | ${cfssljsonCmd} -bare ca
    # generate kubernetes pem

    /usr/bin/cp -rf ${serverCsrFileName}.tmplate ${serverCsrFileName}
    /usr/bin/cp -rf ${clientCsrFileName}.tmplate ${clientCsrFileName}
    local hostsStr=$(cat ${hostFile} | awk -F ' ' '{print $1}' | sed '/^\s*$/d' | sed 's/$/",/;s/^/"/' | sort | uniq)
    #log.Debug "hostsStr: ${hostsStr}"
    sed -i "s/{{KUBERNETES_HOST}}/$(echo ${hostsStr: 0:-1})/" ${serverCsrFileName}
    sed -i "s/{{SERVICE_KUBERNETES_IP}}/${KUBE_SERVICE_KUBERNETES_IP}/" ${serverCsrFileName}

    sed -i "s/{{KUBERNETES_HOST}}/$(echo ${hostsStr: 0:-1})/" ${clientCsrFileName}
    sed -i "s/{{SERVICE_KUBERNETES_IP}}/${KUBE_SERVICE_KUBERNETES_IP}/" ${clientCsrFileName}
    ${cfsslCmd} gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes ${serverCsrFileName} | ${cfssljsonCmd} -bare server
    ${cfsslCmd} gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes ${clientCsrFileName} | ${cfssljsonCmd} -bare client
}

function ssl._sync() {
    local sslCheckFile="${INSTALL_PATH}/tmp/ssl_check"
    cat /dev/null > ${sslCheckFile}
    local key
    local sslPath="${SOURCE_ETC_PATH}/ssl"
    for key in $(echo ${!CONFIG_IPDICT[*]});do
        local ips=${CONFIG_IPDICT[${key}]}
        local ip
        for ip in ${ips};do
            #log.Debug "${ip}"
            local  isIpExist=$(grep "${ip}" ${sslCheckFile} | wc -l)
            if [[ ${isIpExist} -eq 0 ]];then
                # here is do some other job (add new user)
                scp -C  ${sslPath}/*.pem root@${ip}:${KUBE_SSL_PATH}
                if [[ $? -eq 0 ]];then
                    echo "${ip}" >> ${sslCheckFile}
                else
                    log.Error "${ip} copy ssl file failed"
                fi
            fi
        done
    done
}

function ssl.New(){
    ssl._generate
    ssl._sync
}
