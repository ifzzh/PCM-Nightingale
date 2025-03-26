# 删除Prometheus容器
if [ -f "prometheus_container.id" ]; then
    container_id=$(cat prometheus_container.id)
    ${CTR_RUN} rm -f $container_id || echo "删除Prometheus容器失败或容器不存在"
    rm -f prometheus_container.id
fi