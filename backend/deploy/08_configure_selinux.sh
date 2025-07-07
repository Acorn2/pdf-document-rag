#!/bin/bash
# SELinux配置脚本

echo "🛡️ 配置SELinux..."

# 检查SELinux状态
getenforce

# 如果SELinux是启用的，需要设置相应的策略
if [ "$(getenforce)" = "Enforcing" ]; then
    echo "SELinux正在运行，配置Qdrant相关策略..."
    
    # 安装SELinux管理工具
    dnf install -y policycoreutils-python-utils
    
    # 设置Qdrant端口的SELinux策略
    semanage port -a -t http_port_t -p tcp 6333 2>/dev/null || semanage port -m -t http_port_t -p tcp 6333
    semanage port -a -t http_port_t -p tcp 6334 2>/dev/null || semanage port -m -t http_port_t -p tcp 6334
    
    # 设置Qdrant文件权限
    semanage fcontext -a -t admin_home_t "/var/lib/qdrant(/.*)?"
    semanage fcontext -a -t var_log_t "/var/log/qdrant(/.*)?"
    
    # 应用SELinux上下文
    restorecon -R /var/lib/qdrant
    restorecon -R /var/log/qdrant
    
    echo "✅ SELinux配置完成"
else
    echo "SELinux未启用或处于宽松模式，无需额外配置"
fi 