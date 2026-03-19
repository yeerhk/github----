#!/bin/bash

# ==========================================
# NVM + Node.js + PM2 极客版一键安装脚本
# 适用系统: Linux (Ubuntu/Debian/CentOS 等均可)
# ==========================================

print_info() { echo -e "\e[32m[INFO] $1\e[0m"; }

# 1. 安装基础依赖 curl
print_info "检查并安装 curl..."
if ! command -v curl &> /dev/null; then
    sudo apt-get update -y && sudo apt-get install -y curl
fi

# 2. 下载并安装 NVM (这里使用官方最新稳定版脚本)
print_info "正在安装 NVM (Node Version Manager)..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# 3. 核心技巧：在当前脚本会话中立刻激活 NVM 环境变量
print_info "正在加载 NVM 环境变量..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # 加载 nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # 加载 nvm 自动补全

# 4. 使用 NVM 安装 Node.js LTS (长期支持版，目前是 20.x)
print_info "正在通过 NVM 安装 Node.js 20 (LTS)..."
nvm install 20
nvm use 20
nvm alias default 20 # 设置 20 为默认版本

# 5. 使用 npm 安装 PM2
print_info "正在通过 npm 全局安装 PM2..."
npm install -g pm2

# 6. 验证安装
print_info "================ 安装完成 ================"
echo -n "NVM 版本:     " && nvm --version
echo -n "Node.js 版本: " && node -v
echo -n "npm 版本:     " && npm -v
echo -n "PM2 版本:     " && pm2 -v
print_info "=========================================="
print_info "注意: 请断开当前的 SSH 连接并重新登录，或者执行 'source ~/.bashrc'，"
print_info "以确保 nvm 和 pm2 命令在你的终端里完全生效！"
