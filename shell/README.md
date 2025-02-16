# 快速开始

### 本地调用函数库

- 安装函数库

```bash
curl -so- https://raw.githubusercontent.com/kochabonline/boom/refs/heads/master/shell/install.sh | bash -s -- -i
```

- 本地脚本添加导入函数

```bash
#!/usr/bin/env bash

import() {
    local lib="/usr/local/lib/kochab/shell/lib/builtin.sh"
    [[ -f ${lib} ]] || {
        curl -so- https://raw.githubusercontent.com/kochabonline/boom/refs/heads/master/shell/install.sh | bash -s -- -i
    }
    source ${lib}
}; import
argparse $@
```

#### 远程调用函数库

```bash
#!/usr/bin/env bash

source <(curl -sS --max-time 10 'https://raw.githubusercontent.com/kochabonline/boom/refs/heads/master/shell/lib/builtin.sh')
argparse $@
```

### 扩展argparse函数

```bash
# 扩展帮助信息
EXTRA="false"
ANOTHER=""
EXTRA_HELP="  -e, --extra    <arg>           extra argument
  -a, --another  <arg>           another argument
"
extra_argparse() {
    case $1 in
        -e|--extra)
            EXTRA="true"
            EXTRA_SHIFT=1 # 必须要返回shift的个数, 否则无法移动参数
            ;;
        -a|--another)
            if [ -n "$2" ] && [ "${2:0:1}" != "-" ]; then
                ANOTHER=$2
                EXTRA_SHIFT=2 # 必须要返回shift的个数, 否则无法移动参数
            else
                log error "-a|--another requires a non-empty argument"
            fi
            ;;
        *)
            return 1
            ;;
    esac
}
argparse extra_argparse $@
```