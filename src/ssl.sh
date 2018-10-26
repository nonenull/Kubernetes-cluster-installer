#!/usr/bin/env bash

cfsslCmd=${SOURCE_BIN_PATH}/cfssl/cfssl
cfssljsonCmd=${SOURCE_BIN_PATH}/cfssl/cfssljson

function ssl._generate() {
    local hostFile="${SOURCE_ETC_PATH}/hosts"
    local serverCsrFileName="server-csr.json"
    local clientCsrFileName="client-csr.json"

    cd ${SOURCE_SSL_PATH}
    /usr/bin/rm -rf *.pem *.csr ${serverCsrFileName} ${clientCsrFileName}
    # generate ca pem
    ${cfsslCmd} gencert -initca ca-csr.json | ${cfssljsonCmd} -bare ca
    # generate kubernetes pem
    /usr/bin/cp -rf ${serverCsrFileName}.template ${serverCsrFileName}
    /usr/bin/cp -rf ${clientCsrFileName}.template ${clientCsrFileName}
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
    for key in $(echo ${!CONFIG_IPDICT[*]});do
        local ips=${CONFIG_IPDICT[${key}]}
        local ip
        for ip in ${ips};do
            #log.Debug "${ip}"
            local  isIpExist=$(grep "${ip}" ${sslCheckFile} | wc -l)
            if [[ ${isIpExist} -eq 0 ]];then
                # here is do some other job (add new user)
                scp -C  ${SOURCE_SSL_PATH}/*.pem root@${ip}:${KUBE_SSL_PATH}
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
    chmod +x ${cfsslCmd} ${cfssljsonCmd}

    ssl._generate
    ssl._sync
}
