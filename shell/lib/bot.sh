#!/usr/bin/env bash
# describepoint: bot
# author: kochab

# 发送telegram消息
# telegram <message> -t|--token <token> -c|--chat <chat> -m|--mode <mode>
telegram() {
    local baseurl="https://api.telegram.org/bot"
    local message=$1
    args "-t|--token" $@ -r -v token
    args "-c|--chat" $@ -r -v chat
    args "-m|--mode" $@ -d "markdown" -v mode
    local url
    local data

    url="${baseurl}${token}/sendMessage"

    case $mode in
        markdown)
            local data="chat_id=${chat}&text=${message}&parse_mode=Markdown"
            ;;
        text)
            local data="chat_id=${chat}&text=${message}"
            ;;
        *)
            log error "无效的模式: $mode. 只支持 markdown, text."
            ;;
    esac

    local cmd="curl -sS -X POST -d '${data}' '${url}'"
    detect $cmd
}

# 发送钉钉消息 
# dingtalk <message> -w|--webhook <webhook> -s|--secret <secret> -m|--mode <mode>
dingtalk() {
    local message=$1
    args "-w|--webhook" $@ -r -v webhook
    args "-s|--secret" $@ -v secret
    args "-m|--mode" $@ -d "markdown" -v mode
    local url
    local data

    url="${webhook}"
    if [ ! -z "$secret" ]; then
        local timestamp=$(date +%s%3N)
        local sign=$(echo -ne "${timestamp}\n${secret}" | openssl dgst -sha256 -hmac "${secret}" -binary | base64)
        url="${webhook}&timestamp=${timestamp}&sign=${sign}"        
    fi

    case $mode in
        markdown)
            local data="{\"msgtype\": \"markdown\", \"markdown\": {\"title\": \"你有一条新的消息\", \"text\": \"${message}\"}}"
            ;;
        text)
            local data="{\"msgtype\": \"text\", \"text\": {\"content\": \"${message}\"}}"
            ;;
        *)
            log error "无效的模式: $mode. 只支持 markdown, text."
            ;;
    esac

    local cmd="curl -sS -X POST -H 'Content-Type: application/json' -d '${data}' '${url}'"
    detect $cmd
}

# 发送飞书消息
# lark <message> -w|--webhook <webhook> -s|--secret <secret> -m|--mode <mode>
lark() {
    local message=$1
    args "-w|--webhook" $@ -r -v webhook
    args "-s|--secret" $@ -v secret
    args "-m|--mode" $@ -d "markdown" -v mode
    local url
    local data

    url="${webhook}"
    if [ ! -z "$secret" ]; then
        local timestamp=$(date +%s%3N)
        local sign=$(echo -ne "${timestamp}\n${secret}" | openssl dgst -sha256 -hmac "${secret}" -binary | base64)
        url="${webhook}&timestamp=${timestamp}&sign=${sign}"        
    fi

    case $mode in
        markdown)
            local data="{\"msg_type\": \"post\", \"content\": {\"post\": {\"zh_cn\": {\"title\": \"你有一条新的消息\", \"content\": [[\"text\", \"${message}\"]]}}}}"
            ;;
        text)
            local data="{\"msg_type\": \"text\", \"content\": {\"text\": \"${message}\"}}"
            ;;
        *)
            log error "无效的模式: $mode. 只支持 markdown, text."
            ;;
    esac

    local cmd="curl -sS -X POST -H 'Content-Type: application/json' -d '${data}' '${url}'"
    detect $cmd
}