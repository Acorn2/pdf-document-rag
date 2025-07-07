#!/bin/bash
# Qdrant systemd服务配置脚本

echo "🚀 配置Qdrant系统服务..."

# 复制配置文件
cp $(dirname "$0")/qdrant-config.yaml /etc/qdrant/config.yaml
cp $(dirname "$0")/qdrant.service /etc/systemd/system/qdrant.service

# 设置配置文件权限
chown root:qdrant /etc/qdrant/config.yaml
chmod 640 /etc/qdrant/config.yaml

# 创建日志文件
touch /var/log/qdrant/qdrant.log
touch /var/log/qdrant/qdrant-error.log
chown qdrant:qdrant /var/log/qdrant/qdrant.log
chown qdrant:qdrant /var/log/qdrant/qdrant-error.log

# 重新加载systemd配置
systemctl daemon-reload

# 启用开机自启
systemctl enable qdrant

# 启动Qdrant服务
systemctl start qdrant

# 等待服务启动
echo "⏳ 等待Qdrant服务启动..."
sleep 10

# 检查服务状态
echo "📊 检查服务状态..."
systemctl status qdrant --no-pager

# 检查端口监听
echo "🔍 检查端口监听..."
ss -tlnp | grep 6333
ss -tlnp | grep 6334

# 测试服务健康状态
echo "🏥 测试服务健康状态..."
curl -f http://localhost:6333/health

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Qdrant服务启动成功！"
    echo ""
    echo "🔗 服务信息："
    echo "   REST API: http://$(curl -s ifconfig.me):6333"
    echo "   gRPC API: http://$(curl -s ifconfig.me):6334"
    echo "   Web UI: http://$(curl -s ifconfig.me):6333/dashboard"
    echo "   配置文件: /etc/qdrant/config.yaml"
    echo "   数据目录: /var/lib/qdrant/storage"
    echo "   日志文件: /var/log/qdrant/"
    echo ""
    echo "📝 常用管理命令："
    echo "   查看状态: systemctl status qdrant"
    echo "   查看日志: journalctl -u qdrant -f"
    echo "   重启服务: systemctl restart qdrant"
    echo "   停止服务: systemctl stop qdrant"
    echo "   查看配置: cat /etc/qdrant/config.yaml"
else
    echo "❌ Qdrant服务启动失败，请检查日志："
    journalctl -u qdrant -n 20 --no-pager
    echo ""
    echo "检查配置文件："
    cat /etc/qdrant/config.yaml
fi 