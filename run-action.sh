#!/bin/sh

source ./action-function.sh

ACTION_LIST=$(cat action-list.txt | sed "s/^#.*//g" | sed "/^$/d")

declare -A DIC_ACTION_LIST
DIC_ACTION_LIST=()
ACTION_LIST_ARR=(${ACTION_LIST//,/ })
REG_SHELL_COMMOMENT_PATTERN="^#"
for var in ${ACTION_LIST_ARR[@]}; do
    if [[ "$var" =~ $REG_SHELL_COMMOMENT_PATTERN ]]; then
        echo "$var" >/dev/null 2>&1
    else
        name=$(echo "$var" | cut --fields 1 --delimiter "=")
        value=$(echo "$var" | cut --fields 2 --delimiter "=")
        DIC_ACTION_LIST+=([$name]=$value)
        #echo "$value"
        #$value
        #init_stack_master
    fi
done

ACTION_ORDER=$(
    cat <<EOF
action.clone
action.update
action.start
action.init
action.join
EOF
)
declare -A DIC_ACTION_ORDER
DIC_ACTION_ORDER=()
ACTION_ORDER_ARR=(${ACTION_ORDER//,/ })
REG_SHELL_COMMOMENT_PATTERN="^#"
for var in ${ACTION_ORDER_ARR[@]}; do
    if [[ "$var" =~ $REG_SHELL_COMMOMENT_PATTERN ]]; then
        echo "$var" >/dev/null 2>&1
    else
        #echo "$var"
        action=${DIC_ACTION_LIST["$var"]}
        if [ -n "$action" ]; then
            $action
        fi
    fi
done
