#!/usr/bin/env bash
# describepoint: install lib
# author: kochab

LIB_PATH="/usr/local/lib/kochab"
GITHUB_URL="https://github.com/kochabonline/script.git"
SUB_DIR="/shell/lib"

[ ! -d $LIB_PATH ] && mkdir -p $LIB_PATH

# dos2unix
__dos2unix() {
    command -v dos2unix > /dev/null && return

    source /etc/os-release
    os=$ID
    case $os in
        centos|fedora|rhel)
            yum install -y dos2unix
            ;;
        ubuntu|debian)
            apt-get update; apt-get install -y dos2unix
            ;;
        alpine)
            apk update; apk add dos2unix
            ;;
        *)
            echo "Unsupported OS: $os"
            exit 1
            ;;
    esac

    for file in $(find $LIB_PATH$SUB_DIR -type f -name "*.sh"); do
        dos2unix $file
    done
}

# install
install() {
    git clone --filter=blob:none --sparse $GITHUB_URL $LIB_PATH
    cd $LIB_PATH
    git sparse-checkout set $SUB_DIR
}

# upgrade
upgrade() {
    cd $LIB_PATH
    git pull
}

#uninstall
uninstall() {
    rm -rf $LIB_PATH    
}

while [ $# -gt 0 ]; do
    case $1 in
        -i|--install)
            install
            __dos2unix
            ;;
        -u|--upgrade)
            upgrade
            __dos2unix
            ;;
        -r|--remove)
            uninstall
            ;;
        *)
            echo "Usage: $0 [-i|--install] [-u|--upgrade] [-r|--remove]"
            exit 1
            ;;
    esac
    shift
done