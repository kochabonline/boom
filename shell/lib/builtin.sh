#!/usr/bin/env bash
# describepoint: builtin
# author: kochab

# ----------配置区域----------
# 静默输出
QUIET=${QUIET:-"true"} # true, false
# 日志参数
#   日志级别
LOG_LEVELS=(["debug"]=0 ["info"]=1 ["warn"]=2 ["error"]=3)
#   日志模式
LOG_MODE=${LOG_MODE:-"console"} # console, file, multi
#   日志级别
LOG_LEVEL=${LOG_LEVEL:-"info"} # debug, info, warn, error
#   日志文件
LOG_FILE=${LOG_FILE:-"/var/log/$(basename -s .sh $0).log"}
# 额外参数
#   帮助信息
EXTRA_HELP=${EXTRA_HELP:-""}
#   选项处理函数参数偏移量
EXTRA_SHIFT=${EXTRA_SHIFT:-""}


# ----------内置函数----------
# 当前时间
now() {
    date "+%Y-%m-%d %H:%M:%S"
}

# 时间戳
timestamp() {
    date "+%s"
}

# 字符串转换为大写
upper() {
    printf -- "%s" "$1" | tr '[:lower:]' '[:upper:]'
}

# 字符串转换为小写
lower() {
    printf -- "%s" "$1" | tr '[:upper:]' '[:lower:]'
}

# 去除两边空格
trim() {
    local string=$1
    string=$(echo "$string" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    printf -- "%s" "$string"
}

# 颜色输出
# println <color> <message>
println() {
    local full=$@
    local color=$(lower $1)
    shift
    local message=$@

    case $color in
        black)   printf -- "\033[1;31;30m%b\033[0m\n" "$message" ;;
        red)     printf -- "\033[1;31;31m%b\033[0m\n" "$message" ;;
        green)   printf -- "\033[1;31;32m%b\033[0m\n" "$message" ;;
        yellow)  printf -- "\033[1;31;33m%b\033[0m\n" "$message" ;;
        blue)    printf -- "\033[1;31;34m%b\033[0m\n" "$message" ;;
        purple)  printf -- "\033[1;31;35m%b\033[0m\n" "$message" ;;
        cyan)    printf -- "\033[1;31;36m%b\033[0m\n" "$message" ;;
        white)   printf -- "\033[1;31;37m%b\033[0m\n" "$message" ;;
        *)       printf -- "%b\n" "$full" ;;
    esac
}

# 日志输出
# log <level> <message>
log() {
    local xtrace=$(shopt -po xtrace); set +x
    local level=$(lower $1)
    shift
    local timestamp=$(now)
    local caller=$(caller)
    local message=$@
    local exit_code=0
    local color

    # 日志级别低于设定级别则不输出
    [ ${LOG_LEVELS[$level]} -lt ${LOG_LEVELS[$LOG_LEVEL]} ] && return

    case $level in
        debug) color="blue" ;;
        info)  color="green" ;;
        warn)  color="yellow" ;;
        error) color="red"; exit_code=1 ;;
        *)     level=unkown; color="cyan"; exit_code=1 ;;
    esac

    case $LOG_MODE in
        console) println $color "$timestamp [${level^^}] [caller: $caller] $message" ;;
        file)    println $color "$timestamp [${level^^}] [caller: $caller] $message" >> $LOG_FILE ;;
        multi)  println $color "$timestamp [${level^^}] [caller: $caller] $message" | tee -a $LOG_FILE ;;
    esac

    [ $exit_code -ne 0 ] && exit $exit_code
    eval $xtrace
}

# 信号处理
trap _exit INT QUIT TERM
_exit() {
    printf "\r"
    println red "$0 has been terminated."
    exit 1
}

# 帮助信息
_help() {
    printf -- "Usage: $0 [options]\n\n"
    printf -- "Options:\n"
    printf -- "  -h, --help                         帮助信息\n"
    printf -- "  -d, --debug                        调试模式\n"
    printf -- "  -x, --xtrace                       跟踪模式\n"
    printf -- "  -q, --quiet                        静默输出\n"
    printf -- "  --log-mode <console|file|multi>    日志模式\n"
    printf -- "  --log-file <file>                  日志文件\n"
    [ -n "$EXTRA_HELP" ] && printf -- "$EXTRA_HELP"
    exit 0
}
# 选项处理
# argparse [extra_argparse] <options>
argparse() {
    local extra_argparse=$1
    if declare -F $extra_argparse &> /dev/null; then
        shift
    fi

    while [ $# -gt 0 ]; do
        case $1 in
            -h|--help)
                _help
                ;;
            -d|--debug)
                LOG_LEVEL=debug
                shift
                ;;
            -x|--xtrace)
                set -x
                shift
                ;;
            -q|--quiet)
                if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    if [[ "$2" =~ ^(true|false)$ ]]; then
                        QUIET="$2"
                        shift 2
                    else
                        log error "-q|--quiet requires 'true' or 'false' as argument."
                    fi
                else
                    log error "-q|--quiet requires a non-empty option argument."
                fi
                ;;
            --log-mode)
                if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    if [[ "$2" =~ ^(console|file|multi)$ ]]; then
                        LOG_MODE="$2"
                        shift 2
                    else
                        log error "--log-mode requires 'console' or 'file' or 'multi' as argument."
                    fi
                else
                    log error "--log-mode requires a non-empty option argument."
                fi
                ;;
            --log-file)
                if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    LOG_FILE=$2
                    shift 2
                else
                    log error "--log-file requires a non-empty option argument."
                fi
                ;;
            *)
                if $extra_argparse $@; then
                    [ -n "$EXTRA_SHIFT" ] && shift $EXTRA_SHIFT
                    [ -z "$EXTRA_SHIFT" ] && shift
                else
                    log error "unknown option: $1"
                fi 
                ;;
        esac
    done
}; [[ ${BASH_SOURCE[0]} == ${0} ]] && argparse $@

# 参数解析
# 要想参数中能够带有空格，需要用双引号包裹$@; 例如: args "--name" "$@"
# args <param> <args> -d|--default <default> -v|--var <var> -r|--required
args() {
    local param=$1
    shift
    local default
    local __var
    local value
    local required

    while [ $# -gt 0 ]; do
        case $1 in
            -d|--default)
                if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    default=$(printf "%s" "$2")
                    shift
                fi
                ;;
            -v|--var)
                if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    __var="$2"
                    shift
                fi
                ;;
            -r|--required)
                required=true
                ;;
            *)
                if [[ "$param" =~ "$1" ]] && [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    value=$(printf "%s" "$2")
                    shift
                fi
                ;;
        esac
        shift
    done
    
    if [ "$required" == "true" ] && [ -z "$value" ]; then
        log error "missing required argument: $param"
    fi
    
    [ -n "$__var" ] && eval $__var=${value:-$default} || printf -- "%s" "${value:-$default}"
}

# 执行探测
# detect <command> -v|--var <var> -e|--exception <var>
detect() {
    local cmd
    local output
    local exit
    local __stdout
    local __exception
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--var)
                if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    __stdout=$2
                    shift
                fi
                ;;
            -e|--exception)
                if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                    __exception=$2
                    shift
                fi
                ;;
            *)
                cmd="$cmd $1"
                ;;
        esac
        shift
    done
    # 去除首尾空格
    cmd=$(trim "$cmd")

    log debug "${cmd}"

    local tmpfile
    tmpfile=$(mktemp)
    if [ "$QUIET" == "true" ]; then
        eval "$cmd" &> "$tmpfile"
    else
        eval "$cmd" &> >(tee "$tmpfile")
    fi
    exit=${PIPESTATUS[0]}
    output=$(<"$tmpfile")
    rm -f "$tmpfile" &> /dev/null

    if [ $exit -eq 0 ]; then
        [ -n "$__stdout" ] && eval "$__stdout=\$output"
    else
        [ -n "$__exception" ] && eval "$__exception=\$output" && return
        log error "execution command (${cmd}) failed: ${output}"
    fi
}

# 操作系统
os() {
    local os_name
    case "$(uname)" in
        *"NT"* | "CYGWIN"* | "MINGW"*)
            os_name="windows"
            ;;
        "Darwin"*)
            os_name="macos"
            ;;
        *)
            if [ -r /etc/os-release ]; then
                source /etc/os-release
                os_name="${ID}"
            else
                os_name="unknown"
            fi
            ;;
    esac

    printf -- "%s" "${os_name}"
}

# 命令是否存在
# cmdexs <command>
cmdexs() {
    local cmd="$1"
    if eval type type > /dev/null 2>&1; then
        eval type "$cmd" > /dev/null 2>&1
    elif command > /dev/null 2>&1; then
        command -v "$cmd" > /dev/null 2>&1
    else
        which "$cmd" > /dev/null 2>&1
    fi

    return $?
}

# 函数执行进度
# progress <function> <args>
progress() {
    local function=$1
    shift
    local args=$@
    local pid
    local i=0
    local spinner=("|" "/" "-" "\\")
    local length=${#spinner[@]}
    local interval=0.1

    $function $args &
    pid=$!

    while kill -0 $pid &> /dev/null; do
        i=$(( (i + 1) % $length ))
        printf -- "\r%s\r" "${spinner[$i]}"
        sleep $interval
    done

    wait $pid
    exit_status=$?
    if [ $exit_status -ne 0 ]; then
        exit $exit_status
    fi

    printf -- "\r"
}

# 解构
# destruct <array> var1 var2 ...
destruct() {
    local array=($1)
    shift
    local i=0
    for __var in "$@"; do
        if [ $i -eq $(($# - 1)) ]; then
            eval $__var=$(echo -e \${array[@]:$i})
        else
            eval $__var=${array[$i]}
        fi
        i=$((i+1))
    done
}

# 数组包含
# contains <array> <item>
contains() {
    local array=($1)
    local item=$2
    local element
    for element in ${array[@]}; do
        [ "$element" == "$item" ] && return
    done
    return 1
}

# 数组去重
# unique <array>
unique() {
    local array=($@)
    local unique=($(echo "${array[@]}" | tr ' ' '\n' | sort -n | uniq))
    echo -e "${unique[@]}"
}

# 数组合并去重
# merge <array1> <array2>
merge() {
    local array1=($1)
    local array2=($2)
    local merge=($(echo "${array1[@]} ${array2[@]}" | tr ' ' '\n' | sort -n | uniq))
    echo -e "${merge[@]}"
}

# 字符串分割
# split <string> <delimiter>
split() {
    local string=$1
    local delimiter=${2:-" "}
    local array
    IFS=$delimiter read -ra array <<< "$string"
    printf -- "%s" "${array[@]}"
}

# 填充
# pad <string> <length> <char> <side: left|right>
pad() {
    local string=$1
    local length=${2:-0}
    local char=${3:-""}
    local side=${4:-"right"}
    local pad
    local i

    for ((i=0; i<$length; i++)); do
        pad="${pad}${char}"
    done

    case $side in
        left)  printf -- "%s%s" "$pad" "$string" ;;
        right) printf -- "%s%s" "$string" "$pad" ;;
        *)     printf -- "%s" "$string" ;;
    esac
}

# 右边填充一个空格
rightpadonespace() {
    local string=$1
    local length=${#string}

    if [[ ${string:$length-1:1} != " " ]]; then
        string="${string} "
    fi

    printf -- "%s" "$string"
}

# 生成随机字符串, 默认长度为16, 默认不包含特殊字符
# random <length> <special: true|false>
random() {
    local length=${1:-16}
    local special=${2:-false}
    local string
    if [ "$special" == "true" ]; then
        string=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9!@#$%^&*()_+' | fold -w $length | head -n 1)
    else
        string=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1)
    fi
    printf -- "%s" "$string"
}

# 从字符串或数组中随机选择一个元素
# randomselect <...string|array>
randomselect() {
    local array=($@)
    local length=${#array[@]}
    local index=$(($RANDOM % $length))
    printf -- "%s" "${array[$index]}"
}

# 包管理器
# pkg <flag> <package>
pkg() {
    local flag=$1
    shift
    local package=$@
    local os=$(os)
    local cmd

    case "$flag" in
        remove)
            case "$os" in
                windows|macos) flag="uninstall" ;;
                alpine) flag="del" ;;
            esac
            ;;
        install)
            [ "$os" == "alpine" ] && flag="add"
            ;;
        *)
            log error "无效的操作: $flag. 只支持 install, remove."
            ;;
    esac

    case "$os" in
        windows)
            cmdexs choco || log error "请先安装Chocolatey"
            cmd="choco $flag $package -y"
            ;;
        macos)
            cmdexs brew || log error "请先安装Homebrew"
            cmd="brew $flag $package"
            ;;
        ubuntu|debian)
            cmd="apt-get update; apt-get $flag $package -y"
            ;;
        centos|rocky|fedora|rhel)
            cmdexs dnf && cmd="dnf $flag $package -y" || cmd="yum $flag $package -y"
            ;;
        alpine)
            cmd="apk update; apk $flag $package"
            ;;
        *)
            log error "暂不支持该系统${os}"
            ;;
    esac

    detect $cmd
}

# json转换关联数组
# json2array <data> <array>
json2array() {
    local data=$1
    local __array=$2
    local prefix=$3
    local result
    local key
    local value

    cmdexs jq || pkg install jq
    result=$(echo $data | jq -r 'to_entries|map("\(.key)=\(.value|tostring)")|.[]')

    for item in $result; do
        key=$(echo $item | cut -d= -f1)
        value=$(echo $item | cut -d= -f2-)
        if [[ $value == \{* ]] || [[ $value == \[* ]]; then
            json2array "$value" $__array "${prefix}${key}."
        fi
        eval $__array[${prefix}${key}]=\"$value\"
    done
}

# toml
# toml <file> <add|del|get|set> <key> [value]
toml() {
    local file=$1
    local action=$2
    local key=$3
    local value=$4
    local result

    [[ -f $file ]] || log error "文件不存在: $file"
    case $action in
        add)
            printf "%s=%s\n" "$key" "$value" >> $file
            ;;
        del)
            sed -i "/^\s*$key\s*=/d" $file
            ;;
        get)
            result=$(grep -E "^\s*$key\s*=" $file | cut -d= -f2-)
            printf -- "%s" $(trim "$result")
            ;;
        set)
            if grep -qE "^\s*$key\s*=" $file; then
                sed -i "s/^\s*$key\s*=.*/$key=$value/" $file
            else
                printf "%s=%s\n" "$key" "$value" >> $file
            fi
            ;;
        *)
            log error "无效的操作: $action"
            ;;
    esac
}

# http 请求
# http <method> <url> -d|--data <data> -h|--header <header> --response <var>
http() {
    local method=$(upper $1)
    local url=$2
    local __result
    args "-d|--data" "$@" -v data
    args "-h|--header" "$@" -d "Content-Type: application/json" -v header
    args "--response" "$@" -v __response
    
    [[ $method =~ ^(GET|POST|PUT|DELETE)$ ]] || log error "无效的请求方法: $method, 只支持GET, POST, PUT, DELETE"
    [ -z "$url" ] && log error "缺少URL参数"

    local cmd="curl -sS -X $method $url"
    [ -n "$data" ] && cmd="$cmd -d '$data'"
    if [ -n "$header" ]; then
        local headers=()
        IFS=',' read -ra headers <<< "$header"
        for item in "${headers[@]}"; do
            cmd="$cmd -H '$(trim "$item")'"
        done
    fi

    [ -n "$__response" ] && detect $cmd -v __result && eval $__response=\$__result || detect $cmd
}

# 下载动态进度条, 使用wget
# download <url>
download() {
    cmdexs wget || pkg install wget
    local url=$1
    local filename=$(basename $url)
    local cmd="wget -q --show-progress --progress=bar:force:noscroll $url -O $filename"
    QUIET=false detect $cmd
}

# 交互式输入
# input <message> var -d|--default <default>
input() {
    local message=$1
    local __var=$2
    shift 2
    local input

    local default=$(args "-d|--default" "$@")
    message=$(rightpadonespace "$message")
    local text=$(println cyan "$message")
    read -p "$text" input
    eval $__var=${input:-$default}
}

# 交互式选择
# iselect <message> <options> var
iselect() {
    local message=$1
    local options=($2)
    local __var=$3
    shift 3
    local input

    message=$(rightpadonespace "$message")
    PS3=$(println cyan "$message")
    select option in "${options[@]}"; do
        if [ -n "$option" ]; then
            eval $__var=$option
            break
        else
            println red "无效选项，请重新选择."
        fi
    done
}

# 交互式确认
# iconfirm <message> var
iconfirm() {
    local message=$1
    local __var=$2
    local input

    message=$(rightpadonespace "$(pad "$message" 1 "[y/n]" "right")")
    local text=$(println cyan "$message")
    read -p "$text" input
    [[ "$input" =~ ^[Yy]$ ]] && eval $__var=true || eval $__var=false
}

# 交互式输入密码
# ipassword <message> var
ipassword() {
    local message=$1
    local __var=$2
    local input

    message=$(rightpadonespace "$message")
    local text=$(println cyan "$message")
    read -s -p "$text" input
    eval $__var=$input
    printf "\n"
}

# 交互式输入多行
# imultiline <message> var
imultiline() {
    local message=$1
    local __var=$2
    local input

    println cyan "$message(Ctrl+D 退出)"
    input=$(cat)
    eval "$__var=\"\$input\""
}

# 私网 IP 地址
privateip() {
    local ip=$(hostname -I | awk '{print $1}')
    printf -- "%s" "${ip}"
}

# 公网 IP 地址
# publicip -a|--api <api>
publicip() {
    args "-a|--api" "$@" -d "https://ipinfo.io/ip" -v api
    printf -- "%s" $(curl -sS $api)
}

# 获取IP地址的国家信息
# ip2country <ip> -a|--api <api>
ip2country() {
    local ip=$1
    args "-a|--api" "$@" -d "https://ipinfo.io" -v api
    cmdexs jq || pkg install jq
    local response=$(curl -sS "${api}/${ip}/json")
    local country=$(echo "${response}" | jq -r '.country')
    printf -- "%s" "${country}"
}

# 校验器
# validator <rule> <value>
validator() {
    local rule=$1
    local value=$2
    local pattern
    local message

    case $rule in
        email)
            pattern="^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
            message="邮箱格式不正确: $value"
            ;;
        url)
            pattern="^https?://[a-zA-Z0-9.-]+(:[0-9]+)?(/[a-zA-Z0-9._%+-]*)*(\?[a-zA-Z0-9._%+-=&]*)?$"
            message="URL格式不正确: $value"
            ;;
        domain)
            pattern="^([a-zA-Z0-9-]+\.){1,}([a-zA-Z0-9-]+)$"
            message="域名格式不正确: $value"
            ;;
        ipv4)
            pattern="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
            message="IPv4格式不正确: $value"
            ;;
        ipv6)
            pattern="^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$"
            message="IPv6格式不正确: $value"
            ;;
        *)
            log error "无效的校验规则: $rule"
            ;;
    esac

    [[ ! "$value" =~ $pattern ]] && log error "$message"
}

# 时间差
# timesub <time1> <time2>
timesub() {
    local time1
    local time2

    data -d $1 > /dev/null && time1=$(date -d "$1" +%s) || log error "无效日期: $1"
    data -d $2 > /dev/null && time2=$(date -d "$2" +%s) || log error "无效日期: $2"

    printf -- "%s" $((time1 - time2))
}

# 批量自动应答ssh-copy-id
# sshcopyid data -p|--publickey <publickey>
# data: host password port user
sshcopyid() {
    local data=$1
    local publickey host password port user
    args "-p|--publickey" "$@" -d "$HOME/.ssh/id_rsa.pub" -v publickey

    [ -f "$publickey" ] || log error "$publickey 不存在"
    cmdexs expect || pkg install expect
    cmdexs nc || pkg install nc
    while read -r line; do
        destruct "$line" host password port user
        [ -z "$host" ] && log error "缺少主机参数"
        [ -z "$password" ] && log error "缺少密码参数"
        [ -z "$port" ] && port=22
        [ -z "$user" ] && user=root

    # 测试连通性
    nc -z -w 1 $host $port &> /dev/null || log error "无法连接到主机: $host:$port"
    # 自动应答
expect << EOF
    set timeout 10
    spawn ssh-copy-id -p $port -i $publickey $user@$host
    expect {
        "yes/no" { send "yes\n"; exp_continue }
        "password:" { stty -echo; send "$password\n"; stty echo }
    }
EOF
    done <<< "$data"
}