#!/bin/bash

echo "🚀 使用Docker部署PDF文献分析智能体后端服务..."

# 检查Docker是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ Docker未安装，请先安装Docker"
    exit 1
fi

# 检查环境变量文件
if [ ! -f ".env.production" ]; then
    echo "⚠️ 未找到.env.production文件，请先创建此文件并设置必要的环境变量"
    exit 1
fi

# 容器名称
CONTAINER_NAME="pdf-rag-backend"
IMAGE_NAME="pdf-rag-backend:latest"
API_PORT=$(grep API_PORT .env.production | cut -d '=' -f2 || echo 8000)

# 创建必要的目录
mkdir -p uploads logs vector_db

# 停止并移除旧容器（如果存在）
echo "🛑 停止并移除旧容器（如果存在）..."
if docker ps -a | grep -q $CONTAINER_NAME; then
    docker stop $CONTAINER_NAME
    docker rm $CONTAINER_NAME
fi

# 构建Docker镜像
echo "🔨 构建Docker镜像..."
docker build -t $IMAGE_NAME .

# 运行Docker容器
echo "🚀 启动Docker容器..."
docker run -d \
    --name $CONTAINER_NAME \
    --restart always \
    -p ${API_PORT}:8000 \
    -v $(pwd)/uploads:/app/uploads \
    -v $(pwd)/logs:/app/logs \
    -v $(pwd)/vector_db:/app/vector_db \
    -v $(pwd)/.env.production:/app/.env.production \
    --env-file .env.production \
    $IMAGE_NAME

# 检查容器是否成功启动
if docker ps | grep -q $CONTAINER_NAME; then
    echo "✅ 服务已成功启动！"
    
    echo ""
    echo "📋 服务信息："
    echo "  🔗 后端API: http://$(hostname -I | awk '{print $1}'):${API_PORT}"
    echo "  📚 API文档: http://$(hostname -I | awk '{print $1}'):${API_PORT}/docs"
    echo ""
    echo "🛠️ 管理命令："
    echo "  查看日志: docker logs -f $CONTAINER_NAME"
    echo "  重启服务: docker restart $CONTAINER_NAME"
    echo "  停止服务: docker stop $CONTAINER_NAME"
    echo "  查看状态: docker ps | grep $CONTAINER_NAME"
else
    echo "❌ 服务启动失败，请检查日志"
    docker logs $CONTAINER_NAME
    exit 1
fi