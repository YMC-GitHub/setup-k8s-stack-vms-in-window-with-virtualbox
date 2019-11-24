#!/bin/sh

# 使用virtualbox克隆虚拟主机
# 通过VBoxManage使用virtualbox的cli的方式
# 需要：
# 列出运行中的主机
# 关闭被克隆的主机
# 列出已经有的主机
# 克隆出某新的主机

THIS_FILE_PATH=$(
  cd $(dirname $0)
  pwd
)
###
# 定义内置变量
###
#主机列表目录
VMs_PATH="D:\\VirtualBox\\Administrator\\VMs"
#被克隆机目录
VM_PATH=k8s-node-3
#路径分割符号
PATH_SPLIT_SYMBOL="\\"
#新的主机路径
NEW_VM_PATH=k8s-node-9

ACTIONS="close_old_vm|clone_old_vm" #"start_new_vm|restart_new_vm|ssh_new_vm"

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
GETOPT_ARGS_LONG_RULE="--long help,debug,old-vm-name:,new-vm-name:,path-delimeter-char:"
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
  --old-vm-name)
    ARG_OLD_VM_NAME=$2
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

if [ -n "$ARG_OLD_VM_NAME" ]; then
  OLD_VM_NAME=$ARG_OLD_VM_NAME
fi
if [ -n "$ARG_NEW_VM_NAME" ]; then
  NEW_VM_NAME=$ARG_NEW_VM_NAME
fi
if [ -n "$ARG_PATH_DELIMETER_CHAR" ]; then
  PATH_DELIMETER_CHAR=$ARG_PATH_DELIMETER_CHAR
fi
###
#脚本主要代码
###
#被克隆机基径
VM_BASE_PATH=${VMs_PATH}${PATH_SPLIT_SYMBOL}${VM_PATH}
#被克隆机名字
VM_NAME=$VM_PATH
#新的主机基径
NEW_VM_PATH=$NEW_VM_NAME
NEW_VM_BASE_FOLEDR=${VMs_PATH}${PATH_SPLIT_SYMBOL}${NEW_VM_PATH}
#新的主机名字
NEW_VM_NAME=$NEW_VM_PATH
#新的主机host名字
NEW_VM_HOST_NAME=$NEW_VM_NAME
#电脑地址
NEW_VM_IPADDR=$NEW_VM_SSH_SERVER_IP

mkdir -p $VMs_PATH
cd $VMs_PATH
mkdir -p $VM_PATH
cd $VM_PATH

if [[ "$ACTIONS" =~ 'clone_old_vm' ]]; then
  # 关闭被克隆机
  ouput_debug_msg "close old vm $VM_NAME..." "true"
  VBoxManage list runningvms | sed "s#{.*}##g" | grep $VM_NAME
  if [ $? -eq 0 ]; then
    VBoxManage controlvm $VM_NAME poweroff
    smart_sleep "-" 10
  fi
  # 克隆被克隆机
  VBoxManage list vms | sed "s#{.*}##g" | grep $NEW_VM_NAME
  if [ $? -eq 0 ]; then
    echo "vm exists" >/dev/null 2>&1
  else
    VBoxManage clonevm $VM_NAME --name $NEW_VM_NAME --register --basefolder $VMs_PATH
    smart_sleep "-" 40
  fi
fi
