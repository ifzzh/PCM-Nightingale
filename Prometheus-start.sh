#!/bin/bash

set -eo pipefail

# 记录初始工作目录
ORIGINAL_DIR=$(pwd)

# 切换到grafana配置目录
TARGET_DIR="pcm/scripts/grafana"
if [ ! -d "$TARGET_DIR" ]; then
  echo -e "${RED}❌ 无法定位grafana配置目录: $TARGET_DIR${RESET}"
  exit 1
fi
cd "$TARGET_DIR"

# 颜色定义
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
RESET='\033[0m'

# 记录容器ID的文件
CONTAINER_ID_DIR="$(pwd)/container_ids"
mkdir -p "$CONTAINER_ID_DIR"
chmod 777 "$CONTAINER_ID_DIR"

# 异常清理函数
cleanup() {
  if [[ -f "$CONTAINER_ID_FILE" ]]; then
    echo -e "\n${RED}⚠️  检测到异常退出，开始清理环境...${RESET}"
    for id_file in "$CONTAINER_ID_DIR"/*; do
  container_id=$(cat "$id_file")
      if $CTR_RUN rm -f "$container_id" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ 已清理容器: ${container_id:0:12}${RESET}"
      fi
    done < "$CONTAINER_ID_FILE"
    $CTR_RUN network rm prometheus-network >/dev/null 2>&1 || true
    rm -rf "$CONTAINER_ID_DIR" prometheus.yml
    echo -e "${GREEN}✅ 环境清理完成${RESET}"
  cd "$ORIGINAL_DIR"
  fi
}

trap cleanup EXIT SIGINT SIGTERM

# 使用说明函数
usage() {
  echo -e "\n${BLUE}📖 使用帮助:${RESET}"
  echo -e "${YELLOW}$0 目标地址:端口${RESET}"
  echo -e "\n🖥️  目标地址是运行pcm-sensor-server的主机名或IP地址"
  echo -e "\n📁 替代用法: ${YELLOW}$0 目标列表文件${RESET}"
  echo -e "\n📝 文件每行应包含一个目标地址:端口"
  exit 1
}

# 验证URL格式
validate_url() {
  local url=$1
  local regex='^([a-zA-Z0-9.-]+):[0-9]+$'

  if ! [[ $url =~ $regex ]]; then
    echo -e "\n${RED}❌ 错误: 目标地址格式不正确${RESET}"
    usage
  fi
}

# 主程序
main() {
  if [ "$#" -ne 1 ]; then
    usage
  fi

  CTR_RUN=${CTR_RUN:-docker}
  rm -f "$CONTAINER_ID_FILE"

  echo -e "\n${BLUE}🚀 正在初始化监控环境...${RESET}"

  # 创建必要目录
  mkdir -p grafana_volume/dashboards prometheus_volume provisioning/datasources || {
    echo -e "${RED}❌ 目录创建失败${RESET}"
    exit 1
  }

  chmod -R 777 *_volume || {
    echo -e "${RED}❌ 目录权限设置失败${RESET}"
    exit 1
  }

  # 复制配置文件
  cp automatic_prometheus.yml provisioning/datasources/automatic.yml || {
    echo -e "${RED}❌ 配置文件复制失败${RESET}"
    exit 1
  }

  # 处理目标参数
  if [ -f "$1" ]; then
    echo -e "\n${BLUE}📄 正在根据目标文件创建配置...${RESET}"
    head -n -1 "prometheus.yml.template" > prometheus.yml
    while read -r line; do
      validate_url "$line"
      echo "    - targets: ['$line']" >> prometheus.yml
    done < "$1"
    echo -e "\n${BLUE}⬇️  正在下载PCM仪表板...${RESET}"
    curl -o grafana_volume/dashboards/pcm-dashboard.json "$(head -1 "$1")/dashboard/prometheus"
  else
    validate_url "$1"
    echo -e "\n${BLUE}🎯 正在创建单一目标配置...${RESET}"
    sed "s#PCMSENSORSERVER#$1#g" prometheus.yml.template > prometheus.yml
    echo -e "\n${BLUE}⬇️  正在下载PCM仪表板...${RESET}"
    curl -o grafana_volume/dashboards/pcm-dashboard.json "$1/dashboard/prometheus"
  fi

  # 创建监控网络
  echo -e "\n${BLUE}🌐 正在创建监控网络...${RESET}"
  $CTR_RUN network create prometheus-network || {
    echo -e "${RED}❌ 网络创建失败${RESET}"
    exit 1
  }

  # 启动Prometheus
  echo -e "\n${BLUE}🔥 启动Prometheus服务...${RESET}"
  $CTR_RUN run --name prometheus --network=prometheus-network -d -p 9090:9090 \
    -v "$PWD/prometheus.yml:/etc/prometheus/prometheus.yml:Z" \
    -v "$PWD/prometheus_volume:/prometheus:Z" \
    --cidfile "$CONTAINER_ID_DIR/prometheus.id" \
    quay.io/prometheus/prometheus:latest || {
      echo -e "${RED}❌ Prometheus启动失败${RESET}"
      exit 1
    }

  # 启动Grafana
  echo -e "\n${BLUE}📊 启动Grafana仪表板...${RESET}"
  $CTR_RUN run -d --network=prometheus-network --name=grafana -p 3000:3000 \
    -v "$PWD/grafana_volume:/var/lib/grafana:Z" \
    -v "$PWD/provisioning:/etc/grafana/provisioning:Z" \
    -e GF_DASHBOARDS_MIN_REFRESH_INTERVAL=1s \
    --cidfile "$CONTAINER_ID_DIR/grafana.id" \
    docker.io/grafana/grafana:latest || {
      echo -e "${RED}❌ Grafana启动失败${RESET}"
      exit 1
    }

  # 显示成功信息
  echo -e "\n\n${GREEN}✅✅✅ 监控系统启动成功！✅✅✅${RESET}"
  echo -e "${BLUE}🌐 访问地址: http://localhost:3000${RESET}"
  echo -e "${YELLOW}🔑 默认账号: admin 密码: admin${RESET}"
  echo -e "\n${YELLOW}📥 仪表板导出指引:\n  1. 在Grafana左侧菜单选择'Dashboards'\n  2. 找到以${BLUE}Intel(r) Performance Counter Monitor${RESET}开头的仪表板\n  3. 点击右上角${GREEN}Export${RESET}按钮选择'Json'\n  4. 选择${YELLOW}Save to file${RESET}或直接复制JSON内容\n  5. 前往夜莺仪表板的导入界面完成配置${RESET}"
  echo -e "${YELLOW}💡 提示: 输入 Ctrl+C 可安全退出并保留容器${RESET}"
  echo -e "${YELLOW}🗑️  清理指引: 在夜莺中成功查看监控后，可运行 ${BLUE}pcm/scripts/grafana/grafana-delete.sh${YELLOW} 脚本清理部署产生的容器和资源${RESET}"

  # 正常退出前禁用清理
  trap - EXIT SIGINT SIGTERM
cd "$ORIGINAL_DIR"
  wait
}

main "$@"