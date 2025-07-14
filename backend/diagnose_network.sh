#!/bin/bash

# 网络连接诊断脚本

echo "🔍 网络连接诊断..."

# 1. 基本网络连接测试
echo "1️⃣ 基本网络连接测试"
echo "测试公网连接..."
if ping -c 3 8.8.8.8 > /dev/null 2>&1; then
    echo "✅ 公网连接正常"
else
    echo "❌ 公网连接异常"
fi

if ping -c 3 114.114.114.114 > /dev/null 2>&1; then
    echo "✅ 国内DNS服务器连接正常"
else
    echo "❌ 国内DNS服务器连接异常"
fi

# 2. DNS解析测试
echo -e "\n2️⃣ DNS解析测试"
domains=("pypi.org" "mirrors.aliyun.com" "pypi.tuna.tsinghua.edu.cn" "pypi.douban.com")

for domain in "${domains[@]}"; do
    if nslookup "$domain" > /dev/null 2>&1; then
        echo "✅ $domain 解析正常"
    else
        echo "❌ $domain 解析失败"
    fi
done

# 3. HTTP连接测试
echo -e "\n3️⃣ HTTP连接测试"
urls=(
    "https://pypi.org/simple"
    "https://mirrors.aliyun.com/pypi/simple/"
    "https://pypi.tuna.tsinghua.edu.cn/simple"
    "https://pypi.douban.com/simple/"
    "https://mirrors.huaweicloud.com/repository/pypi/simple"
)

for url in "${urls[@]}"; do
    if timeout 10 curl -s --head "$url" > /dev/null 2>&1; then
        echo "✅ $url 连接成功"
    else
        echo "❌ $url 连接失败"
    fi
done

# 4. 当前pip配置
echo -e "\n4️⃣ 当前pip配置"
echo "pip配置文件位置："
pip config list --verbose

# 5. 系统信息
echo -e "\n5️⃣ 系统信息"
echo "操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
echo "Python版本: $(python3 --version)"
echo "pip版本: $(pip --version)"

# 6. 建议的解决方案
echo -e "\n💡 建议的解决方案："
echo "1. 如果DNS解析失败，请检查 /etc/resolv.conf"
echo "2. 如果网络连接异常，请检查防火墙设置"
echo "3. 尝试使用不同的镜像源"
echo "4. 如果在内网环境，请配置HTTP代理" 