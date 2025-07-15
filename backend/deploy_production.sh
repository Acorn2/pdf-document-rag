#!/bin/bash

# 生产环境部署脚本 - 后台运行模式
# 使用systemd服务或screen会话保持服务运行
# 支持日志查看、服务管理等功能

set -e

echo "🚀 部署PDF文献分析智能体系统到生产环境..."

# 项目根目录
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="pdf-rag-backend"
VENV_DIR="$PROJECT_DIR/venv"
LOG_DIR="$PROJECT_DIR/logs"

# 检查是否为root用户（用于systemd服务）
IS_ROOT=false
if [ "$EUID" -eq 0 ]; then
    IS_ROOT=true
fi

# 选择部署模式
DEPLOY_MODE=${1:-auto}
if [ "$DEPLOY_MODE" = "auto" ]; then
    if [ "$IS_ROOT" = true ] || command -v systemctl &> /dev/null; then
        DEPLOY_MODE="systemd"
    else
        DEPLOY_MODE="screen"
    fi
fi

# 优雅关闭服务函数
graceful_shutdown() {
    local mode=$(detect_service_mode)
    echo "🛑 优雅关闭服务..."
    
    case $mode in
        "systemd")
            echo "发送SIGTERM信号给服务..."
            systemctl stop "$SERVICE_NAME"
            
            # 等待服务完全停止
            local max_wait=30
            local count=0
            while systemctl is-active --quiet "$SERVICE_NAME" && [ $count -lt $max_wait ]; do
                echo "等待服务停止... ($count/$max_wait)"
                sleep 1
                ((count++))
            done
            
            if systemctl is-active --quiet "$SERVICE_NAME"; then
                echo "⚠️ 服务未能在$max_wait秒内停止，将强制终止"
                systemctl kill -s 9 "$SERVICE_NAME"
            else
                echo "✅ 服务已优雅停止"
            fi
            ;;
        "screen")
            # 首先尝试发送SIGTERM信号
            if screen -list | grep -q "$SERVICE_NAME"; then
                echo "发送SIGTERM信号给screen会话..."
                screen -S "$SERVICE_NAME" -X stuff $'\003'  # 发送Ctrl+C
                
                # 等待会话结束
                local max_wait=30
                local count=0
                while screen -list | grep -q "$SERVICE_NAME" && [ $count -lt $max_wait ]; do
                    echo "等待会话结束... ($count/$max_wait)"
                    sleep 1
                    ((count++))
                done
                
                if screen -list | grep -q "$SERVICE_NAME"; then
                    echo "⚠️ 会话未能在$max_wait秒内结束，将强制终止"
                    screen -S "$SERVICE_NAME" -X quit
                else
                    echo "✅ 会话已优雅结束"
                fi
            else
                echo "⚠️ 服务未运行"
            fi
            ;;
        "none")
            echo "⚠️ 服务未运行"
            ;;
    esac
    
    # 检查是否有残留的uvicorn进程
    local uvicorn_pids=$(pgrep -f "uvicorn app.main:app")
    if [ -n "$uvicorn_pids" ]; then
        echo "发现残留的uvicorn进程，发送SIGTERM信号..."
        kill $uvicorn_pids
        sleep 3
        
        # 检查是否仍在运行
        uvicorn_pids=$(pgrep -f "uvicorn app.main:app")
        if [ -n "$uvicorn_pids" ]; then
            echo "⚠️ uvicorn进程未能正常终止，将强制终止"
            kill -9 $uvicorn_pids
        fi
    fi
}

# 检测服务运行模式
detect_service_mode() {
    if systemctl is-active "$SERVICE_NAME" &>/dev/null; then
        echo "systemd"
    elif screen -list | grep -q "$SERVICE_NAME"; then
        echo "screen"
    else
        echo "none"
    fi
}

# systemd 部署函数
deploy_with_systemd() {
    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
    
    echo "📝 创建systemd服务文件..."
    
    # 检查权限
    if [ "$IS_ROOT" != true ]; then
        echo "❌ 创建systemd服务需要root权限"
        echo "请使用以下命令之一："
        echo "  sudo $0 systemd"
        echo "  $0 screen  # 使用screen模式"
        exit 1
    fi
    
    # 检查服务是否已运行
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        echo "⚠️ 服务已在运行，执行优雅关闭..."
        graceful_shutdown
    fi
    
    # 获取实际的API端口值
    local api_port="${API_PORT:-8000}"
    local current_user=$(whoami)
    
    echo "📋 服务配置："
    echo "  端口: $api_port"
    echo "  用户: $current_user"
    echo "  工作目录: $PROJECT_DIR"
    
    # 创建服务文件
    cat > "$service_file" << EOF
[Unit]
Description=PDF文献分析智能体后端服务
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=exec
User=$current_user
WorkingDirectory=$PROJECT_DIR
Environment=PATH=$VENV_DIR/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
EnvironmentFile=$PROJECT_DIR/.env.production
ExecStart=$VENV_DIR/bin/uvicorn app.main:app --host 0.0.0.0 --port $api_port --workers 2
ExecReload=/bin/kill -HUP \$MAINPID
KillMode=mixed
Restart=always
RestartSec=5
StandardOutput=append:$LOG_DIR/service.log
StandardError=append:$LOG_DIR/service.error.log
# 添加优雅关闭配置
TimeoutStopSec=30

# 安全设置
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$PROJECT_DIR

[Install]
WantedBy=multi-user.target
EOF

    echo "✅ systemd服务文件创建完成: $service_file"
    
    # 重新加载systemd并启动服务
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME"
    systemctl start "$SERVICE_NAME"
    
    echo "✅ systemd服务已启动"
}

# screen 部署函数
deploy_with_screen() {
    # 检查screen是否安装
    if ! command -v screen &> /dev/null; then
        echo "📦 安装screen..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y screen
        elif command -v yum &> /dev/null; then
            sudo yum install -y screen
        else
            echo "❌ 无法自动安装screen，请手动安装"
            exit 1
        fi
    fi
    
    # 检查是否已有运行的服务
    if screen -list | grep -q "$SERVICE_NAME"; then
        echo "⚠️ 发现已运行的服务会话，执行优雅关闭..."
        graceful_shutdown
    fi
    
    # 创建启动脚本
    local start_script="$PROJECT_DIR/run_service.sh"
    cat > "$start_script" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"

# 加载环境变量
if [ -f ".env.production" ]; then
    export $(grep -v '^#' .env.production | xargs)
fi

# 激活虚拟环境
source venv/bin/activate

# 定义信号处理函数
graceful_shutdown() {
    echo "接收到停止信号，正在优雅关闭..."
    # 这里可以添加任何清理操作
    exit 0
}

# 注册信号处理
trap graceful_shutdown SIGINT SIGTERM

# 启动服务
exec uvicorn app.main:app --host 0.0.0.0 --port ${API_PORT:-8000} --workers 2 \
    --log-level info \
    --access-log \
    --log-config app/logging_config.py
EOF
    
    chmod +x "$start_script"
    
    # 在screen会话中启动服务
    echo "🚀 在screen会话中启动服务..."
    screen -dmS "$SERVICE_NAME" bash -c "
        cd '$PROJECT_DIR'
        exec bash '$start_script' 2>&1 | tee -a '$LOG_DIR/service.log'
    "
    
    echo "✅ screen会话已创建: $SERVICE_NAME"
}

# 检查服务状态函数
check_service_status() {
    local api_port="${API_PORT:-8000}"
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s "http://localhost:$api_port/api/v1/" > /dev/null 2>&1; then
            echo "✅ 服务启动成功，API响应正常"
            return 0
        fi
        
        echo "⏳ 等待服务启动... ($attempt/$max_attempts)"
        sleep 3
        ((attempt++))
    done
    
    echo "❌ 服务启动检查超时"
    return 1
}

# 显示服务信息函数
show_service_info() {
    local api_port="${API_PORT:-8000}"
    
    echo ""
    echo "📋 服务信息："
    echo "  🔗 后端API: http://$(hostname -I | awk '{print $1}'):$api_port"
    echo "  📚 API文档: http://$(hostname -I | awk '{print $1}'):$api_port/docs"
    echo "  🗄️  数据库: PostgreSQL (${DB_HOST:-localhost}:${DB_PORT:-5432})"
    echo "  📝 日志目录: $LOG_DIR"
    echo ""
    echo "🛠️  管理命令："
    echo "  查看服务状态: ./manage_service.sh status"
    echo "  查看实时日志: ./manage_service.sh logs"
    echo "  重启服务: ./manage_service.sh restart"
    echo "  停止服务: ./manage_service.sh stop"
    echo ""
}

# 主执行流程开始
echo "📋 部署配置："
echo "  项目目录: $PROJECT_DIR"
echo "  部署模式: $DEPLOY_MODE"
echo "  服务名称: $SERVICE_NAME"
echo "  用户权限: $(if [ "$IS_ROOT" = true ]; then echo "root"; else echo "$(whoami)"; fi)"

# 检查是否已有服务运行
current_mode=$(detect_service_mode)
if [ "$current_mode" != "none" ]; then
    echo "⚠️ 检测到服务已在运行（模式：$current_mode）"
    if [ "${FORCE_RESTART:-false}" != "true" ]; then
        read -p "是否优雅关闭并重新部署？(y/n): " confirm
        if [[ "$confirm" != [yY] ]]; then
            echo "❌ 部署已取消"
            exit 0
        fi
    fi
    echo "执行优雅关闭..."
    graceful_shutdown
fi

# 调用环境设置脚本
echo "🔧 设置生产环境..."
./scripts/setup_env.sh production

# 读取设置结果
if [ -f "/tmp/setup_env_result" ]; then
    source /tmp/setup_env_result
    rm -f /tmp/setup_env_result
fi

# 加载环境变量
if [ -f ".env.production" ]; then
    echo "📋 加载生产环境变量..."
    export $(grep -v '^#' .env.production | xargs)
    echo "✅ 环境变量加载完成"
fi

# 创建日志目录
mkdir -p "$LOG_DIR"

# 检查并安装依赖
echo "🐍 准备Python环境..."
if ! command -v python3 &> /dev/null; then
    echo "❌ 未找到Python3，请先安装Python3"
    exit 1
fi

# 创建虚拟环境
if [ ! -d "$VENV_DIR" ]; then
    echo "🐍 创建Python虚拟环境..."
    python3 -m venv "$VENV_DIR"
fi

# 安装依赖
echo "📦 安装依赖..."
source "$VENV_DIR/bin/activate"
pip install --upgrade pip
pip install -r requirements.txt

# 检查关键依赖
echo "🔍 检查关键依赖..."
python -c "
try:
    import fastapi, dashscope, langchain, sqlalchemy, psycopg2
    print('✅ 所有关键依赖检查通过')
except ImportError as e:
    print(f'❌ 依赖检查失败: {e}')
    exit(1)
"

# 测试数据库连接
echo "🗄️  测试数据库连接..."
python -c "
from app.database import get_db_session, get_db_info
try:
    print('数据库配置:', get_db_info())
    db = get_db_session()
    db.close()
    print('✅ 数据库连接测试成功')
except Exception as e:
    print(f'❌ 数据库连接失败: {e}')
    exit(1)
"

# 初始化数据库
echo "🗄️ 初始化数据库..."
python -c "
from app.database import create_tables, check_tables_exist
try:
    if check_tables_exist():
        print('ℹ️ 数据库表已存在，跳过初始化')
    else:
        create_tables()
        print('✅ 数据库表初始化完成')
except Exception as e:
    print(f'❌ 数据库初始化失败: {e}')
    exit(1)
"

# 根据部署模式启动服务
if [ "$DEPLOY_MODE" = "systemd" ]; then
    echo "📋 使用systemd服务模式部署..."
    deploy_with_systemd
elif [ "$DEPLOY_MODE" = "screen" ]; then
    echo "📋 使用screen会话模式部署..."
    deploy_with_screen
else
    echo "❌ 未知的部署模式: $DEPLOY_MODE"
    exit 1
fi

# 等待服务启动
echo "⏳ 等待服务启动..."
sleep 5

# 检查服务状态
check_service_status

echo "🎉 部署完成！"
show_service_info 