#!/bin/sh
source ./config.sh

# 使用virtualbox克隆虚拟主机
# 通过VBoxManage使用virtualbox的cli的方式
# 需要：
# 列出运行中的主机
# 关闭被克隆的主机
# 克隆出某新的主机
# 免密登录新的主机
# 修改主机名字地址
# 修改域名解析地址


mkdir -p $VMs_PATH
cd $VMs_PATH
mkdir -p $VM_PATH
cd $VM_PATH




FILE_PATH=$(cd `dirname $0`; pwd)
mkdir -p ~/shell-get-config
echo "\$0 is :${0}" >> ~/shell-get-config/debug.log
echo "FILE_PATH:${FILE_PATH}" >> ~/shell-get-config/debug.log

echo "cat ~/shell-get-config/debug.log"

# 帮助信息
USAGE_MSG="args:\
  -n,--NEW_VM_NAME desc\t\n\
  -i,--NEW_VM_SSH_SERVER_IP desc\
"
# 参数规则
GETOPT_ARGS_SHORT_RULE="-o n:i:"
GETOPT_ARGS_LONG_RULE="--long NEW_VM_NAME:,NEW_VM_SSH_SERVER_IP:"

# 显示帮助信息


# 设置参数规则
GETOPT_ARGS=`getopt $GETOPT_ARGS_SHORT_RULE \
$GETOPT_ARGS_LONG_RULE -- "$@"`
# 解析参数规则
eval set -- "$GETOPT_ARGS"

# 更新相关变量
while [ -n "$1" ]
do
    case $1 in
    -n|--NEW_VM_NAME)
    NEW_VM_NAME=$2
    shift 2
    ;;
    -i|--NEW_VM_SSH_SERVER_IP)
    NEW_VM_SSH_SERVER_IP=$2
    shift 2
    ;;
    --)
    break
    ;;
    *)
    printf "$USAGE_MSG"
    ;;
    esac
done


# 输出相关变量
echo $NEW_VM_NAME,$NEW_VM_SSH_SERVER_IP


# 关闭
VBoxManage list runningvms | sed "s#{.*}##g" | grep $VM_NAME
if [ $? -eq 0 ];then
    VBoxManage controlvm $VM_NAME poweroff
    sleep 60
fi
# 克隆
VBoxManage list vms | sed "s#{.*}##g" | grep $NEW_VM_NAME
if [ $? -eq 0 ]
then
    echo "need to clone a vm" > /dev/null 2>&1
else 
    VBoxManage clonevm $VM_NAME --name $NEW_VM_NAME --register --basefolder $VMs_PATH
    #sleep 60
fi
# 启动
VBoxManage list runningvms | sed "s#{.*}##g" | grep $NEW_VM_NAME
if [ $? -eq 0 ]
then
  echo "has been started before" > /dev/null 2>&1
else
  VBoxManage startvm $NEW_VM_NAME --type headless
  sleep 100
fi


# 登录
#ssh root@192.168.2.2
# ssh -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} $OLD_VM_SSH_SERVER_USER@$OLD_VM_SSH_SERVER_IP
# ssh -tt -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} $OLD_VM_SSH_SERVER_USER@$OLD_VM_SSH_SERVER_IP

#ssh -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} $OLD_VM_SSH_SERVER_USER@$OLD_VM_SSH_SERVER_IP < ./update-ip-and-hostname.sh
ssh -tt -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} $OLD_VM_SSH_SERVER_USER@$OLD_VM_SSH_SERVER_IP < ./update-ip-and-hostname.sh


# 关机
VBoxManage list runningvms | sed "s#{.*}##g" | grep $NEW_VM_NAME
if [ $? -eq 0 ]
then
  VBoxManage controlvm $NEW_VM_NAME poweroff
  sleep 60
fi
# 重启
VBoxManage list runningvms | sed "s#{.*}##g" | grep $NEW_VM_NAME
if [ $? -eq 0 ]
then
  echo "has been started before" > /dev/null 2>&1
else
  VBoxManage startvm $NEW_VM_NAME --type headless
  sleep 60
fi

# 免密登录
ssh -t -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} $NEW_VM_SSH_SERVER_USER@$NEW_VM_SSH_SERVER_IP


#### usage
# bash ./clone-one.sh