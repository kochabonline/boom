# 快速开始

```bash
curl -so- https://raw.githubusercontent.com/kochabonline/script/refs/heads/master/shell/<xx>.sh | bash
```

### 本地调用函数库

- 安装函数库

```bash
curl -so- https://raw.githubusercontent.com/kochabonline/script/refs/heads/master/shell/install.sh | bash -s -- -i
```

- 本地脚本添加导入函数

```bash
#!/usr/bin/env bash

source /usr/local/lib/kochab/shell/lib/builtin.sh
option $@
```

#### 远程调用函数库

```bash
#!/usr/bin/env bash

source <(curl -sS --max-time 10 'https://raw.githubusercontent.com/kochabonline/script/refs/heads/master/shell/lib/builtin.sh')
option $@
```

### 扩展option函数

```bash
# 扩展帮助信息
EXTRA_HELP=""
extra_option() {
    case $1 in
        -e|--extra)
            ;;
        *)
            return 1
            ;;
    esac
}
option extra_option $@
```

# Unix风格

```bash
dos2unix <file>
```