#!/bin/bash
# 系统性能优化脚本

echo "⚡ 优化系统性能参数..."

# 创建系统优化配置文件
cat > /etc/sysctl.d/99-qdrant.conf << 'EOF'
# Qdrant向量数据库优化参数

# 虚拟内存配置
vm.max_map_count = 262144
vm.swappiness = 1
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# 网络配置
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 5000
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl = 30

# 文件描述符限制
fs.file-max = 2097152
fs.nr_open = 2097152

# 内存分配
vm.overcommit_memory = 1
EOF

# 应用配置
sysctl -p /etc/sysctl.d/99-qdrant.conf

# 配置用户限制
cat > /etc/security/limits.d/99-qdrant.conf << 'EOF'
# Qdrant用户资源限制
qdrant soft nofile 65536
qdrant hard nofile 65536
qdrant soft nproc 32768
qdrant hard nproc 32768
qdrant soft memlock unlimited
qdrant hard memlock unlimited
EOF

# 配置systemd用户限制
mkdir -p /etc/systemd/system/qdrant.service.d
cat > /etc/systemd/system/qdrant.service.d/limits.conf << 'EOF'
[Service]
LimitNOFILE=65536
LimitNPROC=32768
LimitMEMLOCK=infinity
EOF

# 重新加载systemd配置
systemctl daemon-reload

echo "✅ 系统性能优化完成" 