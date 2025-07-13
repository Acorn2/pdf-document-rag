#!/bin/bash

# 服务管理脚本 - 用于管理后端服务的启动、停止、重启和日志查看

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_NAME="pdf-rag-backend"
LOG_DIR="$PROJECT_DIR/logs"

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

# 显示服务状态
show_status() {
    local mode=$(detect_service_mode)
    echo "🔍 服务状态检查..."
    
    case $mode in
        "systemd")
            echo "📋 运行模式: systemd服务"
            systemctl status "$SERVICE_NAME" --no-pager -l
            ;;
        "screen")
            echo "📋 运行模式: screen会话"
            if screen -list | grep "$SERVICE_NAME"; then
                echo "✅ screen会话运行正常"
                # 检查API响应
                check_api_response
            else
                echo "❌ screen会话未找到"
            fi
            ;;
        "none")
            echo "❌ 服务未运行"
            echo "使用以下命令启动: ./deploy_production.sh"
            ;;
    esac
}

# 检查API响应
check_api_response() {
    # 从环境变量获取端口
    if [ -f ".env.production" ]; then
        export $(grep -v '^#' .env.production | xargs)
    fi
    
    local api_port="${API_PORT:-8000}"
    
    if curl -s "http://localhost:$api_port/api/v1/" > /dev/null 2>&1; then
        echo "✅ API服务响应正常 (端口: $api_port)"
    else
        echo "❌ API服务无响应 (端口: $api_port)"
    fi
}

# 查看日志
show_logs() {
    local lines="${2:-50}"
    local mode=$(detect_service_mode)
    
    echo "📝 显示服务日志 (最近 $lines 行)..."
    
    case $mode in
        "systemd")
            echo "--- systemd 服务日志 ---"
            journalctl -u "$SERVICE_NAME" -n "$lines" --no-pager
            ;;
        "screen"|"none")
            if [ -f "$LOG_DIR/service.log" ]; then
                echo "--- 应用日志 ---"
                tail -n "$lines" "$LOG_DIR/service.log"
            else
                echo "❌ 日志文件不存在: $LOG_DIR/service.log"
            fi
            ;;
    esac
    
    # 显示错误日志
    if [ -f "$LOG_DIR/service.error.log" ]; then
        echo ""
        echo "--- 错误日志 ---"
        tail -n "$lines" "$LOG_DIR/service.error.log"
    fi
    
    # 显示应用日志
    if [ -f "$LOG_DIR/app.log" ]; then
        echo ""
        echo "--- 应用详细日志 ---"
        tail -n "$lines" "$LOG_DIR/app.log"
    fi
}

# 实时查看日志
follow_logs() {
    local mode=$(detect_service_mode)
    
    echo "📝 实时查看日志 (按 Ctrl+C 退出)..."
    
    case $mode in
        "systemd")
            journalctl -u "$SERVICE_NAME" -f
            ;;
        "screen"|"none")
            if [ -f "$LOG_DIR/service.log" ]; then
                tail -f "$LOG_DIR/service.log"
            else
                echo "❌ 日志文件不存在: $LOG_DIR/service.log"
            fi
            ;;
    esac
}

# 停止服务
stop_service() {
    local mode=$(detect_service_mode)
    echo "🛑 停止服务..."
    
    case $mode in
        "systemd")
            systemctl stop "$SERVICE_NAME"
            echo "✅ systemd服务已停止"
            ;;
        "screen")
            screen -S "$SERVICE_NAME" -X quit
            echo "✅ screen会话已停止"
            ;;
        "none")
            echo "⚠️  服务未运行"
            ;;
    esac
}

# 重启服务
restart_service() {
    echo "🔄 重启服务..."
    stop_service
    sleep 3
    
    echo "🚀 重新启动服务..."
    ./deploy_production.sh
}

# 进入screen会话
attach_screen() {
    if screen -list | grep -q "$SERVICE_NAME"; then
        echo "📺 连接到screen会话 (按 Ctrl+A+D 退出)..."
        screen -r "$SERVICE_NAME"
    else
        echo "❌ 未找到screen会话: $SERVICE_NAME"
    fi
}

# 显示帮助信息
show_help() {
    echo "📋 PDF文献分析智能体 - 服务管理工具"
    echo ""
    echo "用法: $0 <命令> [选项]"
    echo ""
    echo "命令："
    echo "  status              显示服务状态"
    echo "  logs [行数]         显示服务日志 (默认50行)"
    echo "  follow              实时查看日志"
    echo "  stop                停止服务"
    echo "  restart             重启服务"
    echo "  attach              连接到screen会话 (仅screen模式)"
    echo "  help                显示此帮助信息"
    echo ""
    echo "示例："
    echo "  $0 status           # 查看服务状态"
    echo "  $0 logs 100         # 查看最近100行日志"
    echo "  $0 follow           # 实时查看日志"
    echo "  $0 restart          # 重启服务"
    echo ""
}

# 主函数
main() {
    case "${1:-help}" in
        "status")
            show_status
            ;;
        "logs")
            show_logs "$@"
            ;;
        "follow")
            follow_logs
            ;;
        "stop")
            stop_service
            ;;
        "restart")
            restart_service
            ;;
        "attach")
            attach_screen
            ;;
        "help"|"--help"|"-h")
            show_help
            ;;
        *)
            echo "❌ 未知命令: $1"
            echo "使用 '$0 help' 查看帮助"
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
