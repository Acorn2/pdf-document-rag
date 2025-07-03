#!/bin/bash

echo "🚀 启动PDF文献分析智能体系统（PostgreSQL环境）..."

# 调用环境设置脚本
./scripts/setup_env.sh production

# 读取设置结果
if [ -f "/tmp/setup_env_result" ]; then
    source /tmp/setup_env_result
    rm -f /tmp/setup_env_result
fi

# 检查Python
if ! command -v python3 &> /dev/null; then
    echo "❌ 未找到Python3，请先安装Python3"
    exit 1
fi

# 创建和激活虚拟环境
if [ ! -d "venv" ]; then
    echo "🐍 创建Python虚拟环境..."
    python3 -m venv venv
fi

echo "📦 激活虚拟环境..."
source venv/bin/activate

if [ -z "$VIRTUAL_ENV" ]; then
    echo "❌ 虚拟环境激活失败"
    exit 1
fi

# 安装依赖
echo "📦 安装依赖..."
pip install -r requirements.txt

# 检查关键依赖
echo "🔍 检查关键依赖..."
python -c "
try:
    import fastapi, dashscope, langchain, chromadb, sqlalchemy, psycopg2
    print('✅ 所有关键依赖检查通过')
except ImportError as e:
    print(f'❌ 依赖检查失败: {e}')
    exit(1)
" || exit 1

# 创建PostgreSQL数据库（如果不存在）
echo "🗄️  检查/创建PostgreSQL数据库..."
python -c "
import os
import psycopg2
from psycopg2 import sql
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

# 从环境变量获取数据库配置
db_host = os.getenv('DB_HOST', 'localhost')
db_port = os.getenv('DB_PORT', '5432')
db_user = os.getenv('DB_USER', 'postgres')
db_password = os.getenv('DB_PASSWORD', 'postgres')
db_name = os.getenv('DB_NAME', 'document_analysis')

try:
    # 连接到默认postgres数据库
    conn = psycopg2.connect(
        host=db_host,
        port=int(db_port),
        user=db_user,
        password=db_password,
        database='postgres'
    )
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    cursor = conn.cursor()
    
    # 检查数据库是否存在
    cursor.execute('SELECT 1 FROM pg_database WHERE datname = %s', (db_name,))
    exists = cursor.fetchone()
    
    if not exists:
        print(f'📝 创建数据库 {db_name}...')
        cursor.execute(sql.SQL('CREATE DATABASE {}').format(sql.Identifier(db_name)))
        print('✅ 数据库创建成功')
    else:
        print(f'✅ 数据库 {db_name} 已存在')
    
    cursor.close()
    conn.close()
    
except Exception as e:
    print(f'❌ 数据库操作失败: {e}')
    exit(1)
" || exit 1

# 初始化数据库表
echo "🗄️  初始化PostgreSQL数据库表..."
python -c "
from app.database import create_tables, get_db_info, get_db_session
import logging
logging.basicConfig(level=logging.INFO)

try:
    print('数据库配置信息:', get_db_info())
    
    # 测试连接
    db = get_db_session()
    db.close()
    print('✅ 数据库连接测试成功')
    
    # 创建表
    create_tables()
    print('✅ PostgreSQL数据库表初始化完成')
    
except Exception as e:
    print(f'❌ 数据库初始化失败: {e}')
    exit(1)
" || exit 1

# 启动服务
echo "🚀 启动API服务..."
uvicorn app.main:app --reload --host 0.0.0.0 --port ${API_PORT:-8000} &
API_PID=$!

# 等待服务启动
echo "⏳ 等待API服务启动..."
sleep 3

# 检查服务状态
if kill -0 $API_PID 2>/dev/null; then
    echo "✅ PostgreSQL环境启动完成！"
    echo ""
    echo "🗄️  数据库: PostgreSQL (${DB_HOST:-localhost}:${DB_PORT:-5432}/${DB_NAME:-document_analysis})"
    echo "🔗 后端API: http://localhost:${API_PORT:-8000}"
    echo "📚 API文档: http://localhost:${API_PORT:-8000}/docs"
    echo "🔧 数据库信息: http://localhost:${API_PORT:-8000}/api/v1/database/info"
    echo ""
    echo "按 Ctrl+C 停止服务"
else
    echo "❌ API服务启动失败"
    exit 1
fi

trap "echo '🛑 正在停止服务...'; kill $API_PID 2>/dev/null; exit" INT
wait 