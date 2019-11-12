#!/bin/sh

# 使用virtualbox克隆虚拟主机
# 通过VBoxManage使用virtualbox的cli的方式
# 需要：
# 列出运行中的主机
# 关闭被克隆的主机
# 克隆出某新的主机
# 免密登录新的主机
# 修改主机名字地址
# 修改域名解析地址



VMs_PATH="D:\\VirtualBox\\Administrator\\VMs"
mkdir -p $VMs_PATH
cd $VMs_PATH
echo $VMs_PATH
VM_PATH=centos-7.6
mkdir -p $VM_PATH
cd $VM_PATH
PATH_SPLIT_SYMBOL="\\"
VM_BASE_PATH=${VMs_PATH}${PATH_SPLIT_SYMBOL}${VM_PATH}
echo $VM_BASE_PATH
VM_NAME=$VM_PATH

NEW_VM_NAME=k8s-node-6
NEW_VM_PATH=$NEW_VM_NAME
NEW_VM_BASE_FOLEDR=${VMs_PATH}${PATH_SPLIT_SYMBOL}${NEW_VM_PATH}
PRIVITE_KEY_FILE_NAME=google-clound-ssr
PRIVITE_KEY_FILE_PATH=~/.ssh/
OLD_VM_SSH_SERVER_IP=192.168.2.2
OLD_VM_SSH_SERVER_USER=root
NEW_VM_SSH_SERVER_IP=192.168.2.6
NEW_VM_SSH_SERVER_USER=root
NEW_VM_HOST_NAME=$NEW_VM_NAME

#某个网络
ONE_NETWORK=192.168.2.0/24
#网卡名字
NEW_VM_NET_CARD_NAME=eth0
#电脑地址
NEW_VM_IPADDR=$NEW_VM_SSH_SERVER_IP #192.168.2.2
#网络掩码
NEW_VM_NETMASK=255.255.255.0
#网关地址
NEW_VM_GATEWAY=192.168.2.1


FILE_PATH=$(cd `dirname $0`; pwd)

mkdir -p ~/shell-get-config
echo "FILE_PATH:${FILE_PATH}" >> ~/shell-get-config/debug.log

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
    sleep 60
fi
# 启动
VBoxManage list runningvms | sed "s#{.*}##g" | grep $NEW_VM_NAME
if [ $? -eq 0 ]
then
  echo "has been started before" > /dev/null 2>&1
else
  VBoxManage startvm $NEW_VM_NAME --type headless
  sleep 60
fi


# 登录
#ssh root@192.168.2.2
# ssh -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} $OLD_VM_SSH_SERVER_USER@$OLD_VM_SSH_SERVER_IP
# ssh -tt -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} $OLD_VM_SSH_SERVER_USER@$OLD_VM_SSH_SERVER_IP
ssh -tt -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} $OLD_VM_SSH_SERVER_USER@$OLD_VM_SSH_SERVER_IP << run-some-task-on-vm-node


####
#functions
####
function update_static_ip(){
#设置
if [ -e /etc/sysconfig/network-scripts/ifcfg-${NEW_VM_NET_CARD_NAME} ]
then
echo "update ip in net card :${NEW_VM_NET_CARD_NAME}"
sed -i 's/IPADDR=.*//g' /etc/sysconfig/network-scripts/ifcfg-${NEW_VM_NET_CARD_NAME}
sed -i 's/NETMASK=.*//g' /etc/sysconfig/network-scripts/ifcfg-${NEW_VM_NET_CARD_NAME}
sed -i 's/GATEWAY=.*//g' /etc/sysconfig/network-scripts/ifcfg-${NEW_VM_NET_CARD_NAME}
sed -i 's/BOOTPROTO=.*//g' /etc/sysconfig/network-scripts/ifcfg-${NEW_VM_NET_CARD_NAME}
sed -i 's/ONBOOT=.*//g' /etc/sysconfig/network-scripts/ifcfg-${NEW_VM_NET_CARD_NAME}
sed -i '/^\s*$/d' /etc/sysconfig/network-scripts/ifcfg-${NEW_VM_NET_CARD_NAME} # 删除空格
fi
cat >> /etc/sysconfig/network-scripts/ifcfg-${NEW_VM_NET_CARD_NAME} <<centos-set-static-ip-address
IPADDR=${NEW_VM_IPADDR}
NETMASK=${NEW_VM_NETMASK}
GATEWAY=${NEW_VM_GATEWAY}
BOOTPROTO=static
ONBOOT=yes
centos-set-static-ip-address

#service network restart
#sleep 5
# 查看
cat /etc/sysconfig/network-scripts/ifcfg-${NEW_VM_NET_CARD_NAME} | grep --extended-regexp "IPADDR.*(.*.)\..*"
}

function set_host_name(){
# 设置
#2 for centos7
hostnamectl set-hostname $NEW_VM_HOST_NAME
#2 for centos6
#hostname $NEW_VM_HOST_NAME

# 查看
cat /etc/hostname


# 设置
cat /etc/hosts | grep "127.0.0.1" | grep "${NEW_VM_HOST_NAME}" > /dev/null 2>&1
if [ $? -eq 0 ];then
  echo "yes" > /dev/null 2>&1
else
  #echo  "no"
  # 在匹配的行前添加#(注释)
  #sed  '/127.0.0.1 */ s/^/#/g' /etc/hosts
  # 在匹配的行后添加（追加）
  #sed -i "/127.0.0.1 */ s/$/ $NEW_VM_HOST_NAME/g" /etc/hosts
  # 删除后添加（覆盖）
  #sed "s/127.0.0.1.*//g" /etc/hosts | sed '/^\s*$/d'
  sed -i "s/127.0.0.1.*//g" /etc/hosts
  sed -i '/^\s*$/d' /etc/hosts
  echo "127.0.0.1 $NEW_VM_HOST_NAME" >> /etc/hosts
fi

cat /etc/hosts | grep "::1" | grep $NEW_VM_HOST_NAME > /dev/null 2>&1
if [ $? -eq 0 ];then
  echo "yes" > /dev/null 2>&1
else
  #echo  "no"
  # 在匹配的行前添加#
  #sed  '/::1 */ s/^/#/g' /etc/hosts
  # 在匹配的行后添加#
  #sed -i "/::1 */ s/$/ $NEW_VM_HOST_NAME/g" /etc/hosts
  sed -i "s/::1.*//g" /etc/hosts
  sed -i '/^\s*$/d' /etc/hosts
  echo "::1 $NEW_VM_HOST_NAME" >> /etc/hosts
fi

# 查看
cat /etc/hosts
}

function set_dns_resovle_in_china(){
cat > /etc/resolv.conf  << eof
# 国内
nameserver 223.5.5.5
nameserver 223.6.6.6
eof
cat /etc/resolv.conf
}

####
#actions
####
# 操作
#2 修改ip
update_static_ip
#2 修改hostname
set_host_name
#2 修改dns域名服务器
set_dns_resovle_in_china
#2 ...
# 退出
sleep 20
exit
run-some-task-on-vm-node
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