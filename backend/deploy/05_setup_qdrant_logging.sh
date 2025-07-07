#!/bin/bash
# Qdrant日志配置脚本

echo "📝 配置Qdrant日志..."

# 创建日志配置目录
mkdir -p /etc/qdrant

# 创建logrotate配置，自动轮换日志文件
cat > /etc/logrotate.d/qdrant << 'EOF'
/var/log/qdrant/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 qdrant qdrant
    postrotate
        systemctl reload qdrant || true
    endscript
}
EOF

# 设置权限
chown root:root /etc/logrotate.d/qdrant
chmod 644 /etc/logrotate.d/qdrant

echo "✅ Qdrant日志配置完成！" 