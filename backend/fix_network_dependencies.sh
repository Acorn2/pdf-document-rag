#!/bin/bash

# 网络连接修复和依赖安装脚本

echo "🔧 修复网络连接并安装Python依赖..."

# 1. 检查网络连接
echo "🌐 检查网络连接..."
if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ 网络连接正常"
else
    echo "❌ 网络连接异常，请检查网络设置"
    exit 1
fi

# 2. 检查DNS解析
echo "🔍 检查DNS解析..."
nslookup pypi.org > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ DNS解析正常"
else
    echo "⚠️ DNS解析可能有问题"
fi

# 3. 测试各种镜像源的连通性
echo "🌐 测试镜像源连通性..."

declare -A mirrors=(
    ["官方源"]="https://pypi.org/simple"
    ["阿里云"]="https://mirrors.aliyun.com/pypi/simple/"
    ["清华大学"]="https://pypi.tuna.tsinghua.edu.cn/simple"
    ["中科大"]="https://pypi.mirrors.ustc.edu.cn/simple/"
    ["豆瓣"]="https://pypi.douban.com/simple/"
    ["华为云"]="https://mirrors.huaweicloud.com/repository/pypi/simple"
)

working_mirror=""
for name in "${!mirrors[@]}"; do
    mirror_url="${mirrors[$name]}"
    echo "测试 $name: $mirror_url"
    
    if timeout 10 curl -s --head "$mirror_url" > /dev/null 2>&1; then
        echo "✅ $name 可用"
        if [ -z "$working_mirror" ]; then
            working_mirror="$mirror_url"
            working_name="$name"
        fi
    else
        echo "❌ $name 不可用"
    fi
done

if [ -z "$working_mirror" ]; then
    echo "❌ 所有镜像源都不可用，请检查网络设置"
    exit 1
fi

echo "🎯 使用镜像源: $working_name ($working_mirror)"

# 4. 配置pip使用可用的镜像源
echo "🔧 配置pip镜像源..."
pip config set global.index-url "$working_mirror"

# 如果是https源，还需要配置trusted-host
if [[ "$working_mirror" == https://* ]]; then
    # 提取域名
    domain=$(echo "$working_mirror" | sed 's|https://||' | sed 's|/.*||')
    pip config set global.trusted-host "$domain"
    echo "✅ 配置trusted-host: $domain"
fi

# 5. 清理pip缓存
echo "🧹 清理pip缓存..."
pip cache purge

# 6. 升级pip
echo "📦 升级pip..."
python -m pip install --upgrade pip --timeout 60

# 7. 创建精简的requirements文件（移除可能有问题的版本约束）
echo "📝 创建精简requirements文件..."
cat > requirements_minimal.txt << 'EOF'
# 核心框架
fastapi
uvicorn[standard]
python-multipart

# 数据库
sqlalchemy
psycopg2-binary

# LangChain
langchain
langchain-community

# AI模型
dashscope

# 文档处理
PyMuPDF
pypdf
jieba

# 基础工具
pydantic
python-dotenv
numpy
requests

# 腾讯云
cos-python-sdk-v5

# 向量数据库
qdrant-client
EOF

# 8. 分批安装关键依赖
echo "📦 开始安装依赖..."

install_with_retry() {
    local package="$1"
    local max_retries=3
    local retry=1
    
    while [ $retry -le $max_retries ]; do
        echo "正在安装 $package (尝试 $retry/$max_retries)..."
        
        if pip install --no-cache-dir --timeout 120 "$package"; then
            echo "✅ $package 安装成功"
            return 0
        else
            echo "❌ $package 安装失败，等待重试..."
            sleep 5
            ((retry++))
        fi
    done
    
    echo "❌ $package 安装失败，已达到最大重试次数"
    return 1
}

# 按优先级安装
packages=(
    "fastapi"
    "uvicorn[standard]"
    "python-multipart"
    "sqlalchemy"
    "psycopg2-binary"
    "pydantic"
    "python-dotenv"
    "requests"
    "numpy"
    "dashscope"
    "langchain"
    "langchain-community" 
    "PyMuPDF"
    "pypdf"
    "jieba"
    "cos-python-sdk-v5"
    "qdrant-client"
)

failed_packages=()

for package in "${packages[@]}"; do
    if ! install_with_retry "$package"; then
        failed_packages+=("$package")
    fi
done

# 9. 验证安装结果
echo "🔍 验证关键依赖..."
python -c "
import sys
success = True
packages = [
    ('fastapi', 'FastAPI'),
    ('uvicorn', 'Uvicorn'),
    ('sqlalchemy', 'SQLAlchemy'),
    ('psycopg2', 'psycopg2'),
    ('pydantic', 'Pydantic'),
    ('requests', 'Requests'),
    ('numpy', 'NumPy')
]

for module, name in packages:
    try:
        __import__(module)
        print(f'✅ {name} 导入成功')
    except ImportError as e:
        print(f'❌ {name} 导入失败: {e}')
        success = False

if success:
    print('🎉 核心依赖验证通过！')
else:
    print('❌ 部分依赖验证失败')
    sys.exit(1)
"

if [ ${#failed_packages[@]} -eq 0 ]; then
    echo "🎉 所有依赖安装成功！"
else
    echo "⚠️ 以下包安装失败："
    for pkg in "${failed_packages[@]}"; do
        echo "  - $pkg"
    done
    echo "您可以稍后手动安装这些包"
fi

echo "✅ 依赖安装脚本执行完成" 