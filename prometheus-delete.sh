#!/bin/bash

set -eo pipefail

# 保存初始工作目录
ORIGINAL_DIR="$(pwd)"
trap "cd \"$ORIGINAL_DIR\"" EXIT

# 切换到grafana配置目录
TARGET_DIR="pcm/scripts/grafana"
if [ ! -d "$TARGET_DIR" ]; then
  echo -e "${RED}❌ 无法定位grafana配置目录: $TARGET_DIR${RESET}"
  exit 1
fi
cd "$TARGET_DIR" || {
    echo -e "${RED}❌ 目录切换失败: $TARGET_DIR${RESET}"
    exit 1
}

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

# 容器ID文件路径
CONTAINER_ID_FILE="$(pwd)/container_ids/prometheus.id"

# 清理函数
clean_prometheus() {
  echo -e "\n${YELLOW}🗑  开始清理Prometheus资源...${RESET}"

  # 删除Prometheus容器
  if [[ -f "$CONTAINER_ID_FILE" ]]; then
    container_id=$(cat "$CONTAINER_ID_FILE")
    if docker rm -f "$container_id" >/dev/null 2>&1; then
      echo -e "${GREEN}✓ 已删除Prometheus容器: ${container_id:0:12}${RESET}"
    fi
    rm -f "$CONTAINER_ID_FILE"
  fi

  # 移除监控网络
  if docker network inspect prometheus-network >/dev/null 2>&1; then
    if docker network rm prometheus-network >/dev/null 2>&1; then
      echo -e "${GREEN}✓ 已移除监控网络${RESET}"
    fi
  fi

  # 删除专属存储卷
  if [[ -d "prometheus_volume" ]]; then
    rm -rf prometheus_volume
    echo -e "${GREEN}✓ 已删除Prometheus存储卷${RESET}"
  fi

  # 清理配置文件
  if [[ -f "prometheus.yml" ]]; then
    rm -f prometheus.yml
    echo -e "${GREEN}✓ 已清理配置文件${RESET}"
  fi
}

# 执行清理
clean_prometheus

echo -e "\n\n${GREEN}✅✅✅ Prometheus资源清理完成！✅✅✅${RESET}"
echo -e "${YELLOW}⚠  注意: Grafana相关资源仍保留在以下路径："
echo -e "• Grafana容器ID: ${CONTAINER_ID_DIR}/grafana.id"
echo -e "• 仪表板数据: grafana_volume/${RESET}"

exit 0