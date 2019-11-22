#!/bin/sh

HOST_IP_LIST=$(cat host-ip-list.txt | sed "s/^#.*//g" | sed "/^$/d")
#echo "$HOST_IP_LIST"

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

for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
    #
    #echo "$key : ${DIC_HOST_IP_LIST[$key]}"
    template_vm="k8s-master-2"
    if [ "$key" = "$template_vm" ]; then
        echo "template vm $key" >/dev/null 2>&1
    else
        echo "clone vm $template_vm,then generate vm $key"
    fi
done

for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
    #update ip

    template_vm="k8s-master-2"
    if [ "$key" = "$template_vm" ]; then
        echo "template vm $key" >/dev/null 2>&1
    else
        echo "update vm $key 's ip and host name"
    fi
done

for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
    #start vm
    echo "start vm $key "
done

for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
    master_label="master"
    if [[ "$key" =~ $master_label ]]; then
        echo "master vm $key init k8s master"
    fi
done

for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
    node_label="node"
    if [[ "$key" =~ $node_label ]]; then
        echo "vm $key joins in stack"
    fi
done
