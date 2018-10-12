#!/usr/bin/env bash

function log.Debug {
    echo -e "\033[44;37m [DEBUG] $1 \033[0m"
}
function log.Info {
    echo -e "\033[42;37m [INFO] $1 \033[0m"
}
function log.Warning {
    echo -e "\033[43;37m [WARNING] $1 \033[0m"
}
function log.Error {
    echo -e "\033[41;37m [ERROR] $1 \033[0m"
}
function log.Exception {
    log.Error $1
    exit 1
}
