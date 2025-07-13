#!/bin/bash

# 设置生产环境脚本权限和创建便捷命令

echo "🔧 设置生产环境部署脚本..."

# 添加执行权限
chmod +x deploy_production.sh
chmod +x manage_service.sh  
chmod +x monitor_service.sh
chmod +x scripts/setup_env.sh

# 创建便捷的软链接或别名文件
cat > service_commands.sh << 'EOF'
#!/bin/bash
# 便捷的服务管理命令集

# 部署服务
alias deploy='./deploy_production.sh'

# 服务管理
alias svc-status='./manage_service.sh status'
alias svc-logs='./manage_service.sh logs'
alias svc-follow='./manage_service.sh follow'
alias svc-restart='./manage_service.sh restart'
alias svc-stop='./manage_service.sh stop'

# 监控管理
alias monitor-start='./monitor_service.sh daemon'
alias monitor-stop='./monitor_service.sh stop'
alias monitor-status='./monitor_service.sh status'

echo "📋 可用的服务管理命令："
echo "  deploy              部署服务"
echo "  svc-status          查看服务状态"
echo "  svc-logs            查看日志"
echo "  svc-follow          实时查看日志"
echo "  svc-restart         重启服务"
echo "  svc-stop            停止服务"
echo "  monitor-start       启动监控"
echo "  monitor-stop        停止监控"
echo "  monitor-status      查看监控状态"
EOF

chmod +x service_commands.sh

echo "✅ 生产环境脚本设置完成！"
echo ""
echo "🚀 部署流程："
echo "1. 首次部署：    ./deploy_production.sh"
echo "2. 启动监控：    ./monitor_service.sh daemon"
echo "3. 查看状态：    ./manage_service.sh status"
echo "4. 查看日志：    ./manage_service.sh logs"
echo ""
echo "💡 便捷命令："
echo "   source service_commands.sh  # 加载便捷别名" 