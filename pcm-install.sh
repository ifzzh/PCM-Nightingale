#!/bin/bash

echo "正在更新系统软件包..."
sudo yum update -y

echo "正在安装所需软件包..."
sudo yum install -y git cmake libasan gcc gcc-c++

echo "正在克隆 pcm 仓库..."
git clone --recursive https://github.com/intel/pcm

echo "切换到 pcm 目录..."
cd pcm

echo "创建构建目录..."
mkdir build

echo "切换到构建目录..."
cd build

build_dir=$(pwd)

echo "使用 cmake 配置构建..."
cmake ..

echo "正在构建 pcm..."
cmake --build .

echo "切换到工具目录..."
cd bin

bin_dir=$(pwd)

echo "创建 PCM 工具的符号链接..."
mkdir -p "$HOME/pcm-bin"
for tool in pcm pcm-core pcm-dram pcm-energy pcm-events pcm-freq pcm-latency pcm-memory pcm-numa pcm-power pcm-qpi pcm-sensor-server pcm-socket pcm-top pcm-wifi; do
    if [ -x "$bin_dir/$tool" ]; then
        ln -s "$bin_dir/$tool" "$HOME/pcm-bin/$tool"
    fi
done

echo "正在将 PCM 工具路径添加到 PATH 环境变量..."
echo "export PATH=\$PATH:$HOME/pcm-bin" >> ~/.bashrc
source ~/.bashrc

source ~/.bashrc

echo "安装完成。PCM 工具已可从任何目录直接调用，例如："
echo "1. 监控内存带宽，延迟 1 秒："
echo " sudo pcm-memory 1"
echo "2. 监控电源消耗："
echo " sudo pcm-power"
echo "3. 监控核心性能："
echo " sudo pcm-core"
echo "请注意，如果工具需要 root 权限，可能需要使用 sudo 运行。"
