#!/bin/bash
declare -x INSTALL_PATH=$(pwd)
source ${INSTALL_PATH}/src/config.sh
source ${INSTALL_PATH}/src/log.sh
source ${INSTALL_PATH}/src/hosts.sh
source ${INSTALL_PATH}/src/init.sh
source ${INSTALL_PATH}/src/ssl.sh
source ${INSTALL_PATH}/src/systemd.sh
source ${INSTALL_PATH}/src/kubenetes.sh

hosts.Update
init.Start
ssl.New

kubenetes.etcd.Install
sleep 1
kubenetes.apiserver.Install
sleep 1
kubenetes.scheduler.Install
sleep 1
kubenetes.controller-manager.Install
sleep 1
kubenetes.node.Install