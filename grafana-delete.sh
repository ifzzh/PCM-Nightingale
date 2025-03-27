#!/bin/bash

set -eo pipefail

ORIGINAL_DIR=$(pwd)
trap 'cd "$ORIGINAL_DIR"' EXIT

# 切换到grafana配置目录
TARGET_DIR="pcm/scripts/grafana"
if [ ! -d "$TARGET_DIR" ]; then
  echo -e "${RED}❌ 无法定位grafana配置目录: $TARGET_DIR${RESET}"
  exit 1
fi
cd "$TARGET_DIR" || exit 1

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# 容器ID目录
CONTAINER_ID_DIR="$(pwd)/container_ids"

# 安全确认函数
confirm_delete() {
  echo -e "\n${RED}⚠️  即将执行以下操作："
  echo -e "• 停止并删除Grafana监控容器"
  echo -e "• 清理网络资源"
  echo -e "• 删除临时文件${RESET}\n"
  
  read -p "是否继续？(y/n) " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}✅ 已取消删除操作${RESET}"
    exit 0
  fi
}

# 容器清理函数
clean_containers() {
  if [[ -d "$CONTAINER_ID_DIR" ]]; then
    echo -e "\n${BLUE}🧹 正在清理容器...${RESET}"
    
    for id_file in "$CONTAINER_ID_DIR"/grafana*.id; do
      if [[ -f "$id_file" ]]; then
        container_id=$(cat "$id_file")
        echo -e "${YELLOW}• 停止容器: ${container_id:0:12}${RESET}"
        docker stop "$container_id" >/dev/null 2>&1 || true
        
        echo -e "${YELLOW}• 删除容器: ${container_id:0:12}${RESET}"
        docker rm -f "$container_id" >/dev/null 2>&1 || true
        
        rm -f "$id_file"
      fi
    done
    echo -e "${GREEN}✓ 容器清理完成${RESET}"
  else
    echo -e "\n${YELLOW}⚠️  未找到容器ID目录，跳过容器清理${RESET}"
  fi
}


# 主程序
main() {
  confirm_delete
  
  clean_containers
  # clean_network
  
  # 清理残留文件
  echo -e "\n${BLUE}🗑  正在清理临时文件...${RESET}"
  # 清理Grafana volume
echo -e "\n${BLUE}🗑  正在清理Grafana存储卷...${RESET}"
rm -rf grafana_volume

echo -e "${BLUE}🗑  正在删除provisioning配置...${RESET}"
rm -rf provisioning

# 安全删除容器ID目录
if [[ -d "$CONTAINER_ID_DIR" ]] && [[ -z "$(ls -A "$CONTAINER_ID_DIR")" ]]; then
  echo -e "${BLUE}🗑  正在删除空目录...${RESET}"
  rmdir "$CONTAINER_ID_DIR"
fi
  
  echo -e "\n\n${GREEN}✅✅✅ 资源清理完成！✅✅✅${RESET}"
  echo -e "${BLUE}📢 提示: Grafana监控容器已永久删除，Prometheus资源保留${RESET}"
}

main "$@"