#!/bin/bash
set -e

# 颜色配置
ERROR_COLOR="$(tput setaf 1)"
SUCCESS_COLOR="$(tput setaf 2)"
SECTION_COLOR="$(tput setaf 4)"
RESET_COLOR="$(tput sgr0)"

# 停止PCM服务
PID_FILE="pcm-sensor.pid"
LOG_FILE="pcm-sensor.log"

echo "${SECTION_COLOR}════════════════════════════════════════"
echo " 正在停止PCM服务 "
echo "════════════════════════════════════════${RESET_COLOR}"

if [ -f "$PID_FILE" ]; then
    SERVER_PID=$(cat "$PID_FILE")
    echo "正在终止进程 $SERVER_PID"
    if kill $SERVER_PID; then
        rm -f "$PID_FILE" "$LOG_FILE"
        echo "${SUCCESS_COLOR}✓ 服务已成功停止${RESET_COLOR}"
    else
        echo "${ERROR_COLOR}✖ 无法终止进程，请手动检查${RESET_COLOR}"
        exit 2
    fi
else
    echo "${SUCCESS_COLOR}✓ 未找到运行中的服务${RESET_COLOR}"
fi


# 清理PCM源码目录
if [ -d "pcm" ]; then
    echo "${SECTION_COLOR}════════════════════════════════════════"
    echo " 正在清理PCM源码目录 "
    echo "════════════════════════════════════════${RESET_COLOR}"
    rm -rf pcm && echo "${SUCCESS_COLOR}✓ PCM源码清理完成${RESET_COLOR}" || {
        echo "${ERROR_COLOR}✖ PCM源码目录删除失败${RESET_COLOR}"
        exit 1
    }
fi

# 移除用户工具目录
if [ -d "$HOME/pcm-bin" ]; then
    echo "${SECTION_COLOR}════════════════════════════════════════"
    echo " 正在移除PCM工具集 "
    echo "════════════════════════════════════════${RESET_COLOR}"
    rm -rf "$HOME/pcm-bin" && echo "${SUCCESS_COLOR}✓ 用户工具目录清理完成${RESET_COLOR}" || {
        echo "${ERROR_COLOR}✖ 工具目录删除失败${RESET_COLOR}"
        exit 1
    }
fi

# 清理环境变量配置
if grep -q "pcm-bin" ~/.bashrc; then
    echo "${SECTION_COLOR}════════════════════════════════════════"
    echo " 正在清理环境变量配置 "
    echo "════════════════════════════════════════${RESET_COLOR}"
    sed -i '/pcm-bin/d' ~/.bashrc && echo "${SUCCESS_COLOR}✓ 环境变量配置已移除${RESET_COLOR}" || {
        echo "${ERROR_COLOR}✖ 环境变量清理失败${RESET_COLOR}"
        exit 1
    }
fi

echo "${SUCCESS_COLOR}\n=== PCM卸载完成 ===${RESET_COLOR}"