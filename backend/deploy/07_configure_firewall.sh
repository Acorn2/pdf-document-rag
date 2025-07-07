#!/bin/bash
# 防火墙配置脚本

echo "🔧 配置防火墙规则..."

# 检查firewalld是否运行
if systemctl is-active --quiet firewalld; then
    echo "使用firewalld配置防火墙..."
    
    # 添加Qdrant端口
    firewall-cmd --permanent --add-port=6333/tcp  # REST API
    firewall-cmd --permanent --add-port=6334/tcp  # gRPC API
    
    # 添加SSH、HTTP、HTTPS端口（如果需要）
    firewall-cmd --permanent --add-port=22/tcp
    firewall-cmd --permanent --add-port=80/tcp
    firewall-cmd --permanent --add-port=443/tcp
    
    # 重新加载配置
    firewall-cmd --reload
    
    # 显示当前规则
    firewall-cmd --list-all
    
else
    echo "firewalld未运行，安装并配置firewalld..."
    
    # 安装firewalld
    dnf install -y firewalld
    
    # 启动和启用firewalld
    systemctl start firewalld
    systemctl enable firewalld
    
    # 添加端口规则
    firewall-cmd --permanent --add-port=6333/tcp
    firewall-cmd --permanent --add-port=6334/tcp
    firewall-cmd --permanent --add-port=22/tcp
    firewall-cmd --permanent --add-port=80/tcp
    firewall-cmd --permanent --add-port=443/tcp
    
    # 重新加载配置
    firewall-cmd --reload
fi

echo "✅ 防火墙配置完成"
echo "开放的端口："
firewall-cmd --list-ports 