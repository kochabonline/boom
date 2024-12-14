#!/usr/bin/env bash
# describepoint: tailscale
# author: kochab

source <(curl -sS --max-time 10 https://raw.githubusercontent.com/kochabonline/script/refs/heads/master/shell/lib/builtin.sh)
option $@

os=$(os)

install() {
    log info "正在安装Tailscale..."
    case ${os} in
        windows)
            detect curl -fsSL https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe -o tailscale-setup-latest.exe
            detect ./tailscale-setup-latest.exe -quiet -norestart -install INSTALLDIR="/d/Applications/Tailscale"
            ;;
        macos)
            detect curl -fsSL https://pkgs.tailscale.com/stable/Tailscale-latest-macos.pkg -o Tailscale-latest-macos.pkg
            detect sudo installer -pkg Tailscale-latest-macos.pkg -target /Applications
            ;;
        *)
            log error "暂不支持该系统${os}"
            ;;
    esac
    log info "Tailscale安装完成"
}

# 注册
register() {
    local path
    case $os in
        windows)
            detect where tailscale -v result
            path=$(cygpath -u $result)
            ;;
        macos)
            detect which tailscale -v result
            path=$result
            ;;
        *)
            log error "暂不支持该系统${os}"
            ;;
    esac

    input "请输入headscale服务器地址" api
    QUIET=false detect ./$path up --login-server $api
}

main() {
    progress install
    register
}

main