#!/bin/bash

set -eo pipefail

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

# 进度条动画
progress_bar() {
  local delay=0.75
  local spinstr='|/—\'
  
  info "$1..."
  for i in {1..10}; do
    printf "[%-3s] %s" "${spinstr:0:1}" "${BLUE}◼${RESET}"."${YELLOW}◼${RESET}"."${GREEN}◼${RESET}"
    spinstr=${spinstr#?}${spinstr%???}
    sleep $delay
  done
  printf "\033[K"
}

# 主卸载流程
main() {
  progress_bar "Starting Uninstallation"

  # 第一阶段：清理Grafana
  progress_bar "Removing Grafana"
  if [ -f "./grafana-delete.sh" ]; then
    chmod +x ./grafana-delete.sh || error "Grafana脚本权限设置失败"
    ./grafana-delete.sh || error "Grafana资源清理失败"
    success "Grafana资源已清理"
  else
    error "未找到grafana-delete.sh"
  fi

  # 第二阶段：清理Prometheus
  progress_bar "Removing Prometheus"
  if [ -f "./prometheus-delete.sh" ]; then
    chmod +x ./prometheus-delete.sh || error "Prometheus脚本权限设置失败"
    ./prometheus-delete.sh || error "Prometheus组件卸载失败"
    success "Prometheus组件已移除"
  else
    error "未找到prometheus-delete.sh"
  fi

  # 第三阶段：卸载PCM核心
  progress_bar "Removing PCM Core"
  if [ -f "./uninstall-pcm.sh" ]; then
    chmod +x ./uninstall-pcm.sh || error "PCM卸载脚本权限设置失败"
    ./uninstall-pcm.sh || error "PCM核心卸载失败"
    success "PCM核心组件已移除"
  else
    error "未找到uninstall-pcm.sh"
  fi

  echo -e "\n${GREEN}✅✅✅ 所有组件卸载完成！✅✅✅${RESET}"
}

main "$@"