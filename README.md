# PCM-Nightingale 监控系统

## 项目概述
基于Intel PCM性能计数器打造的硬件级监控系统，提供：
- 实时CPU/内存/缓存性能指标采集
- 多节点监控数据汇聚
- Prometheus/Grafana可视化集成
- 告警规则管理

## 快速安装
```bash
# 安装核心组件
sudo ./install.sh <本机IP>
```

## 核心脚本
| 脚本名称                  | 功能描述                           |
|-------------------------|----------------------------------|
| `pcm-start.sh`          | 启动PCM传感器服务                 |
| `uninstall-pcm.sh`           | 停止服务并清理资源                |
| `Prometheus-start.sh`   | 启动Prometheus集成服务               |
| `grafana-delete.sh`     | 清理Grafana配置                   |
| `prometheus-delete.sh`  | 卸载Prometheus服务               |
| `uninstall.sh`          | 完整卸载监控系统                 |
| `pcm-install.sh`        | 安装PCM核心组件                  |
| `install.sh`            | 一键部署完整监控体系                  |



## 运维指南
### 一键部署

### 服务验证
```bash
# 检查服务状态
curl http://localhost:9738/metrics

# 查看实时日志
tail -f pcm-sensor.log
```

### 分步执行
```
        安装阶段                         运行阶段                         卸载阶段
           │                               │                              │
           ▼                               ▼                              ▼
┌─────────────────────┐         ┌──────────────────────┐        ┌─────────────────────┐
│   pcm-install.sh    │ ──────> │    pcm-start.sh      │        │  grafana-delete.sh  │
└─────────────────────┘         └──────────────────────┘        └─────────────────────┘
                                           │                              │
                                           ▼                              ▼
                                ┌──────────────────────┐        ┌──────────────────────┐
                                │  Prometheus-start.sh │        │ prometheus-delete.sh │
                                └──────────────────────┘        └──────────────────────┘
                                                                          │
                                                                          ▼
                                                                ┌──────────────────────┐
                                                                │   uninstall-pcm.sh   │
                                                                └──────────────────────┘

```

### 常见问题
**Q1: 启动时提示权限不足**  
执行`chmod +x *.sh`授予脚本执行权限

**Q2: Prometheus无法连接**  
检查防火墙设置：`sudo ufw allow 9738/tcp`

**卸载操作示例**  
```bash
# 完整卸载（保留配置）
./uninstall.sh --keep-config

# 强制彻底卸载
./uninstall.sh --force
```

## 架构示意图
```
+---------------+     +----------------+     +-------------------+
| PCM Sensor    | --> | Prometheus     | --> | Grafana Dashboard |
|   (9738)      |     |   (9090)       |     |    (3000)         |
+---------------+     +----------------+     +-------------------+
```