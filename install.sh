#!/bin/bash
declare -x INSTALL_PATH=$(pwd)
source ${INSTALL_PATH}/src/config.sh
source ${INSTALL_PATH}/src/log.sh
source ${INSTALL_PATH}/src/hosts.sh
source ${INSTALL_PATH}/src/init.sh
source ${INSTALL_PATH}/src/ssl.sh
source ${INSTALL_PATH}/src/systemd.sh
source ${INSTALL_PATH}/src/kubenetes.sh

hosts.Update 1 > /dev/null
init.Start 1 > /dev/null
ssl.New 1 > /dev/null

kubenetes.etcd.Install 1 > /dev/null
sleep 1
kubenetes.apiserver.Install 1 > /dev/null
sleep 1
kubenetes.scheduler.Install 1 > /dev/null
sleep 1
kubenetes.controller-manager.Install 1 > /dev/null
sleep 1
kubenetes.node.Install 1 > /dev/null