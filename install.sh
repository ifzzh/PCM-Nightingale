#!/bin/bash

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# 格式化输出函数
info() { echo -e "${BLUE}➜ ${RESET}$1"; }
success() { echo -e "${GREEN}✓ ${RESET}$1"; }
error() { echo -e "${RED}✗ ${RESET}$1"; exit 1; }
warn() { echo -e "${YELLOW}⚠ ${RESET}$1"; }

# 进度条动画
progress_bar() {
  local delay=0.75
  local spinstr='|/—\\'
  
  info "$1..."
  for i in {1..10}; do
    printf "[%-3s] \033[34m◼\033[0m.\033[33m◼\033[0m.\033[32m◼\033[0m" "${spinstr:0:1}"
    spinstr=${spinstr#?}${spinstr%???}
    sleep $delay
  done
  printf "\033[K"
}


current_dir="$(dirname "$0")"

# 安装流程
progress_bar "Starting Installation"
info "正在设置执行权限"
chmod +x ./pcm-install.sh || error "权限设置失败"
success "权限设置成功"

progress_bar "Running installer"
./pcm-install.sh || error "主程序安装失败"
success "主程序安装完成"


info "Finalizing setup"
cd "$current_dir" || error "切换目录失败"
chmod +x ./pcm-start.sh || warn "启动脚本权限异常"
./pcm-start.sh || warn "启动脚本执行警告"

# 添加Prometheus启动流程
progress_bar "Starting Prometheus"
cd "$current_dir" || error "切换目录失败"
if [ ! -f "./Prometheus-start.sh" ]; then
    error "Prometheus启动脚本不存在"
fi
chmod +x ./Prometheus-start.sh || error "Prometheus脚本权限设置失败"
./Prometheus-start.sh "$1:9738" || error "Prometheus启动失败"

progress_bar "Finalizing configuration"
success "Installation completed successfully!"
echo -e "${GREEN}🎉 All done! Happy coding! ${RESET}"