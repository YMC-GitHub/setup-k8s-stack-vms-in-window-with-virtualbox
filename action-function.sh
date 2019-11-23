#!/bin/sh

HOST_IP_LIST=$(cat host-ip-list.txt | sed "s/^#.*//g" | sed "/^$/d")

template_vm="k8s-node-3"
node_label="node"
master_label="k8s-node-3"

declare -A DIC_HOST_IP_LIST
DIC_HOST_IP_LIST=()
HOST_IP_LIST_ARR=(${HOST_IP_LIST//,/ })
REG_SHELL_COMMOMENT_PATTERN="^#"
for var in ${HOST_IP_LIST_ARR[@]}; do
    if [[ "$var" =~ $REG_SHELL_COMMOMENT_PATTERN ]]; then
        echo "$var" >/dev/null 2>&1
    else
        HOST=$(echo "$var" | cut --fields 1 --delimiter "=")
        IP=$(echo "$var" | cut --fields 2 --delimiter "=")
        DIC_HOST_IP_LIST+=([$HOST]=$IP)
    fi
done

function clone() {
    echo "clone vm"
    for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
        if [ "$key" = "$template_vm" ]; then
            echo "template vm $key" >/dev/null 2>&1
        else
            echo "clone vm $template_vm,then generate vm $key"
            ./clone-one.sh --old-vm-name "$template_vm" --new-vm-name "$key"
        fi
    done
}
function update() {
    echo "update vm"
    for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
        #update ip
        if [ "$key" = "$template_vm" ]; then
            echo "template vm $key" >/dev/null 2>&1
        else
            echo "update vm $key 's ip and host name"
            ip=${DIC_HOST_IP_LIST[$key]}
            old_ip=${DIC_HOST_IP_LIST[$template_vm]}
            ./ssh-to-vm.sh --new-vm-name "$key" --new-vm-ip "$ip" --old-vm-ip "$old_ip"
        fi
    done
}
function smart_sleep() {
    local PROGRESS_CHAR="."
    if [ -n "${1}" ]; then
        PROGRESS_CHAR="${1}"
    fi
    local TIME_LONG=60
    if [ -n "${2}" ]; then
        TIME_LONG="${2}"
    fi
    local MOD=
    while [ $TIME_LONG -gt 0 ]; do
        sleep 1
        TIME_LONG=$(expr $TIME_LONG - 1)
        MOD=$(expr $TIME_LONG % 10)
        if [ $MOD = "0" ]; then
            echo -n "*"
        else
            echo -n "$PROGRESS_CHAR"
        fi
    done
}
function start() {
    echo "start vm"
    for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
        #start vm
        VBoxManage list vms | sed "s#{.*}##g" | grep "$key"
        if [ $? -eq 0 ]; then
            VBoxManage list runningvms | sed "s#{.*}##g" | grep "$key"
            if [ $? -eq 0 ]; then
                echo "$key has been started before"
            else
                echo "start vm $key "
                VBoxManage list vms | sed "s#{.*}##g" | grep "$key"
                if [ $? -eq 0 ]; then
                    VBoxManage startvm $key --type headless
                    echo "advice wait a minute,please wait ..."
                    smart_sleep "-" 180
                    #sleep 60
                fi
            fi
        else
            #echo "vm $key does not exsits" >/dev/null 2>&1
            echo "vm $key does not exsits"
        fi
    done
}
function init_stack_master() {
    echo "stack init k8s master"
    for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
        if [[ "$key" =~ $master_label ]]; then
            echo "master vm $key init k8s master"
        fi
    done
}
function node_join_stack() {
    echo "node join k8s stack"
    for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
        if [[ "$key" =~ $master_label ]]; then
            echo "except master node " >/dev/null 2>&1
        else
            if [[ "$key" =~ $node_label ]]; then
                echo "vm $key joins in stack"
            fi
        fi
    done
}
function close() {
    echo "close vm"
    for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
        #start vm
        echo "close vm $key "
        VBoxManage controlvm "$key" poweroff
    done
}
