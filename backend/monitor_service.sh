#!/bin/bash

# 服务监控脚本 - 自动监控服务状态并在异常时重启

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="pdf-rag-backend"
LOG_DIR="$PROJECT_DIR/logs"
MONITOR_LOG="$LOG_DIR/monitor.log"

# 加载环境变量
if [ -f ".env.production" ]; then
    export $(grep -v '^#' .env.production | xargs)
fi

API_PORT="${API_PORT:-8000}"
CHECK_INTERVAL="${MONITOR_INTERVAL:-60}"  # 检查间隔（秒）
MAX_RESTART_ATTEMPTS=3
RESTART_COOLDOWN=300  # 重启冷却时间（秒）

# 确保日志目录存在
mkdir -p "$LOG_DIR"

# 记录日志函数
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$MONITOR_LOG"
}

# 检查服务是否运行
check_service_health() {
    # 检查API响应
    if curl -s --max-time 10 "http://localhost:$API_PORT/api/v1/" > /dev/null 2>&1; then
        return 0  # 服务正常
    else
        return 1  # 服务异常
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

# 重启服务
restart_service() {
    local mode=$(detect_service_mode)
    log_message "WARN" "尝试重启服务 (模式: $mode)"
    
    case $mode in
        "systemd")
            systemctl restart "$SERVICE_NAME"
            sleep 10
            if systemctl is-active "$SERVICE_NAME" &>/dev/null; then
                log_message "INFO" "systemd服务重启成功"
                return 0
            else
                log_message "ERROR" "systemd服务重启失败"
                return 1
            fi
            ;;
        "screen")
            # 停止现有会话
            screen -S "$SERVICE_NAME" -X quit 2>/dev/null || true
            sleep 5
            
            # 重新启动
            cd "$PROJECT_DIR"
            screen -dmS "$SERVICE_NAME" bash -c "
                source venv/bin/activate
                if [ -f '.env.production' ]; then
                    export \$(grep -v '^#' .env.production | xargs)
                fi
                exec uvicorn app.main:app --host 0.0.0.0 --port $API_PORT --workers 2 2>&1 | tee -a '$LOG_DIR/service.log'
            "
            
            sleep 10
            if screen -list | grep -q "$SERVICE_NAME"; then
                log_message "INFO" "screen服务重启成功"
                return 0
            else
                log_message "ERROR" "screen服务重启失败"
                return 1
            fi
            ;;
        "none")
            log_message "ERROR" "服务未运行，尝试启动"
            cd "$PROJECT_DIR"
            ./deploy_production.sh > "$LOG_DIR/restart.log" 2>&1
            return $?
            ;;
    esac
}

# 发送告警通知（可扩展）
send_alert() {
    local message="$1"
    log_message "ALERT" "$message"
    
    # 这里可以扩展为发送邮件、微信、钉钉等通知
    # 示例：发送到系统日志
    logger -t "$SERVICE_NAME-monitor" "$message"
}

# 主监控循环
monitor_loop() {
    log_message "INFO" "服务监控启动 (检查间隔: ${CHECK_INTERVAL}秒)"
    
    local consecutive_failures=0
    local last_restart_time=0
    
    while true; do
        if check_service_health; then
            if [ $consecutive_failures -gt 0 ]; then
                log_message "INFO" "服务恢复正常"
                consecutive_failures=0
            fi
        else
            consecutive_failures=$((consecutive_failures + 1))
            log_message "WARN" "服务健康检查失败 (连续失败: $consecutive_failures 次)"
            
            # 连续失败3次则尝试重启
            if [ $consecutive_failures -ge 3 ]; then
                local current_time=$(date +%s)
                local time_since_last_restart=$((current_time - last_restart_time))
                
                # 检查是否在冷却期内
                if [ $time_since_last_restart -lt $RESTART_COOLDOWN ]; then
                    log_message "WARN" "在重启冷却期内，跳过重启 (剩余: $((RESTART_COOLDOWN - time_since_last_restart))秒)"
                else
                    send_alert "服务异常，正在尝试重启"
                    
                    if restart_service; then
                        log_message "INFO" "服务重启成功"
                        consecutive_failures=0
                        last_restart_time=$current_time
                    else
                        log_message "ERROR" "服务重启失败"
                        send_alert "服务重启失败，需要人工干预"
                    fi
                fi
            fi
        fi
        
        sleep "$CHECK_INTERVAL"
    done
}

# 检查是否以daemon模式运行
if [ "$1" = "daemon" ]; then
    # 检查是否已有监控进程运行
    if pgrep -f "monitor_service.sh daemon" > /dev/null; then
        echo "⚠️  监控进程已在运行"
        exit 1
    fi
    
    # 后台运行监控循环
    monitor_loop &
    echo $! > "$LOG_DIR/monitor.pid"
    log_message "INFO" "监控进程已启动 (PID: $!)"
    echo "✅ 服务监控已启动"
    echo "📝 监控日志: $MONITOR_LOG"
    echo "🛑 停止监控: $0 stop"
elif [ "$1" = "stop" ]; then
    if [ -f "$LOG_DIR/monitor.pid" ]; then
        local pid=$(cat "$LOG_DIR/monitor.pid")
        if kill "$pid" 2>/dev/null; then
            log_message "INFO" "监控进程已停止 (PID: $pid)"
            rm -f "$LOG_DIR/monitor.pid"
            echo "✅ 监控进程已停止"
        else
            echo "❌ 无法停止监控进程"
        fi
    else
        echo "⚠️  未找到监控进程"
    fi
elif [ "$1" = "status" ]; then
    if [ -f "$LOG_DIR/monitor.pid" ]; then
        local pid=$(cat "$LOG_DIR/monitor.pid")
        if kill -0 "$pid" 2>/dev/null; then
            echo "✅ 监控进程运行正常 (PID: $pid)"
            echo "📝 最近监控日志:"
            tail -n 10 "$MONITOR_LOG" 2>/dev/null || echo "暂无日志"
        else
            echo "❌ 监控进程已停止"
            rm -f "$LOG_DIR/monitor.pid"
        fi
    else
        echo "❌ 监控进程未运行"
    fi
else
    echo "📋 服务监控工具"
    echo ""
    echo "用法: $0 <命令>"
    echo ""
    echo "命令："
    echo "  daemon              启动后台监控"
    echo "  stop                停止监控"
    echo "  status              查看监控状态"
    echo ""
    echo "示例："
    echo "  $0 daemon           # 启动服务监控"
    echo "  $0 status           # 查看监控状态"
    echo "  $0 stop             # 停止监控"
fi 