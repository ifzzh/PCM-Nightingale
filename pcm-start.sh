#!/bin/bash

# 检查构建目录是否存在
if [ ! -f "pcm/build/bin/pcm-sensor-server" ]; then
    echo "错误：请先编译pcm-sensor-server (在pcm/build/bin目录下未找到可执行文件)"
    exit 1
fi

# 启动服务并记录PID
nohup pcm/build/bin/pcm-sensor-server > pcm-sensor.log 2>&1 &
SERVER_PID=$!

echo "启动pcm-sensor-server (PID: $SERVER_PID)"
echo $SERVER_PID > pcm-sensor.pid

# 状态检查
sleep 1
if ps -p $SERVER_PID > /dev/null; then
    echo "服务启动成功，日志保存在: $(pwd)/pcm-sensor.log"
else
    echo "错误：服务启动失败，请检查日志"
    rm pcm-sensor.pid
    exit 2
fi