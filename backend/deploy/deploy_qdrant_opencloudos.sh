#!/bin/bash
# OpenCloudOS Qdrant一键部署脚本

set -e

echo "🚀 开始在OpenCloudOS上自动部署Qdrant..."

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    log_error "请使用root用户运行此脚本"
    exit 1
fi

# 检查系统版本
if ! grep -q "OpenCloudOS" /etc/os-release; then
    log_warn "此脚本专为OpenCloudOS设计，当前系统可能不兼容"
    read -p "是否继续？(y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

log_info "检测到系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"

# 获取脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 步骤1: 系统初始化
log_info "步骤 1/8: 系统初始化和更新..."
bash "$SCRIPT_DIR/01_init_opencloudos.sh"

# 步骤2: 安装Rust
log_info "步骤 2/8: 安装Rust环境..."
if ! command -v rustc &> /dev/null; then
    bash "$SCRIPT_DIR/02_install_rust.sh"
    source ~/.cargo/env
else
    log_info "Rust已安装: $(rustc --version)"
fi

# 步骤3: 安装Qdrant（选择二进制安装方式）
log_info "步骤 3/8: 安装Qdrant..."
bash "$SCRIPT_DIR/04_install_qdrant_binary.sh"

# 步骤4: 配置日志
log_info "步骤 4/8: 配置日志..."
bash "$SCRIPT_DIR/05_setup_qdrant_logging.sh"

# 步骤5: 配置systemd服务
log_info "步骤 5/8: 配置systemd服务..."
bash "$SCRIPT_DIR/06_setup_qdrant_service.sh"

# 步骤6: 配置防火墙
log_info "步骤 6/8: 配置防火墙..."
bash "$SCRIPT_DIR/07_configure_firewall.sh"

# 步骤7: 系统优化
# log_info "步骤 7/8: 系统性能优化..."
# bash "$SCRIPT_DIR/09_optimize_system.sh"

# 步骤8: 验证安装
log_info "步骤 8/8: 验证安装..."
sleep 15

if systemctl is-active --quiet qdrant; then
    log_info "✅ Qdrant服务运行正常"
else
    log_error "❌ Qdrant服务启动失败"
    systemctl status qdrant --no-pager
    exit 1
fi

# 健康检查
if curl -f http://localhost:6333/health > /dev/null 2>&1; then
    log_info "✅ Qdrant健康检查通过"
else
    log_error "❌ Qdrant健康检查失败"
    exit 1
fi

# 获取公网IP
PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || echo "无法获取公网IP")

# 创建便捷管理脚本
cat > /usr/local/bin/qdrant-status << 'EOF'
#!/bin/bash
echo "📊 Qdrant状态报告"
echo "=================="
echo "服务状态: $(systemctl is-active qdrant)"
echo "端口监听: $(ss -tlnp | grep -E ':(6333|6334)' | wc -l) 个端口"
echo "磁盘使用: $(df -h /var/lib/qdrant | tail -1 | awk '{print $5}')"
echo "内存使用: $(free -m | grep Mem | awk '{printf "%.1f%%\n", $3/$2 * 100.0}')"
echo ""
curl -s http://localhost:6333/health 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "健康检查失败"
EOF

chmod +x /usr/local/bin/qdrant-status

# 输出部署信息
echo ""
echo "🎉 Qdrant部署完成！"
echo "========================"
echo "📊 服务信息:"
echo "   REST API: http://$PUBLIC_IP:6333"
echo "   gRPC API: http://$PUBLIC_IP:6334"
echo "   Web UI: http://$PUBLIC_IP:6333/dashboard"
echo ""
echo "📁 重要路径:"
echo "   配置文件: /etc/qdrant/config.yaml"
echo "   数据目录: /var/lib/qdrant/storage"
echo "   日志目录: /var/log/qdrant/"
echo ""
echo "🔧 管理命令:"
echo "   查看状态: systemctl status qdrant"
echo "   查看日志: journalctl -u qdrant -f"
echo "   重启服务: systemctl restart qdrant"
echo "   停止服务: systemctl stop qdrant"
echo "   状态报告: qdrant-status"
echo ""
echo "📋 API测试:"
echo "   健康检查: curl http://localhost:6333/health"
echo "   集合列表: curl http://localhost:6333/collections"
echo "   完整测试: bash $SCRIPT_DIR/test_qdrant_api.sh"
echo ""

log_info "✅ 部署完成！"

echo ""
log_info "🔗 下一步操作建议:"
echo "1. 测试API连接: curl http://$PUBLIC_IP:6333/health"
echo "2. 访问Web UI: http://$PUBLIC_IP:6333/dashboard"
echo "3. 配置应用连接: 使用地址 $PUBLIC_IP:6333"
echo "4. 设置定期备份: 配置 $SCRIPT_DIR/backup_qdrant.sh"
echo "5. 监控服务状态: $SCRIPT_DIR/monitor_qdrant.sh" 