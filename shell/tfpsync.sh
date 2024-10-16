#!/bin/bash

# 定义源目录和目标目录
SOURCE_DIR="${TFPROVIDER_SOURCE_DIR:-${HOME}/.terraform.d/plugin-cache}"
DESTINATION_DIR="${TFPROVIDER_DESTINATION_DIR:-${HOME}/.terraform.d/plugins}"

# 检查源目录和目标目录是否存在
if [ ! -d "$SOURCE_DIR" ]; then
    echo "错误：源目录 $SOURCE_DIR 不存在"
    exit 1
fi

if [ ! -d "$DESTINATION_DIR" ]; then
    echo "错误：目标目录 $DESTINATION_DIR 不存在"
    exit 1
fi

find "$SOURCE_DIR" -type f ! -name '.*' -o -type d | while read -r item; do
    # 忽略源自身目录
    if [ "$item" = "$SOURCE_DIR" ]; then continue; fi
    # 去掉源目录前缀，得到相对路径
    relative_path="${item#$SOURCE_DIR/}"

    if [ ! -e "$DESTINATION_DIR/$relative_path" ]; then
        # 如果目标目录中不存在该文件或目录，使用rsync进行同步
        if [ -d "$item" ]; then
            # 如果是目录，创建对应目录
            mkdir -p "$DESTINATION_DIR/$relative_path"
        elif [ -f "$item" ]; then
            # 如果是文件，进行同步
            # rsync -av "$item" "$DESTINATION_DIR/$relative_path"
            echo "LOG: START syncing $relative_path"
            rsync -a "$item" "$DESTINATION_DIR/$relative_path"
            echo "LOG: Syncing $relative_path END"
        fi
    fi
done
echo "同步完成"
