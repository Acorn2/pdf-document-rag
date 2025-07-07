#!/bin/bash
# Qdrant源码编译安装脚本

echo "🔧 从源码编译安装Qdrant..."

# 创建工作目录
WORK_DIR="/opt/qdrant"
mkdir -p $WORK_DIR
cd $WORK_DIR

# 克隆Qdrant源码
git clone https://github.com/qdrant/qdrant.git
cd qdrant

# 检查最新稳定版本
git checkout $(git describe --tags $(git rev-list --tags --max-count=1))

echo "开始编译Qdrant，这可能需要30-60分钟..."

# 编译Qdrant（Release版本，优化性能）
RUSTFLAGS="-C target-cpu=native" cargo build --release

# 创建Qdrant用户
useradd -r -s /bin/false qdrant

# 创建必要目录
mkdir -p /var/lib/qdrant/storage
mkdir -p /var/lib/qdrant/snapshots
mkdir -p /var/log/qdrant
mkdir -p /etc/qdrant

# 设置权限
chown -R qdrant:qdrant /var/lib/qdrant
chown -R qdrant:qdrant /var/log/qdrant

# 复制可执行文件
cp target/release/qdrant /usr/local/bin/
chown root:root /usr/local/bin/qdrant
chmod 755 /usr/local/bin/qdrant

# 验证安装
/usr/local/bin/qdrant --version

echo "✅ Qdrant源码编译安装完成！" 