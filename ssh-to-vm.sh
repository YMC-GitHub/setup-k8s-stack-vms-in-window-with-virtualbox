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
#主机列表目录
VMs_PATH="D:\\VirtualBox\\Administrator\\VMs"
#路径分割符号
PATH_SPLIT_SYMBOL="\\"
#新的主机路径
NEW_VM_PATH=k8s-node-9
#私钥文件名字
PRIVITE_KEY_FILE_NAME=google-clound-ssr
#私钥文件路径
PRIVITE_KEY_FILE_PATH=~/.ssh/
#被克隆机ssh服务地址
OLD_VM_SSH_SERVER_IP=192.168.2.2
#被克隆机ssh服务账户
OLD_VM_SSH_SERVER_USER=root
#新的主机ssh服务地址
NEW_VM_SSH_SERVER_IP=192.168.2.9
#新的主机ssh服务账户
NEW_VM_SSH_SERVER_USER=root

ONE_NETWORK=192.168.2.0/24
#网卡名字
NEW_VM_NET_CARD_NAME=eth0
#网络掩码
NEW_VM_NETMASK=255.255.255.0
#网关地址
NEW_VM_GATEWAY=192.168.2.1
###
# 定义内置函数
###
function ouput_debug_msg() {
  local debug_msg=$1
  local debug_swith=$2
  if [[ "$debug_swith" =~ "false" ]]; then
    echo $debug_msg >/dev/null 2>&1
  elif [ -n "$debug_swith" ]; then
    echo $debug_msg
  elif [[ "$debug_swith" =~ "true" ]]; then
    echo $debug_msg
  fi
}
function path_resolve_for_relative() {
  local str1="${1}"
  local str2="${2}"
  local slpit_char1=/
  local slpit_char2=/
  if [[ -n ${3} ]]; then
    slpit_char1=${3}
  fi
  if [[ -n ${4} ]]; then
    slpit_char2=${4}
  fi

  # 路径-转为数组
  local arr1=(${str1//$slpit_char1/ })
  local arr2=(${str2//$slpit_char2/ })

  # 路径-解析拼接
  #2 遍历某一数组
  #2 删除元素取值
  #2 获取数组长度
  #2 获取数组下标
  #2 数组元素赋值
  for val2 in ${arr2[@]}; do
    length=${#arr1[@]}
    if [ $val2 = ".." ]; then
      index=$(($length - 1))
      if [ $index -le 0 ]; then index=0; fi
      unset arr1[$index]
      #echo ${arr1[*]}
      #echo  $index
    else
      index=$length
      arr1[$index]=$val2
      #echo ${arr1[*]}
    fi
  done
  # 路径-转为字符
  local str3=''
  for i in ${arr1[@]}; do
    str3=$str3/$i
  done
  if [ -z $str3 ]; then str3="/"; fi
  echo $str3
}
function path_resolve() {
  local str1="${1}"
  local str2="${2}"
  local slpit_char1=/
  local slpit_char2=/
  if [[ -n ${3} ]]; then
    slpit_char1=${3}
  fi
  if [[ -n ${4} ]]; then
    slpit_char2=${4}
  fi

  #FIX:when passed asboult path,dose not return the asboult path itself
  #str2="/d/"
  local str3=""
  str2=$(echo $str2 | sed "s#/\$##")
  ABSOLUTE_PATH_REG_PATTERN="^/"
  if [[ $str2 =~ $ABSOLUTE_PATH_REG_PATTERN ]]; then
    str3=$str2
  else
    str3=$(path_resolve_for_relative $str1 $str2 $slpit_char1 $slpit_char2)
  fi
  echo $str3
}
function get_help_msg() {
  local USAGE_MSG=$1
  local USAGE_MSG_FILE=$2
  if [ -z $USAGE_MSG ]; then
    if [[ -n $USAGE_MSG_FILE && -e $USAGE_MSG_FILE ]]; then
      USAGE_MSG=$(cat $USAGE_MSG_FILE)
    else
      USAGE_MSG="no help msg and file"
    fi
  fi
  echo "$USAGE_MSG"
}
# 引入相关文件
PROJECT_PATH=$(path_resolve $THIS_FILE_PATH "../")
HELP_DIR=$(path_resolve $THIS_FILE_PATH "../help")
SRC_DIR=$(path_resolve $THIS_FILE_PATH "../src")
TEST_DIR=$(path_resolve $THIS_FILE_PATH "../test")
DIST_DIR=$(path_resolve $THIS_FILE_PATH "../dist")
DOCS_DIR=$(path_resolve $THIS_FILE_PATH "../docs")
TOOL_DIR=$(path_resolve $THIS_FILE_PATH "../tool")
# 参数帮助信息
USAGE_MSG=
USAGE_MSG_PATH=$(path_resolve $THIS_FILE_PATH "../help")
USAGE_MSG_FILE=${USAGE_MSG_PATH}/clone-one.txt
USAGE_MSG=$(get_help_msg "$USAGE_MSG" "$USAGE_MSG_FILE")
###
#参数规则内容
###
GETOPT_ARGS_SHORT_RULE="--options h,d,"
GETOPT_ARGS_LONG_RULE="--long help,debug,key-file-path:,new-vm-ip:,old-vm-user:,new-vm-name:,path-delimeter-char:,key-file-name:,old-vm-ip:"
###
#设置参数规则
###
GETOPT_ARGS=$(
  getopt $GETOPT_ARGS_SHORT_RULE \
    $GETOPT_ARGS_LONG_RULE -- "$@"
)
###
#解析参数规则
###
eval set -- "$GETOPT_ARGS"
# below generated by write-sources.sh
while [ -n "$1" ]; do
  case $1 in
  --key-file-path)
    ARG_KEY_FILE_PATH=$2
    shift 2
    ;;
  --new-vm-ip)
    ARG_NEW_VM_IP=$2
    shift 2
    ;;
  --old-vm-user)
    ARG_OLD_VM_USER=$2
    shift 2
    ;;
  --new-vm-name)
    ARG_NEW_VM_NAME=$2
    shift 2
    ;;
  --path-delimeter-char)
    ARG_PATH_DELIMETER_CHAR=$2
    shift 2
    ;;
  --key-file-name)
    ARG_KEY_FILE_NAME=$2
    shift 2
    ;;
  --old-vm-ip)
    ARG_OLD_VM_IP=$2
    shift 2
    ;;
  -h | --help)
    echo "$USAGE_MSG"
    exit 1
    ;;
  -d | --debug)
    IS_DEBUG_MODE=true
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
###
#处理剩余参数
###
# optional
###
#更新内置变量
###
# below generated by write-sources.sh

if [ -n "$ARG_KEY_FILE_PATH" ]; then
  KEY_FILE_PATH=$ARG_KEY_FILE_PATH
fi
if [ -n "$ARG_NEW_VM_IP" ]; then
  NEW_VM_IP=$ARG_NEW_VM_IP
fi
if [ -n "$ARG_OLD_VM_USER" ]; then
  OLD_VM_USER=$ARG_OLD_VM_USER
fi
if [ -n "$ARG_NEW_VM_NAME" ]; then
  NEW_VM_NAME=$ARG_NEW_VM_NAME
fi
if [ -n "$ARG_PATH_DELIMETER_CHAR" ]; then
  PATH_DELIMETER_CHAR=$ARG_PATH_DELIMETER_CHAR
fi
if [ -n "$ARG_KEY_FILE_NAME" ]; then
  KEY_FILE_NAME=$ARG_KEY_FILE_NAME
fi
if [ -n "$ARG_OLD_VM_IP" ]; then
  OLD_VM_IP=$ARG_OLD_VM_IP
fi
###
#脚本主要代码
###
ouput_debug_msg "caculate relations config ..." "true"
#新的主机基径
NEW_VM_BASE_FOLEDR=${VMs_PATH}${PATH_SPLIT_SYMBOL}${NEW_VM_PATH}

#新的主机名字
NEW_VM_PATH=$NEW_VM_NAME
#NEW_VM_NAME=$NEW_VM_PATH
#新的主机host名字
NEW_VM_HOST_NAME=$NEW_VM_NAME
#电脑地址
NEW_VM_IPADDR=$NEW_VM_SSH_SERVER_IP

ouput_debug_msg "generate relations dir and file ..." "true"
mkdir -p $VMs_PATH
cd $VMs_PATH
cd $NEW_VM_PATH
echo $OLD_VM_IP,$VMs_PATH,$NEW_VM_PATH

if [ -n "$OLD_VM_NAME" ]; then
  OLD_VM_SSH_SERVER_USER=$OLD_VM_NAME
fi
if [ -n "$OLD_VM_IP" ]; then
  OLD_VM_SSH_SERVER_IP=$OLD_VM_IP
fi
# 启动新的主机
VBoxManage list runningvms | sed "s#{.*}##g" | grep $NEW_VM_NAME
if [ $? -eq 0 ]; then
  echo "has been started before" >/dev/null 2>&1
else
  ouput_debug_msg "start new vm ..." "true"
  VBoxManage startvm $NEW_VM_NAME --type headless
fi
sleep 60

# 免密登录主机
ssh -i ${PRIVITE_KEY_FILE_PATH}${PRIVITE_KEY_FILE_NAME} $OLD_VM_SSH_SERVER_USER@$OLD_VM_SSH_SERVER_IP
