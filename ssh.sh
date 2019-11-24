#!/bin/sh

# 需要：
# 免密登录新的主机
# 修改主机名字地址

THIS_FILE_PATH=$(
  cd $(dirname $0)
  pwd
)
###
# 定义内置变量
###
PRIVITE_KEY_FILE_NAME=google-clound-ssr
#私钥文件路径
PRIVITE_KEY_FILE_PATH=~/.ssh/
#被克隆机ssh服务地址
VM_SSH_SERVER_IP=192.168.2.3
#被克隆机ssh服务账户
VM_SSH_SERVER_USER=root
VM_NAME=k8s-node-3

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

# 启动远程主机
VBoxManage list runningvms | sed "s#{.*}##g" | grep $VM_NAME
if [ $? -eq 0 ]; then
  echo "has been started before" >/dev/null 2>&1
else
  VBoxManage startvm $VM_NAME --type headless
  time_to_waite=90
  echo "advice wait $time_to_waite s,please wait ..."
  smart_sleep "-" $time_to_waite
fi

TXT_RESTART_NET=$(
  cat <<EOF
#cat /etc/sysconfig/network-scripts/ifcfg-eth0
function restart_net(){
service network  restart && exit 0
restart_net
}
restart_net
EOF
)

# 远程登录主机
ssh -t -t -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} $VM_SSH_SERVER_USER@$VM_SSH_SERVER_IP
:<<note
# fix:Pseudo-terminal will not be allocated because stdin is not a terminal.
ssh -t -t -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} $VM_SSH_SERVER_USER@$VM_SSH_SERVER_IP <<EOF
kubectl get pods --all-namespaces
EOF
note

