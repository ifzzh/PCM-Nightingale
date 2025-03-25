#!/bin/bash
set -e

cleanup() {
    echo '执行清理操作...'
    [ -d "pcm" ] && rm -rf pcm
    [ -d "$HOME/pcm-bin" ] && rm -rf "$HOME/pcm-bin"
}
trap cleanup EXIT

set -o pipefail

# 在脚本开头添加颜色变量定义
ERROR_COLOR="$(tput setaf 1)"
SUCCESS_COLOR="$(tput setaf 2)"
NOTICE_COLOR="$(tput setaf 3)"
SECTION_COLOR="$(tput setaf 4)"
RESET_COLOR="$(tput sgr0)"

# 系统更新部分添加绿色进度提示
echo "${SUCCESS_COLOR}▶ 正在更新系统软件包...${RESET_COLOR}"
sudo yum update -y || { echo "${ERROR_COLOR}✖ 系统更新失败${RESET_COLOR}"; exit 1; }

# 软件安装部分添加绿色进度提示
echo "${SUCCESS_COLOR}▶ 正在安装所需软件包...${RESET_COLOR}"
sudo yum install -y git cmake libasan gcc gcc-c++ || { echo "${ERROR_COLOR}✖ 软件包安装失败${RESET_COLOR}"; exit 1; }

# 关键步骤添加蓝色分隔线
echo "${SECTION_COLOR}════════════════════════════════════════"
echo " 正在克隆 pcm 仓库 "
echo "════════════════════════════════════════${RESET_COLOR}"
git clone --recursive https://github.com/intel/pcm || { echo "${ERROR_COLOR}✖ 仓库克隆失败${RESET_COLOR}"; exit 1; }

# 编译构建部分添加蓝色分隔线
echo "${SECTION_COLOR}════════════════════════════════════════"
echo " 正在构建 PCM 工具 "
echo "════════════════════════════════════════${RESET_COLOR}"
cd build || { echo "${ERROR_COLOR}✖ 切换构建目录失败${RESET_COLOR}"; exit 1; }
cmake .. || { echo "${ERROR_COLOR}✖ CMake配置失败${RESET_COLOR}"; exit 1; }
cmake --build . || { echo "${ERROR_COLOR}✖ 构建失败${RESET_COLOR}"; exit 1; }

echo "切换到 pcm 目录..."
cd pcm

echo "创建构建目录..."
mkdir build || { echo '创建构建目录失败'; exit 1; }

echo "切换到构建目录..."
cd build || { echo '切换构建目录失败'; exit 1; }

build_dir=$(pwd)

echo "使用 cmake 配置构建..."
cmake .. || { echo 'CMake配置失败'; exit 1; }

echo "正在构建 pcm..."
cmake --build . || { echo '构建失败'; exit 1; }

echo "切换到工具目录..."
cd bin

bin_dir=$(pwd)

echo "创建 PCM 工具的符号链接..."
mkdir -p "$HOME/pcm-bin" || { echo '创建用户目录失败'; exit 1; }
for tool in pcm pcm-core pcm-dram pcm-energy pcm-events pcm-freq pcm-latency pcm-memory pcm-numa pcm-power pcm-qpi pcm-sensor-server pcm-socket pcm-top pcm-wifi; do
    if [ -x "$bin_dir/$tool" ]; then
        ln -s "$bin_dir/$tool" "$HOME/pcm-bin/$tool" || { echo '创建$tool符号链接失败'; exit 1; }
    fi
done

echo "正在将 PCM 工具路径添加到 PATH 环境变量..."
grep -q "pcm-bin" ~/.bashrc || echo "export PATH=\$PATH:$HOME/pcm-bin" >> ~/.bashrc
source ~/.bashrc
hash -r

echo '环境变量配置已添加到 ~/.bashrc，如仍无法调用请手动执行以下命令生效：'
echo 'exec $SHELL  # 重新加载shell配置'
echo '或重新登录系统'

SUCCESS_COLOR="$(tput setaf 2)"
NOTICE_COLOR="$(tput setaf 3)"
RESET_COLOR="$(tput sgr0)"

cat <<EOF

${SUCCESS_COLOR}=== PCM 工具安装完成 ===${RESET_COLOR}

现在可以通过以下命令使用 PCM 监控工具：

${NOTICE_COLOR}── 内存带宽监控 ──
• 命令格式：sudo pcm-memory [刷新间隔(秒)]
• 示例命令：sudo pcm-memory 1${RESET_COLOR}

${NOTICE_COLOR}── 电源消耗监控 ──
• 命令格式：sudo pcm-power
• 持续监控系统功耗${RESET_COLOR}

${NOTICE_COLOR}── 核心性能监控 ──
• 命令格式：sudo pcm-core
• 显示每个核心的频率和利用率${RESET_COLOR}

${SUCCESS_COLOR}──────────────────────
⚠ 注意：部分工具需要root权限
建议使用 sudo 执行监控命令
──────────────────────${RESET_COLOR}
EOF
