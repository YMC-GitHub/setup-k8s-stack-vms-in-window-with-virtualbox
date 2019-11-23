#!/bin/sh

HOST_IP_LIST=$(cat host-ip-list.txt | sed "s/^#.*//g" | sed "/^$/d")
template_vm="k8s-node-3"

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
    if [ "$key" = "$template_vm" ]; then
        echo "template vm $key" >/dev/null 2>&1
    else
        echo "delete vm $key"
        VBoxManage list runningvms | sed "s#{.*}##g" | grep "$key"
        if [ $? -eq 0 ]; then
            VBoxManage controlvm "$key" poweroff
            sleep 10
        fi
        VBoxManage list vms | sed "s#{.*}##g" | grep "$key"
        if [ $? -eq 0 ]; then
            VBoxManage unregistervm "$key" --delete
        fi
    fi
done
