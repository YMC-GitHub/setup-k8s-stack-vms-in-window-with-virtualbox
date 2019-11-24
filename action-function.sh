#!/bin/sh

HOST_IP_LIST=$(cat host-ip-list.txt | sed "s/^#.*//g" | sed "/^$/d")

template_vm="k8s-node-3"
node_label="node"
master_label="k8s-node-3"
PRIVITE_KEY_FILE_NAME=google-clound-ssr
PRIVITE_KEY_FILE_PATH=~/.ssh/

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
            #./ssh-to-vm.sh --new-vm-name "$key" --new-vm-ip "$ip" --old-vm-ip "$old_ip"
            vm_start "$key"
            ssh -t -t -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} root@$old_ip <<EOF
hostnamectl set-hostname "$key"
sed -i "s/127.0.0.1.*//g" /etc/hosts
sed -i "s/::1.*//g" /etc/hosts
sed -i "s/^$//g" /etc/hosts
echo "127.0.0.1 $key" >>/etc/hosts
echo "::1 $key" >>/etc/hosts
sed -i "s/IPADDR=.*/IPADDR=$ip/g" /etc/sysconfig/network-scripts/ifcfg-eth0
function restart_net() {
    service network restart && exit 0
    restart_net
}
restart_net
EOF
            vm_restart "$key"
            #
            #question: connect to host 192.168.2.22 port 22: Connection timed
            echo "try to ssh to host with new ip $ip..."
            ssh -t -t -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} root@$ip <<EOF
function restart_net() {
    service network restart && exit 0
    restart_net
}
restart_net
EOF
            if [ $? -eq 0 ]; then
                echo "$key-$ip is ok"
            fi

        fi
    done
}
###
#private fun
###
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
            if [ $TIME_LONG = "0" ]; then
                echo "*"
            else
                echo -n "*"
            fi
        else
            echo -n "$PROGRESS_CHAR"
        fi
    done
}
function restart_net() {
    service network restart && exit 0
    restart_net
}
function set_hosts_resolve() {
    local key="k8s-node-2"
    if [ -n "${1}" ]; then
        key="${1}"
    fi
    sed -i "s/127.0.0.1.*//g" /etc/hosts
    sed -i "s/::1.*//g" /etc/hosts
    sed -i "s/^$//g" /etc/hosts
    echo "127.0.0.1 $key" >>/etc/hosts
    echo "::1 $key" >>/etc/hosts
}
function vm_close() {
    local key="k8s-node-2"
    if [ -n "${1}" ]; then
        key="${1}"
    fi
    temp=$(VBoxManage list runningvms | sed "s#{.*}##g" | grep "$key")
    if [ $? -eq 0 ]; then
        VBoxManage controlvm "$key" poweroff
        # 30s is too long
        time_to_waite=15
        echo "advice wait $time_to_waite s,please wait ..."
        smart_sleep "-" $time_to_waite
    fi
}
function vm_start() {
    local key="k8s-node-2"
    if [ -n "${1}" ]; then
        key="${1}"
    fi
    temp=$(VBoxManage list runningvms | sed "s#{.*}##g" | grep "$key")
    if [ $? -eq 0 ]; then
        echo "has been started before" >/dev/null 2>&1
    else
        VBoxManage startvm "$key" --type headless
        # 180 is too long
        time_to_waite=90
        echo "advice wait $time_to_waite s,please wait ..."
        smart_sleep "-" $time_to_waite
    fi
}
function vm_restart() {
    local key="k8s-node-2"
    if [ -n "${1}" ]; then
        key="${1}"
    fi
    vm_close "$key"
    vm_start "$key"
}
function start() {
    echo "start vm"
    for key in $(echo ${!DIC_HOST_IP_LIST[*]}); do
        #start vm
        temp=$(VBoxManage list vms | sed "s#{.*}##g" | grep "$key")
        if [ $? -eq 0 ]; then
            vm_start "$key"
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
            vm_start "$key"
            ip=${DIC_HOST_IP_LIST["$key"]}
            K8S_PATH=/root/k8s
            K8S_VERISON="1.15.3"
            CALICO_DIR=calico
            CALICO_VERSION=v3.8
            CALICO_LOCAL_FILE=calico.yaml
            DASHBOARD_DIR=dashboard
            DASHBOARD_VERSION=v1.10.1
            DASHBOARD_NS=kubernetes-dashboard
            DASHBOARD_LOCAL_FILE=kubernetes-dashboard.yaml
            ssh -t -t -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} root@$ip <<EOF
cd $K8S_PATH
kubeadm init --config=kubeadm-init-k8s-${K8S_VERISON}.yaml

#uses caclio net work
kubectl apply --filename $CALICO_DIR/$CALICO_VERSION/$CALICO_LOCAL_FILE
#uses ui borad
kubectl apply --filename ${DASHBOARD_DIR}/${DASHBOARD_VERSION}/${DASHBOARD_LOCAL_FILE}
EOF
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
