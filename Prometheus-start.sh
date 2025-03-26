#!/bin/bash

set -e

CLEANUP_ENABLED=true
network_created=false
prometheus_container_created=false
prometheus_volume_created=false

cleanup() {
  if [[ "${CLEANUP_ENABLED}" != "true" ]]; then
    return 0
  fi

  echo "正在执行清理操作..." 
  
  if [[ -f "prometheus_container.id" ]]; then
    container_id=$(cat prometheus_container.id)
    ${CTR_RUN} rm -f $container_id >/dev/null 2>&1 || true
    rm -f prometheus_container.id
  fi

  if [[ "${network_created}" == "true" ]]; then
    ${CTR_RUN} network rm prometheus-network >/dev/null 2>&1 || true
  fi

  if [[ "${prometheus_volume_created}" == "true" ]]; then
    rm -rf prometheus_volume
  fi

  if [[ -f "prometheus.yml" ]]; then
    rm -f prometheus.yml
  fi
}
trap cleanup EXIT

usage() {
  echo
  echo "Usage: $0 target_address:port"
  echo
  echo "target_address是运行pcm-sensor-server的主机名或IP地址"
  echo
  echo "替代用法: $0 filename"
  echo
  echo "指定包含每行target_address:port的文件名"
  exit 1
}

validate_url() {
  local url=$1
  local regex='^([a-zA-Z0-9.-]+):[0-9]+$'
  local localhost_regex='^(localhost|127\.0\.0\.1):[0-9]+$'

  if ! [[ $url =~ $regex ]]; then
    echo "错误: 目标地址($url)格式不正确"
    usage
  fi

  if [[ $url =~ $localhost_regex ]]; then
    echo "错误: 目标地址不能是localhost或127.0.0.1"
    usage
  fi
}

if [ "$#" -ne 1 ]; then
  usage
fi

CTR_RUN=${CTR_RUN:-docker}

mkdir -p prometheus_volume || { echo "创建prometheus_volume目录失败"; exit 1; }
prometheus_volume_created=true
chmod -R 777 prometheus_volume || { echo "设置目录权限失败"; exit 1; }

if [ -f "$1" ]; then
  echo "正在为文件中的目标主机创建prometheus.yml"
  head -n -1 "pcm/scripts/grafana/prometheus.yml.template" > prometheus.yml || { echo "创建prometheus.yml失败"; exit 1; }
  while read -r line; do
    validate_url "$line"
    echo "    - targets: ['$line']" >> "prometheus.yml"
  done < "$1"
else
  validate_url "$1"
  echo "正在为$1创建prometheus.yml"
  sed "s#PCMSENSORSERVER#$1#g" pcm/scripts/grafana/prometheus.yml.template > prometheus.yml || { echo "创建prometheus.yml失败"; exit 1; }
fi

${CTR_RUN} network create prometheus-network || { echo "创建prometheus网络失败"; exit 1; }
network_created=true

echo "正在启动Prometheus"

${CTR_RUN} run --cidfile prometheus_container.id --name prometheus --network=prometheus-network -d -p 9090:9090 \
  -v "$PWD"/prometheus.yml:/etc/prometheus/prometheus.yml:Z \
  -v "$PWD"/prometheus_volume:/prometheus:Z \
  quay.io/prometheus/prometheus:latest || { echo "启动Prometheus失败"; exit 1; }

prometheus_container_created=true
echo ""

echo "==============================="
echo "Prometheus已成功启动"
echo "访问地址: http://HOSTIP:9090"
echo "请将此地址配置到夜莺监控系统作为数据源"
CLEANUP_ENABLED=false

echo "==============================="