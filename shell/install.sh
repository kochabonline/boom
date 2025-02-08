#!/usr/bin/env bash
# describepoint: install lib
# author: kochab

LIB_PATH="/usr/local/lib/kochab"
GITHUB_URL="https://github.com/kochabonline/boom.git"
SUB_DIR="/shell/lib"

[ ! -d $LIB_PATH ] && mkdir -p $LIB_PATH

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
            ;;
        -u|--upgrade)
            upgrade
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