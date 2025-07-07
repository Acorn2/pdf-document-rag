#!/bin/bash
# Rust环境安装脚本

echo "🦀 安装Rust环境..."

# 下载并安装Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# 重新加载环境变量
source ~/.cargo/env

# 添加到系统PATH
echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 验证安装
rustc --version
cargo --version

# 安装必要的编译工具
rustup component add rustfmt
rustup component add clippy

echo "✅ Rust环境安装完成！"
echo "Rust版本: $(rustc --version)"
echo "Cargo版本: $(cargo --version)" 