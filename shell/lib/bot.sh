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
# dingtalk <message> -t|--token <token> -s|--secret <secret> -m|--mode <mode>
dingtalk() {
    local baseurl="https://oapi.dingtalk.com/robot/send?access_token="
    local message=$1
    args "-t|--token" $@ -r -v token
    args "-s|--secret" $@ -v secret
    args "-m|--mode" $@ -d "markdown" -v mode
    local url
    local data

    if [ -z "$secret" ]; then
        url="${baseurl}${token}"
    else
        local timestamp=$(date +%s%3N)
        local sign=$(echo -ne "${timestamp}\n${secret}" | openssl dgst -sha256 -hmac "${secret}" -binary | base64)
        url="${baseurl}${token}&timestamp=${timestamp}&sign=${sign}"        
    fi

    case $mode in
        markdown)
            local data="{\"msgtype\": \"markdown\", \"markdown\": {\"title\": \"你有一条新的消息,请注意查收\", \"text\": \"${message}\"}}"
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
# lark <message> -t|--token <token> -m|--mode <mode>
lark() {
    local baseurl="https://open.feishu.cn/open-apis/bot/v2/hook/"
    local message=$1
    args "-t|--token" $@ -r -v token
    args "-m|--mode" $@ -d "markdown" -v mode
    local url
    local data

    url="${baseurl}${token}"

    case $mode in
        markdown)
            local data="{\"msg_type\": \"interactive\", \"card\": {\"config\": {\"wide_screen_mode\": true}, \"elements\": [{\"tag\": \"div\", \"text\": {\"content\": \"${message}\", \"tag\": \"lark_md\"}}]}}"
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