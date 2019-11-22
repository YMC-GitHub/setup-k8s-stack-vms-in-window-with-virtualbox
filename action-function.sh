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
function start() {
    echo "start vm"
    for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
        #start vm
        VBoxManage list runningvms | sed "s#{.*}##g" | grep "$key"
        if [ $? -eq 0 ]; then
            echo "has been started before" >/dev/null 2>&1
        else
            echo "start vm $key "
            echo "advice wait a minute,please wait ..."
            VBoxManage startvm $NEW_VM_NAME --type headless
            sleep 60
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
