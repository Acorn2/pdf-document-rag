#!/bin/bash
# Qdrant预编译二进制安装脚本

echo "📦 使用预编译二进制文件安装Qdrant..."

# 获取最新版本号
QDRANT_VERSION=$(curl -s https://api.github.com/repos/qdrant/qdrant/releases/latest | grep '"tag_name"' | cut -d '"' -f 4)
echo "最新Qdrant版本: $QDRANT_VERSION"

# 下载预编译二进制文件
cd /tmp
wget "https://github.com/qdrant/qdrant/releases/download/$QDRANT_VERSION/qdrant-x86_64-unknown-linux-gnu.tar.gz"

# 验证下载文件
if [ ! -f "qdrant-x86_64-unknown-linux-gnu.tar.gz" ]; then
    echo "❌ 下载失败，请检查网络连接"
    exit 1
fi

# 解压并安装
tar -xzf qdrant-x86_64-unknown-linux-gnu.tar.gz
mv qdrant /usr/local/bin/
chmod +x /usr/local/bin/qdrant

# 创建Qdrant用户和目录
useradd -r -s /bin/false qdrant || true
mkdir -p /var/lib/qdrant/storage
mkdir -p /var/lib/qdrant/snapshots
mkdir -p /var/log/qdrant
mkdir -p /etc/qdrant

# 设置权限
chown -R qdrant:qdrant /var/lib/qdrant
chown -R qdrant:qdrant /var/log/qdrant

# 验证安装
/usr/local/bin/qdrant --version

# 清理临时文件
rm -f /tmp/qdrant-x86_64-unknown-linux-gnu.tar.gz

echo "✅ Qdrant二进制安装完成！"
echo "版本信息: $(/usr/local/bin/qdrant --version)" 