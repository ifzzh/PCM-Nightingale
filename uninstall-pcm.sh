#!/bin/bash

# 删除pcm源码目录
echo "正在删除pcm安装目录..."
rm -rf "$(dirname \"$0\")/pcm"

# 删除符号链接目录
echo "正在删除符号链接..."
rm -rf "$HOME/pcm-bin"

# 清理.bashrc配置
echo "清理环境变量配置..."
sed -i '/export PATH=\$PATH:\$HOME\/pcm-bin/d' "$HOME/.bashrc"

# 提示需要重新加载配置
echo -e "\n卸载完成，正在重新加载配置..."
source ~/.bashrc
exec bash