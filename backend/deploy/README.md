# Qdrant on OpenCloudOS 部署指南

本目录包含在腾讯云OpenCloudOS系统上部署Qdrant向量数据库的完整脚本集合。

## 🚀 快速开始

### 一键部署
```bash
# 下载并执行一键部署脚本
chmod +x deploy_qdrant_opencloudos.sh
./deploy_qdrant_opencloudos.sh
```

### 分步部署
```bash
# 1. 系统初始化
./01_init_opencloudos.sh

# 2. 安装Rust环境
./02_install_rust.sh

# 3. 安装Qdrant（选择其中一种方式）
./03_install_qdrant_from_source.sh    # 从源码编译
./04_install_qdrant_binary.sh         # 使用预编译二进制

# 4. 配置日志
./05_setup_qdrant_logging.sh

# 5. 配置systemd服务
./06_setup_qdrant_service.sh

# 6. 配置防火墙
./07_configure_firewall.sh

# 7. 配置SELinux（如果启用）
./08_configure_selinux.sh

# 8. 系统优化
./09_optimize_system.sh

# 9. 磁盘优化
./10_optimize_disk.sh
```

## 📁 脚本文件说明

### 安装脚本
- `01_init_opencloudos.sh` - OpenCloudOS系统初始化
- `02_install_rust.sh` - Rust环境安装
- `03_install_qdrant_from_source.sh` - Qdrant源码编译安装
- `04_install_qdrant_binary.sh` - Qdrant预编译二进制安装

### 配置脚本
- `05_setup_qdrant_logging.sh` - 日志配置
- `06_setup_qdrant_service.sh` - systemd服务配置
- `07_configure_firewall.sh` - 防火墙配置
- `08_configure_selinux.sh` - SELinux配置

### 优化脚本
- `09_optimize_system.sh` - 系统性能优化
- `10_optimize_disk.sh` - 磁盘I/O优化

### 维护脚本
- `monitor_qdrant.sh` - 服务监控
- `backup_qdrant.sh` - 数据备份
- `test_qdrant_api.sh` - API测试
- `troubleshoot_qdrant.sh` - 故障排除

### 配置文件
- `qdrant-config.yaml` - Qdrant主配置文件
- `qdrant.service` - systemd服务文件

### 主脚本
- `deploy_qdrant_opencloudos.sh` - 一键部署主脚本

## 🔧 使用说明

### 环境要求
- OpenCloudOS 8.6+
- 2GB+ RAM
- 20GB+ 磁盘空间
- root权限

### 服务器规格推荐
```
小型项目: 2核4GB, 40GB SSD
中型项目: 4核8GB, 100GB SSD
大型项目: 8核16GB, 200GB+ SSD
```

### 服务管理
```bash
# 查看服务状态
systemctl status qdrant

# 启动/停止/重启服务
systemctl start qdrant
systemctl stop qdrant
systemctl restart qdrant

# 查看日志
journalctl -u qdrant -f

# 快速状态检查
qdrant-status
```

### API访问
```bash
# 健康检查
curl http://localhost:6333/health

# Web UI
http://your-server-ip:6333/dashboard

# REST API
http://your-server-ip:6333

# gRPC API
your-server-ip:6334
```

## 🛠️ 维护

### 监控
```bash
# 运行监控脚本
./monitor_qdrant.sh

# 持续监控
watch -n 30 "./monitor_qdrant.sh"
```

### 备份
```bash
# 手动备份
./backup_qdrant.sh

# 设置定时备份（每天2点）
echo "0 2 * * * /path/to/backup_qdrant.sh" | crontab -
```

### 故障排除
```bash
# 运行故障排除脚本
./troubleshoot_qdrant.sh

# 查看详细日志
tail -f /var/log/qdrant/qdrant.log
```

## 📊 性能调优

### 配置调整
编辑 `/etc/qdrant/config.yaml` 调整以下参数：
- `max_concurrent_searches` - 最大并发搜索数
- `wal_capacity_mb` - WAL文件大小
- `hnsw_index.m` - HNSW索引连接数
- `hnsw_index.ef_construct` - 构建时候选数量

### 系统调优
```bash
# 应用系统优化
./09_optimize_system.sh

# 应用磁盘优化
./10_optimize_disk.sh
```

## 🔐 安全建议

1. 配置防火墙规则，限制访问源
2. 使用反向代理（Nginx）进行SSL加密
3. 定期更新系统和Qdrant版本
4. 监控日志文件，发现异常访问

## 📞 故障支持

如果遇到问题：
1. 运行 `./troubleshoot_qdrant.sh` 获取诊断信息
2. 检查 `/var/log/qdrant/` 下的日志文件
3. 确认防火墙和SELinux配置
4. 检查系统资源使用情况

## 📝 更新日志

- v1.0 - 初始版本，支持OpenCloudOS基础部署
- v1.1 - 添加性能优化和监控脚本
- v1.2 - 增强故障排除和备份功能
``` 