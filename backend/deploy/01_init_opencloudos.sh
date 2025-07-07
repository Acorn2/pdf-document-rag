#!/bin/bash
# OpenCloudOS系统初始化脚本

echo "🚀 初始化OpenCloudOS系统..."

# 更新系统包
dnf update -y

# 安装基础工具
dnf install -y wget curl git vim htop unzip tar

# 安装开发工具
dnf groupinstall -y "Development Tools"

# 安装网络工具
dnf install -y net-tools telnet nc

# 设置时区
timedatectl set-timezone Asia/Shanghai

# 检查系统信息
echo "系统信息:"
cat /etc/os-release
echo "内核版本:"
uname -r
echo "内存信息:"
free -h
echo "磁盘信息:"
df -h

echo "✅ 系统初始化完成！" 