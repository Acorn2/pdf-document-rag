#!/bin/bash
# Qdrant安装和启动问题诊断脚本

echo "🔍 Qdrant服务诊断工具"
echo "====================="

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 1. 检查Qdrant二进制文件
log_step "1. 检查Qdrant二进制文件安装"
echo "================================"
if [ -f "/usr/local/bin/qdrant" ]; then
    log_info "✅ Qdrant二进制文件存在: /usr/local/bin/qdrant"
    ls -la /usr/local/bin/qdrant
    
    # 检查文件权限
    if [ -x "/usr/local/bin/qdrant" ]; then
        log_info "✅ 文件可执行权限正确"
    else
        log_error "❌ 文件缺少可执行权限"
        echo "修复命令: chmod +x /usr/local/bin/qdrant"
    fi
    
    # 检查文件类型
    echo "文件类型信息:"
    file /usr/local/bin/qdrant
    
    # 尝试获取版本信息
    echo ""
    echo "尝试获取版本信息:"
    /usr/local/bin/qdrant --version 2>&1 || log_error "无法获取版本信息"
    
else
    log_error "❌ Qdrant二进制文件不存在: /usr/local/bin/qdrant"
    echo "请先运行安装脚本: ./04_install_qdrant_binary.sh"
fi

echo ""

# 2. 检查用户和权限
log_step "2. 检查用户和目录权限"
echo "=============================="
if id "qdrant" &>/dev/null; then
    log_info "✅ qdrant用户存在"
    echo "用户信息:"
    id qdrant
else
    log_error "❌ qdrant用户不存在"
    echo "创建用户命令: useradd -r -s /bin/false qdrant"
fi

# 检查关键目录
directories=(
    "/var/lib/qdrant"
    "/var/lib/qdrant/storage"
    "/var/lib/qdrant/snapshots"
    "/var/log/qdrant"
    "/etc/qdrant"
)

for dir in "${directories[@]}"; do
    if [ -d "$dir" ]; then
        log_info "✅ 目录存在: $dir"
        ls -la "$dir"
        echo "权限信息: $(stat -c '%U:%G %a' "$dir")"
    else
        log_error "❌ 目录不存在: $dir"
        echo "创建目录命令: mkdir -p $dir && chown qdrant:qdrant $dir"
    fi
    echo ""
done

echo ""

# 3. 检查配置文件
log_step "3. 检查配置文件"
echo "====================="
CONFIG_FILE="/etc/qdrant/config.yaml"
if [ -f "$CONFIG_FILE" ]; then
    log_info "✅ 配置文件存在: $CONFIG_FILE"
    echo "配置文件权限: $(stat -c '%U:%G %a' "$CONFIG_FILE")"
    echo "配置文件大小: $(stat -c%s "$CONFIG_FILE") 字节"
    
    # 检查配置文件语法
    echo ""
    echo "🔍 检查配置文件语法:"
    if /usr/local/bin/qdrant --config-path "$CONFIG_FILE" --dry-run 2>&1; then
        log_info "✅ 配置文件语法正确"
    else
        log_error "❌ 配置文件语法错误"
        echo ""
        echo "配置文件内容预览:"
        head -20 "$CONFIG_FILE"
    fi
else
    log_error "❌ 配置文件不存在: $CONFIG_FILE"
    echo "请确保配置文件已正确复制"
fi

echo ""

# 4. 检查systemd服务文件
log_step "4. 检查systemd服务文件"
echo "============================"
SERVICE_FILE="/etc/systemd/system/qdrant.service"
if [ -f "$SERVICE_FILE" ]; then
    log_info "✅ 服务文件存在: $SERVICE_FILE"
    echo "服务文件权限: $(stat -c '%U:%G %a' "$SERVICE_FILE")"
    echo ""
    echo "服务文件内容:"
    cat "$SERVICE_FILE"
else
    log_error "❌ 服务文件不存在: $SERVICE_FILE"
fi

echo ""

# 5. 检查服务状态详情
log_step "5. 检查服务状态详情"
echo "=========================="
echo "🔍 服务状态:"
systemctl status qdrant --no-pager -l

echo ""
echo "🔍 最近的服务日志 (最后50行):"
journalctl -u qdrant -n 50 --no-pager

echo ""
echo "🔍 服务启动失败详情:"
journalctl -u qdrant --since "5 minutes ago" --no-pager

echo ""

# 6. 检查端口占用
log_step "6. 检查端口占用情况"
echo "========================"
echo "检查6333端口 (HTTP API):"
ss -tlnp | grep 6333 || echo "端口6333未被占用"

echo ""
echo "检查6334端口 (gRPC API):"
ss -tlnp | grep 6334 || echo "端口6334未被占用"

echo ""
echo "检查是否有其他进程占用相关端口:"
lsof -i :6333 2>/dev/null || echo "无进程占用6333端口"
lsof -i :6334 2>/dev/null || echo "无进程占用6334端口"

echo ""

# 7. 检查系统资源
log_step "7. 检查系统资源"
echo "====================="
echo "💾 磁盘空间:"
df -h /var/lib/qdrant
df -h /var/log/qdrant

echo ""
echo "🧠 内存使用:"
free -h

echo ""
echo "⚡ CPU负载:"
uptime

echo ""

# 8. 手动启动测试
log_step "8. 手动启动测试"
echo "===================="
echo "🧪 尝试手动启动Qdrant (5秒测试):"
echo "命令: sudo -u qdrant /usr/local/bin/qdrant --config-path /etc/qdrant/config.yaml"
echo ""

# 在后台启动并限制时间
timeout 5s sudo -u qdrant /usr/local/bin/qdrant --config-path /etc/qdrant/config.yaml 2>&1 &
MANUAL_PID=$!

sleep 2

if kill -0 $MANUAL_PID 2>/dev/null; then
    log_info "✅ 手动启动成功，进程正在运行"
    kill $MANUAL_PID 2>/dev/null
else
    log_error "❌ 手动启动也失败"
fi

echo ""

# 9. 依赖检查
log_step "9. 检查系统依赖"
echo "===================="
echo "🔍 检查共享库依赖:"
ldd /usr/local/bin/qdrant 2>&1 | head -10

echo ""
echo "🔍 检查glibc版本:"
ldd --version | head -1

echo ""
echo "🔍 检查系统架构:"
uname -m

echo ""

# 10. 生成修复建议
log_step "10. 生成修复建议"
echo "====================="
echo "🔧 常见问题修复建议:"
echo ""

if [ ! -f "/usr/local/bin/qdrant" ]; then
    echo "1. 重新安装Qdrant二进制文件:"
    echo "   ./04_install_qdrant_binary.sh"
    echo ""
fi

if ! id "qdrant" &>/dev/null; then
    echo "2. 创建qdrant用户:"
    echo "   useradd -r -s /bin/false qdrant"
    echo ""
fi

echo "3. 重新设置目录权限:"
echo "   mkdir -p /var/lib/qdrant/{storage,snapshots}"
echo "   mkdir -p /var/log/qdrant"
echo "   chown -R qdrant:qdrant /var/lib/qdrant"
echo "   chown -R qdrant:qdrant /var/log/qdrant"
echo ""

echo "4. 重新部署配置文件:"
echo "   ./06_setup_qdrant_service.sh"
echo ""

echo "5. 检查配置文件语法:"
echo "   /usr/local/bin/qdrant --config-path /etc/qdrant/config.yaml --dry-run"
echo ""

echo "6. 重启服务:"
echo "   systemctl daemon-reload"
echo "   systemctl restart qdrant"
echo ""

echo "7. 查看实时日志:"
echo "   journalctl -u qdrant -f"
echo ""

echo "�� 诊断完成！请根据上述信息排查问题。" 